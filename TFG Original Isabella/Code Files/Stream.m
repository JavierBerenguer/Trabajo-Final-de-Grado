classdef Stream
% This class defines a stream (feed or product)
% Features:
%   - Fix the variables that define the stream
% =========================================================================
% Isabela Fons Moreno-Palancas
% Last update: March 28, 2020
% =========================================================================
   
    properties
        molarFlow
        molarFlow_Units
        concentration
        volumetricFlow
        volumetricFlow_Units
        density
        P = 101325 ; %Pa
        T = 298.15 ; %K
        viscosity
        phase
        streamMolarEnthalpy 
        streamHeatCapacity
    end
    
    methods
        
        function F = set.molarFlow(F,molarFlow)
            F.molarFlow = molarFlow ;
        end
        
        function molarFlow = get.molarFlow(F)
            if isempty(F.molarFlow) 
                molarFlow = F.concentration * F.volumetricFlow ;
            else
                molarFlow = F.molarFlow ; 
            end
        end
        
        function F = set.concentration(F,concentration)
            F.concentration = concentration ;
        end
        
        function concentration = get.concentration(F)
            if isempty(F.concentration) 
                concentration = F.molarFlow / F.volumetricFlow ;
            else
                concentration = F.concentration ;
            end
        end
        
        function F = set.volumetricFlow(F,volumetricFlow)
            F.volumetricFlow = volumetricFlow ;
        end
        
        function volumetricFlow = get.volumetricFlow(F)
            if isempty(F.volumetricFlow) 
                if strcmp(F.phase,'L')
                    volumetricFlow = F.molarFlow / F.concentration ;
                elseif strcmp(F.phase,'G')
                    volumetricFlow = sum(F.molarFlow)*8.314*F.T/F.P ;
                end
            else
                volumetricFlow = F.volumetricFlow ;
            end
        end
        
        function F = set.molarFlow_Units(F,molarFlow_Units)
            if ischar(molarFlow_Units)
                F.molarFlow_Units = molarFlow_Units;
            end
        end
        
        function F = set.volumetricFlow_Units(F,volumetricFlow_Units)
            if ischar(volumetricFlow_Units)
                F.volumetricFlow_Units = volumetricFlow_Units;
            end
        end
        
        function F = set.P(F,P)
            F.P = P ;
        end
        
        function F = set.T(F,T)
            F.T = T ;
        end
        
        function F = set.density(F,density)
            F.density = density ;
        end
        
        
        function F = set.viscosity(F,viscosity)
            F.viscosity = viscosity ;
        end
        
        function F = set.phase(F,phase)
            phase_options = {'L' 'G'};
            switch phase
                case phase_options
                    F.phase = phase ;
                otherwise
                    error ('Invalid phase. Only type L or G');
            end
        end
        
        function streamCopy = defineStreamFromHysys(streamCopy,workingDirectory, fileName, streamName)
            if isempty(workingDirectory)
                workingDirectory = pwd ; % Command to get the current directory
            end
            %% STEP 1: Find the .xml file
            
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
            HyOperations        = HyFlowsheet.Operations;
            HyEnergyStreams     = HyFlowsheet.EnergyStreams;
            HyComponents        = HyFlowsheet.FluidPackage.Components;
            
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
            
            %% STEP 4: Read properties from the selected stream
            % >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            pressureUnits = 'Pa' ;
            temperatureUnits = 'K' ;
            molarEnthalpyUnits = 'kJ/kgmole' ;
            componentMolarFlowUnits = 'gmole/s' ;
            volumeFlowUnits = 'm3/s' ;
            molarHeatCapacityUnits = 'kJ/kgmole-C' ;
            massDensityUnits = 'kg/m3' ;
            viscosityUnits = 'Pa-s' ;
            %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            
            HyStream = get(HyMaterialStreams,'Item',streamName) ;
            
            streamCopy.P                    = HyStream.Pressure.GetValue(pressureUnits) ;
            streamCopy.T                    = HyStream.Temperature.GetValue(temperatureUnits) ;
            streamCopy.volumetricFlow       = HyStream.ActualVolumeFlow.GetValue(volumeFlowUnits) ;
            streamCopy.density              = HyStream.MassDensity.GetValue(massDensityUnits) ;
            streamCopy.viscosity            = HyStream.Viscosity.GetValue(viscosityUnits) ;
            streamCopy.molarFlow            = HyStream.ComponentMolarFlow.GetValues(componentMolarFlowUnits) ;
            streamCopy.concentration        = streamCopy.molarFlow/streamCopy.volumetricFlow ;
            streamCopy.streamMolarEnthalpy  = HyStream.MolarEnthalpy.GetValue(molarEnthalpyUnits) ;
            streamCopy.streamHeatCapacity   = HyStream.MolarHeatCapacity.GetValue(molarHeatCapacityUnits) ;
            if HyStream.VapourFractionValue == 1
                streamCopy.phase = 'G' ;
            else
                streamCopy.phase = 'L' ;
            end
            
        end
        
    end
end

