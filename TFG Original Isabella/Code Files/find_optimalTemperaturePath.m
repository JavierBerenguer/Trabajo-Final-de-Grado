function [minimumTime,minimumVolume] = find_optimalTemperaturePath(Feed,Product,R,RS,keyComponentIndex)
%%
% This function is only valid for exothermic reversible reactions.
% Features:
% - Computes the locus of maximum rates
% - Computes the minimum reaction time and minimum volume required to achieve the product specifications
% Aspects to improve:
% - 17/03 : Still doesn't work for adiabatic reactors because computation time is too long
% - 08/06: Two problems have been detected
%     1. The solution of the optimization is highly dependent of the guess
%     value for the temperature >> can me modified in lines 75 and 146.
%     2. The temperature upper bound is fixed. Only can be modified from
%     line 25. An improvement would be enabling the user to specify it.
% =========================================================================
% Isabela Fons Moreno-Palancas
% Created: March 14th, 2020. Last update: June 27th, 2020
% =========================================================================

if rank(RS.stochiometricMatrix) == 1 && RS.DHref(1) <= 0
    global keyComponentIndex

    %% STEP 1: Plot T vs conversion chart
    %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    temperatureLB = -10 + 273.15 ; %K
    temperatureUB = 100 + 273.15 ; %K
    nPoints = 50 ;
    %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    temperatureAxis    = linspace(temperatureLB,temperatureUB+10,nPoints) ;
    conversionAxis     = linspace(0,1,nPoints) ;
    [temperatureMesh , conversionMesh] = meshgrid(temperatureAxis,conversionAxis) ;
    rateMesh = zeros(nPoints,nPoints) ;
    for i = 1:nPoints
        for ii = 1:nPoints
            temperature = temperatureMesh(i,ii) ;
            conversion  = conversionMesh(i,ii) ;
            extent      = Feed.molarFlow(keyComponentIndex)*conversion/(-RS.stochiometricMatrix(1,keyComponentIndex)) ;
            moles       = Feed.molarFlow + extent * RS.stochiometricMatrix(1,:) ;
            if strcmp(Feed.phase, 'L')
                Qv = Feed.volumetricFlow ;
            elseif strcmp(Feed.phase, 'G')
                Rg = 8.314 ; % Pa·m^3/mol/K
                Qv = sum(moles) * Rg * temperature/Feed.P ; %m^3/s
            end
            concentration = moles/Qv ; %mol/m^3
            RS = RS.computeRate(concentration,temperature) ;
            rate = RS.r_i ;
            if length(rate) == 2
                rate = rate(1) - rate(2) ; %As the reaction is exothermic, the "total" rate = rate_direct - rate_inverse
            end
            rateMesh(i,ii) = rate ;
        end
    end
    
    % Plot contour lines
    Concentration_vs_Temperature = figure ;
    figure(Concentration_vs_Temperature)
    valuesOfRateShown = prctile(rateMesh(rateMesh>=0), linspace(0, 100, nPoints));
    
    [contourMatrix,contourObject] = contour(temperatureMesh-273.15,conversionMesh,rateMesh,valuesOfRateShown);
    xlabel('Temperature (ºC)'),ylabel('Conversion'),title('Optimal temperature progression'),
    colorbarObj = colorbar ;
    colorbarObj.Label.String = 'Rate of reaction (mol/(m³·s))';
    colorbarObj.Limits = [min(valuesOfRateShown), max(valuesOfRateShown)] ;
    
    hold on
    [contourMatrix0,contourObject0] = contour(temperatureMesh-273.15,conversionMesh,rateMesh,[0,0],'LineWidth',1.5,'LineColor','k') ;
    clabel(contourMatrix0,contourObject0,0); hold off
    
    %% STEP 2: Find the optimal temperature for each value of conversion (this step is independent on the type of reactor)
    conversionUB = (Feed.molarFlow(keyComponentIndex)-Product.molarFlow(keyComponentIndex))/Feed.molarFlow(keyComponentIndex) ;
    conversionArray = linspace(0,conversionUB) ;
    optimalTemperatureArray = zeros(1,length(conversionArray)) ;
    maximumRateArray = zeros(1,length(conversionArray)) ;
    %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    guessTemperature = Feed.T ; % Initial guess for the T
    %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    for i = 1:length(conversionArray)
        conversion = conversionArray(i) ;
        % Syntax hint: fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options)
        % Unknowns: T
        fun = @(T) optimize_LocusOfMaximumRates(RS,Feed,conversion,T) ;
        x0 = guessTemperature ; 
        A = [] ;
        b = [] ;
        Aeq = [] ;
        beq = [] ;
        lb = temperatureLB ;
        ub = temperatureUB ;
        nonlcon = compute_nonLinearConstraintsLocus ;
        options = optimoptions('fmincon','MaxIterations',100);

        [T,fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options) ;
        optimalTemperatureArray(i) = T ;
        maximumRateArray(i) = -fval ;
        guessTemperature = T ;
    end
    
    % Plot locus of maximum rates
    figure(Concentration_vs_Temperature)
    hold on
    plotLocus = plot(optimalTemperatureArray - 273.15,conversionArray) ;
    plotLocus.Color = 'r' ;
    plotLocus.LineWidth = 0.75 ;
    
    %% STEP 3: Compute the minimum space time (this step is influenced by the type of reactor)
    % NOTICE space time is only equivalent to residence time if density is constant
      
    % Minimum space time
    if strcmp(class(R),'CSTR')
        % NOTICE the concentration inside the CSTR is the same as in the output stream. Therefore it must work at the maximum rate for the desired conversion.
        minimumVolume = Feed.molarFlow(keyComponentIndex) * conversionArray(end) / (-RS.stochiometricMatrix(1,keyComponentIndex)*maximumRateArray(end)) ;
        R.V = minimumVolume ;
        minimumTime = minimumVolume/Feed.volumetricFlow ;
        
        % Plot trajectory
        figure(Concentration_vs_Temperature)
        hold on
        plotTrajectory = plot(optimalTemperatureArray(end) - 273.15,conversionArray(end),'*') ;
        
    else
        if strcmp(R.heatMode,'Other')
            keyComponentRateArray = RS.stochiometricMatrix(1,keyComponentIndex) * maximumRateArray ;
            inverseMaximumRateArray = -1./keyComponentRateArray ;
            integral = trapz(conversionArray,inverseMaximumRateArray) ;
            if strcmp(class(R),'Batch')
                minimumTime = integral * Feed.molarFlow(keyComponentIndex)/R.V ;
                minimumVolume = [] ;
                R.timeBatch = minimumTime ;
            elseif strcmp(class(R),'PFR')
                minimumVolume = integral * Feed.molarFlow(keyComponentIndex) ;
                R.V = minimumVolume ;
                minimumTime = minimumVolume/Feed.volumetricFlow ;
            end
            
            % Plot trajectory
            figure(Concentration_vs_Temperature)
            hold on
            plotTrajectory = plot(optimalTemperatureArray-273.15,conversionArray) ;
            
        elseif strcmp(R.heatMode,'Isothermal')
            % STEP 1: Find the optimal operating temperature
            
            % Syntax hint: fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options)
            % Unknowns: T
            %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            guessTemperature = Feed.T ; % Initial guess for the temperature
            %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            fun = @(T) optimize_maximumRateAverage(RS,Feed,conversionArray,T) ;
            x0 = guessTemperature ; 
            A = [] ;
            b = [] ;
            Aeq = [] ;
            beq = [] ;
            lb = temperatureLB ;
            ub = temperatureUB ;
            nonlcon = @(T) compute_nonLinearConstraintsIsothermal(RS,Feed,conversionArray,T) ;
            options = optimoptions('fmincon','MaxIterations',100);

            [T,fval] = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options) ;
            optimalIsothermalTemperature = T ;
            
            % STEP 2: compute the reaction rate for each value of conversion at the optimal temperature
            isothermalRateArray  = zeros(size(conversionArray)) ;
            for i = 1:length(conversionArray)
                conversion = conversionArray(i) ;
                isothermalRateArray(i) = computeRateFromConversion(RS,Feed,conversion,optimalIsothermalTemperature) ;
            end
            isothermalKeyComponentRateArray = RS.stochiometricMatrix(1,keyComponentIndex) * isothermalRateArray ;
            
            % STEP 3:
            inverseIsothermalRateArray = -1./isothermalKeyComponentRateArray ;
            
            % The following lines are included because if rate is near zero,its inverse tends to infinity and results make no sense. This problem is solved by eliminating that outliers.
            per99 = prctile(inverseIsothermalRateArray,0.99) ;
            maxValue = max(inverseIsothermalRateArray) ;
            if abs(per99-maxValue)/per99 > 10
                [inverseIsothermalRateArray,TF] = rmoutliers(inverseIsothermalRateArray,'percentiles',[0 99]) ;
                conversionArray = conversionArray(~TF) ;
            end
            
            integral = trapz(conversionArray,inverseIsothermalRateArray) ;
            if strcmp(class(R),'Batch')
                minimumTime = integral * Feed.molarFlow(keyComponentIndex)/R.V ;
                minimumVolume = [] ;
                R.timeBatch = minimumTime ;
            elseif strcmp(class(R),'PFR')
                minimumVolume = integral * Feed.molarFlow(keyComponentIndex) ;
                R.V = minimumVolume ;
                minimumTime = minimumVolume/Feed.volumetricFlow ;
            end
            
            % Plot trajectory
            figure(Concentration_vs_Temperature)
            hold on
            plotTrajectory = plot([optimalIsothermalTemperature,optimalIsothermalTemperature]-273.15,[conversionArray(1),conversionArray(end)]) ;
            
        elseif strcmp(R.heatMode,'Adiabatic')
            optimalTemperature = optimalTemperatureArray(end) ;
            Feed.T = optimalTemperature ;
            error = 1 ;
            tolerance = 1e-6 ;
            if strcmp(class(R),'PFR') && isempty(R.L)
                R.L = R.V/(R.nTubes * pi * (R.diameterTubes/2)^2) ;
            end
            while error > tolerance
                R = R.compute_output(Feed,RS) ;
                error = abs(R.T_out - optimalTemperature) ;
                Feed.T = Feed.T - 0.001 ;
            end
            % Build the Adiabatic Line T = slope * X + intercept
            slope = (optimalTemperature-Feed.T)/conversionArray(end) ;
            intercept = optimalTemperature - slope * conversionArray(end)  ;
            adiabaticTemperatureArray = slope.*converisionArray + intercept ;
            
            % Compute the reaction rate at each point of the Adiabatic Line
            for i = 1:length(conversionArray)
                conversion = conversionArray(i) ;
                T = adiabaticTemperatureArray(i) ;
                extent      = Feed.molarFlow(keyComponentIndex)*conversion/(-RS.stochiometricMatrix(1,keyComponentIndex)) ;
                moles       = Feed.molarFlow + extent * RS.stochiometricMatrix(1,:) ;
                if strcmp(Feed.phase,'L')
                    concentration = moles/Feed.volumetricFlow ;
                elseif strcmp(Feed.phase,'G')
                    concentration = moles/(sum(moles)*8.314*T/Feed.P) ;
                end
                RS = RS.computeRate(concentration,T) ;
                adiabaticRate = RS.r_i ;
                if length(adiabaticRate) == 2
                    adiabaticRate = adiabaticRate(1) - adiabaticRate(2) ; %As the reaction is exothermic, the "total" rate = rate_direct - rate_inverse
                end
            end
            
            % Compute minimum space time
            keyComponentAdiabaticRateArray = RS.stochiometricMatrix(1,keyComponentIndex) * adiabaticRate ;
            inverseAdiabaticRateArray = -1./keyComponentAdiabaticRateArray ;
            integral = trapz(conversionArray,inverseAdiabaticRateArray) ;
            if strcmp(class(R),'Batch')
                minimumTime = integral * Feed.molarFlow(keyComponentIndex)/R.V ;
                minimumVolume = [] ;
                R.timeBatch = minimumTime ;
            elseif strcmp(class(R),'PFR')
                minimumVolume = integral * Feed.molarFlow(keyComponentIndex) ;
                R.V = minimumVolume ;
                minimumTime = minimumVolume/Feed.volumetricFlow ;
            end
            
            % Plot trajectory
            figure(Concentration_vs_Temperature)
            hold on
            plotTrajectory = plot(adiabaticTemperatureArray - 273.15,conversionArray) ;
            
        end
    end
    
    
    % Customize plot
    figure(Concentration_vs_Temperature)
    plotTrajectory.Color = 'b' ;
    plotTrajectory.LineWidth = 1 ;
    lgd = legend('Rate contour lines','Equilibrium','Locus','Trajectory') ;
    xlim([temperatureLB-273.15 temperatureUB-273.15+10]),ylim([0 1])
    grid on
    
