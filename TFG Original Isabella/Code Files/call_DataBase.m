function Component = call_DataBase(varargin)
% This function communicates with Aspen Hysys to obtain information about the reactive system
% Aspen Hysys files required:
%   Sample .xml file whose location is specified in lines 17, 18
% =========================================================================
% Isabela Fons Moreno-Palancas
% Last update: March 17, 2020
% =========================================================================

    %% STEP 1: Find the Aspen Hysys File
    if isempty(varargin{1})
    %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        workingDirectory = pwd ; 
        fileName = 'ComponentDataBase' ;
        streamName = 'Stream_Sample' ;
    %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    else 
        location = varargin{1} ;
        workingDirectory = location{1} ;
        fileName = location{2} ;
        streamName = location{3} ;
    end

    HySimulationCaseName = [fileName '.xml'];
    HyFilename           = fullfile(workingDirectory,HySimulationCaseName);
    % Test existence of Hysys file
    if exist(HyFilename, 'file') ~= 2
       error('File not found: %s.', HyFilename);
    end

    %% STEP 2: Stablish connection with Hysys
    fprintf('Connecting with Hysys. Please wait...\n')
    feature('COM_SafeArraySingleDim', 1); % This command allows to exchange data as vectors
    HyApp = actxserver('HYSYS.Application');
    HyCase = HyApp.SimulationCases.Open(HyFilename); % open Hysys file
    HyCase.Visible = 1;
    HyCase.Solver.CanSolve = 1 ;
    fprintf('Hysys file "%s" loaded. \n',HySimulationCaseName);

    HyFlowsheet         = HyCase.Flowsheet ;
    HyMaterialStreams   = HyFlowsheet.MaterialStreams ;
    HyOperations      = HyFlowsheet.Operations;
    HyEnergyStreams   = HyFlowsheet.EnergyStreams;
    HyComponents      = HyFlowsheet.FluidPackage.Components;

    %% STEP 3: Read component properties from Hysys
    % Index for component list starts at 0 in Hysys
    nComponents = HyComponents.Count;
    Component = struct('Formula',[],'Name',[],'MolecularWeightValue',[],'HeatOfFormation',[]) ;
    for i = 0:nComponents-1
        Component(i+1).Formula               = HyComponents.Item(i).Formula;
        Component(i+1).Name                  = HyComponents.Item(i).Name;
        Component(i+1).MolecularWeightValue  = HyComponents.Item(i).MolecularWeightValue;
        Component(i+1).HeatOfFormation       = HyComponents.Item(i).HeatOfFormation.GetValue('kJ/kgmole') ; % kJ/kgmole = kJ/kmol = J/mol
    end

    %% STEP 4: Determine heat capacity for each component
    global heatCapacityUnits temperatureUnits pressureUnits Name %Defined as global for local funtions
    %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    temperatureLo = 500 +273.15 ; %K
    temperatureUp = 1000 + 273.15 ; %K
    temperatureUnits = 'K' ;
    pressureUnits = 'Pa' ;
    heatCapacityUnits = 'kJ/kgmole-C'; % kJ/(kgmole·C) = kJ/(kmol·C) = J/(mol·C)
    nPoints = 30;
    
    % #### If pressure dependancy is neglected, comment the following lines ####
    %     fprintf('Evaluating pressure depencency takes time. Please wait...\n')
    %     pressureLo    = 1 * 1e5 ;
    %     pressureUp    = 5 * 1e5 ;  
    %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    HyStream = get(HyMaterialStreams,'Item',streamName);
    temperatureArray = linspace(temperatureLo,temperatureUp,nPoints);
    if exist('pressureLo','var') && exist('pressureUp','var')
        pressureArray  = linspace(pressureLo,pressureUp,nPoints) ;
    else
        pressureArray = HyStream.Pressure.GetValue(pressureUnits) ;
    end
    molarFlowUnits = 'kgmole/h' ;

    ComponentMolarFlow = zeros(nComponents,1) ;
    for iLevel1 = 1:nComponents
        HySolver.CanSolve = 0 ;
        ComponentMolarFlow(iLevel1) = 1 ;
        HyStream.ComponentMolarFlow.SetValues(ComponentMolarFlow,molarFlowUnits) ;
        HySolver.CanSolve = 1 ;

        %Compute molar heat capacity for each pressure and each temperature
        MolarHeatCapacityArray = zeros(length(temperatureArray),length(pressureArray)) ; % Rows : equal T // Columns : equal P
        for iLevel2 = 1:length(pressureArray)
            HySolver.CanSolve = 0 ;
            HyStream.Pressure.SetValue(pressureArray(iLevel2),pressureUnits) ;
            HySolver.CanSolve = 1 ;
            for iLevel3 = 1:length(temperatureArray) 
                HySolver.CanSolve = 0 ;
                % Set stream temperature
                HyStream.Temperature.SetValue(temperatureArray(iLevel3),temperatureUnits) ; 
                HySolver.CanSolve = 1;
                % Read Molar heat capacity
                MolarHeatCapacityArray(iLevel3,iLevel2) = HyStream.MolarHeatCapacity.GetValue(heatCapacityUnits); 
            end
        end
        
        Name = Component(iLevel1).Name ;
        
        if length(pressureArray) == nPoints
            Component(iLevel1).MolarHeatCapacityAverage = [] ;
            Component(iLevel1).MolarHeatCapacityFunction = [] ;
            % fit the Heat Capacity as a function of temperature and pressure to a polynomial expression
            Component(iLevel1).MolarHeatCapacityFunction_withPressure = fit_to_a_surface(temperatureArray,pressureArray,MolarHeatCapacityArray);
        else
            Component(iLevel1).MolarHeatCapacityFunction_withPressure = [] ;
            % fit the Heat Capacity as a function of temperature to a polynomial expression
            Component(iLevel1).MolarHeatCapacityFunction = fit_to_a_polynomial(temperatureArray,MolarHeatCapacityArray);
            % Compute average molar heat capacity
            Component(iLevel1).MolarHeatCapacityAverage = ...
                trapz(temperatureArray,Component(iLevel1).MolarHeatCapacityFunction(temperatureArray)) / ...
                (temperatureUp - temperatureLo);
        end
    end
    
    % Close the file after all properties are computed
    HyCase.Close(HyFilename) ;
