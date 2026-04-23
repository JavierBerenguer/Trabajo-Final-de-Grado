classdef DispersionReactor < Reactor
% DispersionReactor - Non-ideal reactor using the dispersion model
%
% The dispersion model characterizes non-ideal flow by a single parameter:
%   Bo = De/(u*L) = dispersion number (also called 1/Pe)
%
%   Bo → 0  : plug flow (PFR)
%   Bo → ∞  : perfect mixing (CSTR)
%
% Supports two boundary conditions:
%   - 'open-open'     : for open vessels (Gaussian approximation)
%   - 'closed-closed' : for closed vessels (Danckwerts solution)
%
% Features:
%   - Generate RTD for given Bo and tau
%   - Analytical conversion for 1st order reactions (Danckwerts equation)
%   - Numerical conversion for 2nd order reactions
%   - Parametric sweep of conversion vs Bo
%
% Usage:
%   dr = DispersionReactor ;
%   dr.Bo = 0.025 ;
%   dr.boundaryType = 'closed-closed' ;
%   rtd = dr.generate_RTD(10) ;
%   X = dr.compute_conversion_firstOrder(0.1, 10) ;
%
% =========================================================================
% Javier Berenguer Sabater
% Created: March 25, 2026. Last update: March 28, 2026
% =========================================================================