end
end

%% Required files
function f = optimize_LocusOfMaximumRates(RS,Feed,conversion,T)
rate = computeRateFromConversion(RS,Feed,conversion,T) ;
% Function fmincon works in the minimization direction. Therefore...
f = -rate ;
end

function f = optimize_maximumRateAverage(RS,Feed,conversionArray,T)
%STEP 1: Compute the reaction reate for every value of conversion (T is fixed)
isothermalRateArray  = zeros(size(conversionArray)) ;
for i=1:length(conversionArray)
    conversion = conversionArray(i) ;
    rate = computeRateFromConversion(RS,Feed,conversion,T) ;
    isothermalRateArray(i) = rate ;
end
%STEP 2: Compute the mean reaction rate (variable to be maximized)
averageRate = 1/conversionArray(end) * trapz(conversionArray,isothermalRateArray) ;
% Function fmincon works in the minimization direction. Therefore...
f = -averageRate ;
end

function [c,ceq] = compute_nonLinearConstraintsLocus
c = [] ;
ceq = [] ;
end

function [c,ceq] = compute_nonLinearConstraintsIsothermal(RS,Feed,conversionArray,T)
isothermalRateArray  = zeros(size(conversionArray)) ;
for i=1:length(conversionArray)
    conversion = conversionArray(i) ;
    rate = computeRateFromConversion(RS,Feed,conversion,T) ;
    isothermalRateArray(i) = rate ;
end
% c(x) must be expressed as c(x)=< 0 and, as rate must be >0...
c = -isothermalRateArray  ;
ceq = [] ;
end

function rate = computeRateFromConversion(RS,Feed,conversion,T)
global keyComponentIndex

extent      = Feed.molarFlow(keyComponentIndex)*conversion/(-RS.stochiometricMatrix(1,keyComponentIndex)) ;
moles       = Feed.molarFlow + extent * RS.stochiometricMatrix(1,:) ;

if strcmp(Feed.phase,'L')
    concentration = moles/Feed.volumetricFlow ;
elseif strcmp(Feed.phase,'G')
    concentration = moles/(sum(moles)*8.314*T/Feed.P) ;
end

RS = RS.computeRate(concentration,T) ;
rate = RS.r_i ;
if length(rate) == 2
    rate = rate(1) - rate(2) ; %As the reaction is exothermic, the "total" rate = rate_direct - rate_inverse
end

end


