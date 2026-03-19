classdef CSTR < Reactor
    % This subclass defines a CSTR
    % Features:
    %   - Fix the parameters particular to a CSTR
    %   - Compute the output stream of individual CSTRs
    % =========================================================================
    % Isabela Fons Moreno-Palancas
    % Created: March 14, 2020. Last update: April 20, 2020
    % =========================================================================
    properties (Hidden = true) % This property is not displayed on the property list
        heatFlux % Stores the value of Q >> Useful to compute OPEX
    end
    
    methods
        
        function [Product,R] = compute_output(R,Feed,RS)
            %% @compute_output computes the composition, T and P of a CSTR
            % Features:
            %   - Pressure of the feed and product streams is assumed to be equal
            % =========================================================================
            % Isabela Fons Moreno-Palancas
            % Last update: March 27, 2020
            % =========================================================================%
            
            %%
            Guess = [Feed.molarFlow , Feed.T, Feed.P] ;
            options = optimoptions('fsolve','Display','none');
            y = fsolve(@fsolveCSTR,Guess,options) ;
            
            % Mass balance in the mixer
            moles_beforeMix = y(1:RS.nComponents) ;
            moles_bypass = Feed.molarFlow*R.bypassRatio/(1+R.bypassRatio) ;
            moles_out = moles_beforeMix + moles_bypass ;
            % Momentum balance in the mixer
            P_out = y(RS.nComponents+2) ;
            % Energy balance in the mixer
            T_beforeMix = y(RS.nComponents+1) ;
            componentCp_beforeMix = RS.compute_HeatCapacity(T_beforeMix,P_out) ;
            componentCp_bypass    = RS.compute_HeatCapacity(Feed.T,Feed.P) ;
            T_out = (componentCp_beforeMix*moles_beforeMix'*T_beforeMix + componentCp_bypass*moles_bypass'*Feed.T)/(componentCp_beforeMix*moles_beforeMix'+componentCp_bypass*moles_bypass');
            
            % Definition of the product stream
            Product = Stream ;
            Product.molarFlow = moles_out ;
            Product.molarFlow_Units = Feed.molarFlow_Units ;
            Product.T = T_out ;
            Product.P = P_out ;
            Product.phase = Feed.phase ;
            Product.viscosity = Feed.viscosity ;
            Product.volumetricFlow = Feed.volumetricFlow_Units ;
            if strcmp(Product.phase,'L')
                Product.volumetricFlow = Feed.volumetricFlow ; 
                Product.density = Feed.density ;
            end
            %% Solve the NonLinear System
            function y = fsolveCSTR(x)
                
                moles = x(1:RS.nComponents) ;
                T = x(RS.nComponents+1) ;
                P = x(RS.nComponents+2) ;
                
                Rg = 8.31; %J/mol/K
                
                %Rate of reaction
                if Feed.phase == 'L'
                    Qv = Feed.volumetricFlow ;
                elseif Feed.phase =='G'
                    Qv = sum(moles) * Rg * T/P ; %m^3/s
                end
                concentration = moles./Qv ;
                RS = RS.computeRate(concentration,T) ;
                constant_WtoV = (1-R.porosityCatalyst)*R.densityCatalyst ; % constant_WtoV is a conversion factor to change from mol/(time·kg cat) to mol/(time·m^3 reactor)
                r_i = constant_WtoV * RS.r_i ; %[1 x nReactions]
                r_j = r_i*RS.stochiometricMatrix ; %[1 x nComponents]
                               
                % Mass balance
                moles_inlet = Feed.molarFlow/(1+R.bypassRatio) ;
                y(1:RS.nComponents) = moles_inlet - moles + r_j*R.V ;
                
                %Energy balance
                componentCp = RS.compute_HeatCapacity(T,P) ;
                DH = RS.DHref + componentCp * RS.stochiometricMatrix' * (T-RS.Tref) ; %[1xnReactions]
                
                if strcmp(R.heatMode,'Isothermal') == 1
                    y(RS.nComponents+1) = T - Feed.T ;
                    R.heatFlux = Feed.molarFlow*componentCp'*(T-Feed.T) - R.V*r_i*DH' ; 
                else
                    if strcmp(R.heatMode,'Adiabatic') == 1
                        Q = 0;
                    elseif strcmp(R.heatMode,'Other') == 1
                        if isempty(R.outletUtilityTemperature)
                            meanUtilityTemperature = (R.inletUtilityTemperature - R.outletUtilityTemperature)/log(R.inletUtilityTemperature/R.outletUtilityTemperature) ;
                        else
                            meanUtilityTemperature = R.inletUtilityTemperature ;
                        end
                        Q = R.U * R.heatTransferArea * (meanUtilityTemperature - T) ;
                        R.heatFlux = Q ;
                    end
                    
                    y(RS.nComponents+1) = Feed.molarFlow*componentCp'*(T-Feed.T) - R.V*r_i*DH' - Q ;
                end
                
                % Momentum balance
                y(RS.nComponents+2) = P - Feed.P ;
                
                y = y';
                
            end
        end
        
    end
end