% Internal units (SI):
%   time: s | volume: m^3 | concentration: mol/m^3
%   flow: m^3/s | pressure: Pa | temperature: K
%   k(1st): 1/s | k(2nd): m^3/(mol*s) | energy: J/mol

    % [HYSYS] Bo podria calcularse desde propiedades de fluido:
    %         Bo = De/(u*L), donde De depende de Re y Sc via correlaciones
    %         (e.g., Taylor-Aris). Re y Sc vendrian de Hysys.
    properties
        Bo = 0.01           % Dispersion number De/(u*L)
        boundaryType = 'closed-closed'  % 'open-open' or 'closed-closed'
    end

    properties (SetAccess = private)
        rtd                 % RTD object for current Bo and tau
    end

    methods

        %% ============== CONSTRUCTOR ==============

        function R = DispersionReactor(Bo, bcType)
            % DispersionReactor Constructor
            %   R = DispersionReactor()
            %   R = DispersionReactor(Bo)
            %   R = DispersionReactor(Bo, bcType)

            R@Reactor ;

            if nargin >= 1
                R.Bo = Bo ;
            end
            if nargin >= 2
                R.boundaryType = bcType ;
            end
        end

        %% ============== GENERATE RTD ==============

        function rtd_obj = generate_RTD(obj, tau)
            % Generate RTD for current Bo and boundary conditions
            %   rtd_obj = generate_RTD(obj, tau)

            switch obj.boundaryType
                case 'open-open'
                    rtd_obj = RTD.dispersion_open(obj.Bo, tau) ;
                case 'closed-closed'
                    rtd_obj = RTD.dispersion_closed(obj.Bo, tau) ;
                otherwise
                    error('Unknown boundary condition type: %s', obj.boundaryType) ;
            end

            obj.rtd = rtd_obj ;
        end

        %% ============== FIRST-ORDER CONVERSION ==============

        function X = compute_conversion_firstOrder(obj, k, tau)
            % Analytical conversion for 1st order reaction using
            % the Danckwerts equation (closed-closed BCs):
            %
            %   X = 1 - 4*q*exp(Pe/2) / ((1+q)^2*exp(q*Pe/2) - (1-q)^2*exp(-q*Pe/2))
            %
            % where Pe = 1/Bo, q = sqrt(1 + 4*Da*Bo), Da = k*tau
            %
            % For open-open BCs:
            %   X = 1 - exp((1 - q)/(2*Bo))    (approximate for small Bo)
            %
            % Inputs:
            %   k   - rate constant (1/s)
            %   tau - mean residence time (s)
            %
            % [HYSYS] k podria obtenerse de Arrhenius k=k0*exp(-Ea/RT)
            %         con T de Hysys. tau = V/Q donde Q vendria de Hysys.

            Da = k * tau ;

            % Guard for extreme Bo → 0 (PFR limit): use analytical PFR formula
            if obj.Bo < 1e-6
                X = 1 - exp(-Da) ;  % PFR 1st order
                X = max(0, min(1, X)) ;
                return
            end

            Pe = 1 / obj.Bo ;

            switch obj.boundaryType
                case 'closed-closed'
                    q = sqrt(1 + 4 * Da * obj.Bo) ;
                    % Guard against numerical overflow for large Pe
                    if Pe > 500
                        X = 1 - exp(-Da) ;  % PFR limit
                    else
                        num = 4 * q * exp(Pe / 2) ;
                        den = (1 + q)^2 * exp(q * Pe / 2) - ...
                              (1 - q)^2 * exp(-q * Pe / 2) ;
                        X = 1 - num / den ;
                    end

                case 'open-open'
                    q = sqrt(1 + 4 * Da * obj.Bo) ;
                    X = 1 - exp((1 - q) / (2 * obj.Bo)) ;
            end

            % Clamp to [0, 1]
            X = max(0, min(1, X)) ;
        end

        %% ============== SECOND-ORDER CONVERSION ==============

        function X = compute_conversion_secondOrder(obj, k, CA0, tau)
            % Numerical conversion for 2nd order reaction (-rA = k*CA^2)
            % using the segregation model approach with the dispersion RTD.
            %
            % Inputs:
            %   k   - rate constant (m^3/(mol*s))
            %   CA0 - initial concentration (mol/m^3)
            %   tau - mean residence time (s)
            %
            % [HYSYS] k podria obtenerse de Arrhenius k=k0*exp(-Ea/RT).
            %         CA0 y tau podrian venir de corriente Hysys.

            rtd_obj = obj.generate_RTD(tau) ;

            t_rtd = rtd_obj.t ;
            Et = rtd_obj.Et ;

            % Batch conversion for 2nd order: X(t) = k*CA0*t / (1 + k*CA0*t)
            X_batch = (k * CA0 * t_rtd) ./ (1 + k * CA0 * t_rtd) ;

            % Segregation integral
            X = trapz(t_rtd, X_batch .* Et) ;
            X = max(0, min(1, X)) ;
        end

        %% ============== PARAMETRIC SWEEP ==============

        function [Bo_vec, X_vec] = sweep_Bo(obj, k, tau, CA0, order, n_points)
            % Compute conversion for a range of Bo values
            %
            % Inputs:
            %   k        - rate constant
            %   tau      - mean residence time (s)
            %   CA0      - initial concentration (only for 2nd order)
            %   order    - 1 or 2
            %   n_points - number of points (default 50)
            %
            % Outputs:
            %   Bo_vec - [1 x n_points] Bo values (log-spaced)
            %   X_vec  - [1 x n_points] conversion values

            if nargin < 6
                n_points = 50 ;
            end

            Bo_vec = logspace(-3, 1, n_points) ;
            X_vec = zeros(size(Bo_vec)) ;

            saved_Bo = obj.Bo ;

            for i = 1:n_points
                obj.Bo = Bo_vec(i) ;
                if order == 1
                    X_vec(i) = obj.compute_conversion_firstOrder(k, tau) ;
                else
                    X_vec(i) = obj.compute_conversion_secondOrder(k, CA0, tau) ;
                end
            end

            obj.Bo = saved_Bo ;
        end

        %% ============== GENERAL KINETICS (ReactionSys) ==============

        function [X, C_out] = compute_conversion_general(obj, RS, C0, tau)
            % Numerical conversion for any kinetics defined by ReactionSys,
            % using the segregation approach with the dispersion RTD.
            %
            %   X = integral( X_batch(t) * E(t) dt )
            %
            % where X_batch(t) is solved from the batch ODE:
            %   dC/dt = r(C) * stoich
            %
            % Inputs:
            %   RS  - ReactionSys object (any kinetics)
            %   C0  - [1 x nComponents] initial concentration vector
            %   tau - mean residence time (s)
            %
            % Outputs:
            %   X     - conversion of key component (component 1)
            %   C_out - [1 x nComp] mean outlet concentrations

            rtd_obj = obj.generate_RTD(tau) ;
            t_rtd = rtd_obj.t ;
            Et = rtd_obj.Et ;

            stoich = RS.stochiometricMatrix ;
            nComp = length(C0) ;
            T = 298.15 ;  % isothermal (Ea=0 → T irrelevant)

            % Solve batch ODE
            odeOpts = odeset('NonNegative', 1:nComp, 'RelTol', 1e-8) ;
            [t_ode, C_ode] = ode45(@(t, C) batch_ode(C), ...
                [0, max(t_rtd)], C0(:), odeOpts) ;

            % Conversion of key component (index 1)
            X_vs_t = (C0(1) - C_ode(:, 1)) / C0(1) ;

            % Interpolate at RTD time points
            X_batch = interp1(t_ode, X_vs_t, t_rtd, 'pchip', 0) ;
            X_batch = X_batch(:)' ;  % force row [1 x N]

            % Segregation integral
            X = trapz(t_rtd, X_batch .* Et) ;
            X = max(0, min(1, X)) ;

            % Mean outlet concentrations (optional)
            if nargout >= 2
                C_interp = interp1(t_ode, C_ode, t_rtd, 'pchip') ;
                C_out = zeros(1, nComp) ;
                for j = 1:nComp
                    C_out(j) = trapz(t_rtd, C_interp(:, j)' .* Et) ;
                end
            end

            function dCdt = batch_ode(C)
                RS_temp = RS.computeRate(C(:)', T) ;
                r = RS_temp.r_i ;
                dCdt = (r * stoich)' ;
            end
        end

        function [Bo_vec, X_vec] = sweep_Bo_general(obj, RS, C0, tau, n_points)
            % Parametric sweep of conversion vs Bo for general kinetics
            %
            % Inputs:
            %   RS       - ReactionSys object
            %   C0       - [1 x nComp] initial concentrations
            %   tau      - mean residence time (s)
            %   n_points - number of points (default 50)

            if nargin < 5
                n_points = 50 ;
            end

            Bo_vec = logspace(-3, 1, n_points) ;
            X_vec = zeros(size(Bo_vec)) ;

            saved_Bo = obj.Bo ;

            for i = 1:n_points
                obj.Bo = Bo_vec(i) ;
                X_vec(i) = obj.compute_conversion_general(RS, C0, tau) ;
            end

            obj.Bo = saved_Bo ;
        end

    end
end
