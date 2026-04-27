classdef TanksInSeries < Reactor
% This subclass models a non-ideal reactor using the Tanks-in-Series model.
% Features:
%   - Models non-ideal behaviour as N equal-sized CSTRs in series
%   - Computes RTD analytically
%   - Solves N sequential CSTR balances for general kinetics
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: April 26, 2026
% =========================================================================

% Internal units (SI):
%   time: s | volume: m^3 | concentration: mol/m^3
%   flow: m^3/s | pressure: Pa | temperature: K
%   k(1st): 1/s | k(2nd): m^3/(mol*s) | energy: J/mol

    % [HYSYS] N podria estimarse desde geometria del reactor +
    %         propiedades de fluido (Re, viscosidad) via correlaciones.
    %         Tambien puede calcularse desde RTD experimental (N = tau^2/sigma^2).
    properties
        nTanks = 1          % Number of tanks in series (can be non-integer for RTD)
        nTanks_method = 'manual'  % 'manual' or 'from_rtd'
    end

    properties (SetAccess = private)
        rtd                 % RTD object associated with this model
    end

    methods

        %% ============== SETTERS ==============

        function R = set.nTanks(R, n)
            if n <= 0
                error('Number of tanks must be positive') ;
            end
            R.nTanks = n ;
        end

        function R = set.nTanks_method(R, method)
            valid = {'manual', 'from_rtd'} ;
            if ~ismember(method, valid)
                error('nTanks_method must be ''manual'' or ''from_rtd''') ;
            end
            R.nTanks_method = method ;
        end

        %% ============== GENERATE RTD FOR THIS MODEL ==============

        function R = generate_RTD(R, tau_total, tspan)
            % Generate the analytical RTD for this tanks-in-series configuration
            %
            % Inputs:
            %   tau_total - total mean residence time (s). If not given, uses V/Qv
            %   tspan     - (optional) time vector

            if nargin < 2 || isempty(tau_total)
                error('Must provide tau_total (mean residence time)') ;
            end

            if nargin < 3
                tspan = linspace(0, 5 * tau_total, 500) ;
            end

            R.rtd = RTD.tanks_in_series(R.nTanks, tau_total, tspan) ;
        end

        %% ============== COMPUTE OUTPUT ==============

        function [Product, R] = compute_output(R, Feed, RS)
            %% @compute_output computes the output of N CSTRs in series
            % Uses N integer CSTRs solved sequentially.
            % If nTanks is non-integer, rounds to nearest integer for
            % the sequential computation.
            %
            % This method reuses the existing CSTR class.
            % =========================================================================
            % Javier Berenguer Sabater
            % Last update: March 21, 2026
            % =========================================================================

            N = round(R.nTanks) ;  % Must be integer for sequential computation
            if N < 1
                N = 1 ;
            end
            if abs(R.nTanks - N) > 0.01
                warning('TIS:nonIntegerN', ...
                    'Rounding N = %.2f to %d for sequential CSTR computation.', ...
                    R.nTanks, N) ;
            end

            % Volume per tank
            Vi = R.V / N ;

            % Create N identical CSTRs
            sequence = cell(1, N) ;
            for i = 1:N
                cstr_i = CSTR ;
                cstr_i.V = Vi ;
                cstr_i.V_Units = R.V_Units ;
                cstr_i.heatMode = R.heatMode ;
                cstr_i.U = R.U ;
                cstr_i.heatTransferArea = R.heatTransferArea ;
                cstr_i.inletUtilityTemperature = R.inletUtilityTemperature ;
                cstr_i.outletUtilityTemperature = R.outletUtilityTemperature ;
                cstr_i.densityCatalyst = R.densityCatalyst ;
                cstr_i.porosityCatalyst = R.porosityCatalyst ;
                cstr_i.pressureMode = R.pressureMode ;
                cstr_i.bypassRatio = 0 ;  % No bypass on individual tanks
                cstr_i.activatePlots = 'off' ;
                sequence{i} = cstr_i ;
            end

            % Solve in series using parent class method
            [Product, sequence] = compute_series(R, Feed, RS, sequence) ;

            % Apply global bypass if any
            if R.bypassRatio > 0
                moles_bypass = Feed.molarFlow * R.bypassRatio / (1 + R.bypassRatio) ;
                Product.molarFlow = Product.molarFlow + moles_bypass ;
                % Energy balance for bypass mixing
                componentCp_product = RS.compute_HeatCapacity(Product.T, Product.P) ;
                componentCp_bypass  = RS.compute_HeatCapacity(Feed.T, Feed.P) ;
                T_mix = (componentCp_product * Product.molarFlow' * Product.T + ...
                         componentCp_bypass * moles_bypass' * Feed.T) / ...
                        (componentCp_product * Product.molarFlow' + ...
                         componentCp_bypass * moles_bypass') ;
                Product.T = T_mix ;
            end

            % Generate RTD if plots are activated
            if strcmp(R.activatePlots, 'on')
                tau_total = R.V / Feed.volumetricFlow ;
                R = R.generate_RTD(tau_total) ;
                R.rtd.plot_all() ;
            end
        end

    end

    methods (Static)

        function [C_out, X] = solve_sequential(N, RS, C0, tau_total)
            %% solve_sequential - General sequential CSTR solver
            % Solves N equal-sized CSTRs in series for ANY kinetics
            % defined in a ReactionSys object.
            %
            % Each tank balance (isothermal, constant density):
            %   C_out - C_in - tau_i * r(C_out) * stoich = 0
            %
            % Inputs:
            %   N         - Number of tanks (rounded to integer)
            %   RS        - ReactionSys object (from fromSimpleKinetics or manual)
            %   C0        - Initial concentration vector [1 x nComponents]
            %   tau_total - Total mean residence time [s]
            %
            % Outputs:
            %   C_out - Outlet concentration vector [1 x nComponents]
            %   X     - Conversion of first component: X = 1 - C_out(1)/C0(1)

            N_int = round(N) ;
            if N_int < 1, N_int = 1 ; end
            tau_i = tau_total / N_int ;
            T = 298.15 ;  % isothermal — Ea=0 so T is irrelevant
            stoich = RS.stochiometricMatrix ;
            nComp = length(C0) ;

            C_in = C0 ;
            opts = optimoptions('fsolve', 'Display', 'off', ...
                'FunctionTolerance', 1e-12, 'OptimalityTolerance', 1e-12) ;

            for i = 1:N_int
                residual = @(Cout) TanksInSeries.cstr_balance( ...
                    Cout, C_in, tau_i, RS, T, stoich) ;
                [C_out, ~, exitflag] = fsolve(residual, C_in, opts) ;
                C_out = max(C_out, 0) ;
                C_in = C_out ;
            end

            X = 1 - C_out(1) / C0(1) ;
        end

        function [C_out, X] = solve_PFR(RS, C0, tau_total)
            %% solve_PFR - PFR reference via ODE integration
            % Solves dC/dtau = r(C) * stoich for the plug flow reactor.
            %
            % Inputs:
            %   RS        - ReactionSys object
            %   C0        - Initial concentration vector [1 x nComponents]
            %   tau_total - Total mean residence time [s]
            %
            % Outputs:
            %   C_out - Outlet concentration vector [1 x nComponents]
            %   X     - Conversion of first component

            T = 298.15 ;
            stoich = RS.stochiometricMatrix ;
            nComp = length(C0) ;

            odefun = @(t, C) TanksInSeries.pfr_ode(C, RS, T, stoich) ;
            odeOpts = odeset('NonNegative', 1:nComp, 'RelTol', 1e-8) ;
            [~, C] = ode45(odefun, [0 tau_total], C0(:), odeOpts) ;

            C_out = C(end, :) ;
            X = 1 - C_out(1) / C0(1) ;
        end

        function F = cstr_balance(C_out, C_in, tau_i, RS, T, stoich)
            % Residual for CSTR mass balance: F = 0 at steady state
            RS_temp = RS.computeRate(C_out, T) ;
            r = RS_temp.r_i ;
            F = C_out - C_in - tau_i * r * stoich ;
        end

        function dCdt = pfr_ode(C, RS, T, stoich)
            % ODE right-hand side for PFR: dC/dtau = r * stoich
            RS_temp = RS.computeRate(C(:)', T) ;
            r = RS_temp.r_i ;
            dCdt = (r * stoich)' ;
        end

    end
end
