classdef MaxMixednessModel
% This class implements the Maximum Mixedness Model for predicting
% conversion in non-ideal reactors.
%
% In maximum mixedness, fluid mixes as early as possible. The model uses
% life expectancy (lambda), the time remaining before a fluid element
% exits the reactor.
%
% The current toolbox workflow uses the general ReactionSys-based
% isothermal route implemented in compute_isothermal().
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: April 26, 2026
% =========================================================================

% Internal units (SI):
%   time: s | volume: m^3 | concentration: mol/m^3
%   flow: m^3/s | pressure: Pa | temperature: K
%   k(1st): 1/s | k(2nd): m^3/(mol*s) | energy: J/mol

    properties
        rtd                 % RTD object
        keyComponentIndex = 1  % Index of the key component for conversion
    end

    properties (SetAccess = private)
        X_exit              % Exit conversion X(lambda=0) (result)
        lambda_profile      % [1 x M] life expectancy vector
        X_profile           % [1 x M] conversion profile X(lambda)
    end

    methods

        function obj = MaxMixednessModel(varargin)
            % MaxMixednessModel Constructor
            %   obj = MaxMixednessModel()
            %   obj = MaxMixednessModel(rtd_obj)
            %
            % Extra legacy arguments are ignored. The current non-ideal
            % workflow only requires the RTD object.

            if nargin == 0
                return
            end

            obj.rtd = varargin{1} ;
        end

        function obj = compute_isothermal(obj, RS, C0)
            % Compute exit conversion using a general ReactionSys object
            % under isothermal conditions.
            %
            % ODE (in X space for key component):
            %   dX/d(lambda) = rA(C)/CA0 + E(lambda)/(1-F(lambda)) * X
            %
            % Inputs:
            %   RS  - ReactionSys object (any kinetics)
            %   C0  - Initial concentration vector [1 x nComponents]

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;
            stoich = RS.stochiometricMatrix ;
            nComp = length(C0) ;
            T = 298.15 ;
            idx_key = obj.keyComponentIndex ;
            CA0 = C0(idx_key) ;

            E_interp = griddedInterpolant(t_rtd, Et, 'pchip', 'nearest') ;
            F_interp = griddedInterpolant(t_rtd, Ft, 'pchip', 'nearest') ;

            valid_idx = find((1 - Ft) > 1e-6, 1, 'last') ;
            if isempty(valid_idx)
                lambda_max = max(t_rtd) * 0.95 ;
            else
                lambda_max = t_rtd(valid_idx) ;
            end

            options = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;

            if nComp == 1
                [lambda_sol, X_sol] = ode45(@ode_single, ...
                    [lambda_max, 0], 0, options) ;
            else
                [lambda_sol, X_sol] = ode45(@ode_multi, ...
                    [lambda_max, 0], 0, options) ;
            end

            X_sol = max(min(X_sol, 1), 0) ;

            obj.lambda_profile = flip(lambda_sol') ;
            obj.X_profile = flip(X_sol') ;
            obj.X_exit = X_sol(end) ;

            function dXdlambda = ode_single(lambda, X)
                E_val = E_interp(lambda) ;
                F_val = F_interp(lambda) ;
                denom = max(1 - F_val, 1e-12) ;

                CA = CA0 * (1 - X) ;
                RS_local = RS.computeRate(CA, T) ;
                nu_key = stoich(:, idx_key) ;
                rA = RS_local.r_i * nu_key ;

                dXdlambda = rA / CA0 + (E_val / denom) * X ;
            end

            function dXdlambda = ode_multi(lambda, X)
                E_val = E_interp(lambda) ;
                F_val = F_interp(lambda) ;
                denom = max(1 - F_val, 1e-12) ;

                % Current app workflow assumes C0 = [CA0, 0, ...] and
                % reconstructs the state from the key-component conversion.
                C = C0 ;
                C(idx_key) = CA0 * (1 - X) ;

                RS_local = RS.computeRate(C, T) ;
                nu_key = stoich(:, idx_key) ;
                rA = RS_local.r_i * nu_key ;

                dXdlambda = rA / CA0 + (E_val / denom) * X ;
            end
        end

    end
end