end 

%% Functions to fit the data obtained from Hysys to a polynomial expression
function polynomial = fit_to_a_polynomial(xData,yData)
global heatCapacityUnits temperatureUnits Name
%>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
displayFigure = true;
ft = fittype( 'poly2' );
%<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
xData = xData(:); % convert to a column vector
yData = yData(:);
polynomial = fit( xData, yData, ft ); % Fit model to data.

    if displayFigure
        figure( 'Name', 'untitled fit 1' );
        hold on
        plot( xData, yData,'o')
        plot (xData,polynomial(xData),'-');
        legend( 'Original data', 'fitting function' );
        xlabel(string(['Temperature(',temperatureUnits,')'])) ;
        ylabel(string(['Molar Heat Capacity (',heatCapacityUnits,')'])) ;
        title(sprintf('Heat Capacity of %s',Name)) ;
        grid on
    end
end

function surface = fit_to_a_surface(xData,yData,zData)
global heatCapacityUnits temperatureUnits pressureUnits Name
%>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
displayFigure = true;
ft = fittype( 'poly22' );
%<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

[xData, yData, zData] = prepareSurfaceData(xData,yData,zData);
surface = fit([xData,yData],zData,ft,'Normalize','on');

    if displayFigure
        figure( 'Name', 'untitled fit 1' );
        plot(surface,[xData,yData],zData)
        xlabel(string(['Temperature(',temperatureUnits,')'])) ;
        ylabel(string(['Pressure(',pressureUnits,')'])) ;
        zlabel(string(['Molar Heat Capacity (',heatCapacityUnits,')'])) ;
        title(sprintf('Heat Capacity of %s',Name)) ;
    end
end