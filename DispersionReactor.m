classdef DispersionReactor < Reactor
% DispersionReactor - Non-ideal reactor using the dispersion model
%
% The dispersion model characterizes non-ideal flow by a single parameter:
%   Bo = De/(u*L) = dispersion number (also called 1/Pe)
%
%   Bo -> 0  : plug flow (PFR)
%   Bo -> inf: perfect mixing (CSTR)
%
% The current toolbox workflow uses:
%   - generate_RTD()
%   - compute_conversion_general()
%   - sweep_Bo_general()
% =========================================================================
% Javier Berenguer Sabater
% Created: March 25, 2026. Last update: April 26, 2026
% =========================================================================

% Internal units (SI):
%   time: s | volume: m^3 | concentration: mol/m^3
%   flow: m^3/s | pressure: Pa | temperature: K
%   k(1st): 1/s | k(2nd): m^3/(mol*s) | energy: J/mol

    properties
        Bo = 0.01           % Dispersion number De/(u*L)
        boundaryType = 'closed-closed'  % 'open-open' or 'closed-closed'
    end

    properties (SetAccess = private)
        rtd                 % RTD object for current Bo and tau
    end

    methods

        function R = DispersionReactor(Bo, bcType)
            R@Reactor ;

            if nargin >= 1
                R.Bo = Bo ;
            end
            if nargin >= 2
                R.boundaryType = bcType ;
            end
        end

        function rtd_obj = generate_RTD(obj, tau)
            % Generate RTD for current Bo and boundary conditions.

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

        function [X, C_out] = compute_conversion_general(obj, RS, C0, tau)
            % Numerical conversion for any kinetics defined by ReactionSys,
            % using the segregation approach with the dispersion RTD.
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
            T = 298.15 ;

            odeOpts = odeset('NonNegative', 1:nComp, 'RelTol', 1e-8) ;
            [t_ode, C_ode] = ode45(@(t, C) batch_ode(C), ...
                [0, max(t_rtd)], C0(:), odeOpts) ;

            X_vs_t = (C0(1) - C_ode(:, 1)) / C0(1) ;
            X_batch = interp1(t_ode, X_vs_t, t_rtd, 'pchip', 0) ;
            X_batch = X_batch(:)' ;

            X = trapz(t_rtd, X_batch .* Et) ;
            X = max(0, min(1, X)) ;

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
            % Parametric sweep of conversion vs Bo for general kinetics.

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
