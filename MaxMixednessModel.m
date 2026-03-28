classdef MaxMixednessModel
% This class implements the Maximum Mixedness Model for predicting
% conversion in non-ideal reactors.
%
% In maximum mixedness, fluid mixes as early as possible (at the entrance).
% The model uses the concept of "life expectancy" (lambda) - the time
% remaining before a fluid element exits the reactor.
%
% The governing ODE (in terms of conversion X):
%   dX/d(lambda) = r_A/C_A0 + E(lambda)/(1 - F(lambda)) * X
%
% Boundary condition: X(lambda -> infinity) = 0  (i.e., C_A = C_A0)
% Integration proceeds backwards from large lambda to lambda = 0.
% The exit conversion is X(lambda = 0).
%
% This model gives the LOWER BOUND of conversion for reaction orders > 1
% and the UPPER BOUND for reaction orders < 1.
%
% Features:
%   - Compute conversion from RTD and kinetics
%   - Supports first-order, second-order, and general kinetics
%   - Plots X(lambda) profile
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: March 28, 2026
% =========================================================================

% Internal units (SI):
%   time: s | volume: m^3 | concentration: mol/m^3
%   flow: m^3/s | pressure: Pa | temperature: K
%   k(1st): 1/s | k(2nd): m^3/(mol*s) | energy: J/mol

    properties
        rtd                 % RTD object
        reactionSys         % ReactionSys object
        feed                % Stream object (feed conditions)
        V                   % Reactor volume (m^3)
        keyComponentIndex = 1  % Index of the key component for conversion
    end

    properties (SetAccess = private)
        X_exit              % Exit conversion X(lambda=0) (result)
        lambda_profile      % [1 x M] life expectancy vector
        X_profile           % [1 x M] conversion profile X(lambda)
    end

    methods

        %% ============== CONSTRUCTOR ==============

        function obj = MaxMixednessModel(rtd_obj, RS, Feed, V)
            % MaxMixednessModel Constructor
            %   obj = MaxMixednessModel(rtd_obj, RS, Feed, V)
            %
            % Inputs:
            %   rtd_obj - RTD object with E(t) and time vector
            %   RS      - ReactionSys object
            %   Feed    - Stream object (feed conditions)
            %   V       - Reactor volume (m^3)

            if nargin == 0
                return
            end

            obj.rtd = rtd_obj ;
            obj.reactionSys = RS ;
            obj.feed = Feed ;
            obj.V = V ;
        end

        %% ============== COMPUTE (GENERAL KINETICS) ==============

        function obj = compute(obj)
            % Compute exit conversion using the maximum mixedness model
            % with general kinetics from ReactionSys.
            %
            % ODE: dX/d(lambda) = rA(X)/CA0 + E(lambda)/(1-F(lambda)) * X
            % BC: X(lambda_max) = 0
            % Result: X_exit = X(lambda=0)

            if isempty(obj.rtd) || isempty(obj.reactionSys) || isempty(obj.feed)
                error('MaxMixednessModel requires rtd, reactionSys and feed to be set') ;
            end

            % Prepare E(lambda) and F(lambda) as interpolation functions
            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            % Create interpolants
            E_interp = griddedInterpolant(t_rtd, Et, 'pchip', 'nearest') ;
            F_interp = griddedInterpolant(t_rtd, Ft, 'pchip', 'nearest') ;

            % Feed conditions
            RS = obj.reactionSys ;
            CA0 = obj.feed.concentration(obj.keyComponentIndex) ;
            if isempty(CA0) || CA0 <= 0
                CA0 = obj.feed.molarFlow(obj.keyComponentIndex) / obj.feed.volumetricFlow ;
            end
            T = obj.feed.T ;

            % Integration limits: from lambda_max (large) to 0
            % Start from where (1-F) is still significant
            valid_idx = find((1 - Ft) > 1e-6, 1, 'last') ;
            if isempty(valid_idx)
                lambda_max = max(t_rtd) * 0.95 ;
            else
                lambda_max = t_rtd(valid_idx) ;
            end

            % ODE: dX/d(lambda) = rA(X)/CA0 + E(lambda)/(1-F(lambda)) * X
            % Integrate from lambda_max to 0 (backwards)
            options = odeset('RelTol', 1e-10, 'AbsTol', 1e-12, ...
                            'NonNegative', 1) ;

            [lambda_sol, X_sol] = ode45(@ode_maxmix, ...
                                        [lambda_max, 0], 0, options) ;

            obj.lambda_profile = flip(lambda_sol') ;
            obj.X_profile = flip(X_sol') ;
            obj.X_exit = X_sol(end) ;

            fprintf('Maximum Mixedness Model: X_exit = %.4f\n', obj.X_exit) ;

            %% Nested ODE function
            function dXdlambda = ode_maxmix(lambda, X)

                % E(lambda) and F(lambda)
                E_val = E_interp(lambda) ;
                F_val = F_interp(lambda) ;

                % Avoid division by zero when F -> 1
                denominator = 1 - F_val ;
                if denominator < 1e-12
                    denominator = 1e-12 ;
                end

                % Rate of reaction at current conversion
                % CA = CA0 * (1 - X)
                CA = CA0 * (1 - X) ;
                concentration = obj.feed.concentration ;
                if isempty(concentration)
                    concentration = obj.feed.molarFlow / obj.feed.volumetricFlow ;
                end
                % Update key component concentration
                concentration(obj.keyComponentIndex) = CA ;

                RS_local = RS.computeRate(concentration, T) ;

                % Net rate of disappearance of key component
                % rA = sum over all reactions of (r_i * nu_key_i)
                nu_key = RS.stochiometricMatrix(:, obj.keyComponentIndex) ;
                rA = RS_local.r_i * nu_key ;  % negative for disappearance

                % dX/dlambda = rA/CA0 + E/(1-F) * X
                % Note: rA is negative (disappearance), so rA/CA0 < 0
                % which makes dX/dlambda negative, meaning X increases
                % as we go from large lambda to 0
                dXdlambda = rA / CA0 + (E_val / denominator) * X ;
            end
        end

        %% ============== FIRST-ORDER KINETICS ==============

        function obj = compute_firstOrder(obj, k)
            % Compute exit conversion for first-order irreversible reaction
            %   -rA = k*CA, so rA/CA0 = -k*(1-X)
            %
            % ODE: dX/d(lambda) = -k*(1-X) + E(lambda)/(1-F(lambda)) * X
            %
            % Input:
            %   k - rate constant (1/s)
            %
            % [HYSYS] k podria obtenerse de Arrhenius k=k0*exp(-Ea/RT)
            %         con T de Hysys via Stream.defineStreamFromHysys().

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            E_interp = griddedInterpolant(t_rtd, Et, 'pchip', 'nearest') ;
            F_interp = griddedInterpolant(t_rtd, Ft, 'pchip', 'nearest') ;

            Ft = obj.rtd.Ft ;
            valid_idx = find((1 - Ft) > 1e-6, 1, 'last') ;
            if isempty(valid_idx)
                lambda_max = max(t_rtd) * 0.95 ;
            else
                lambda_max = t_rtd(valid_idx) ;
            end

            options = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;

            [lambda_sol, X_sol] = ode45(@ode_mm_1st, ...
                                        [lambda_max, 0], 0, options) ;

            obj.lambda_profile = flip(lambda_sol') ;
            obj.X_profile = flip(X_sol') ;
            obj.X_exit = X_sol(end) ;

            fprintf('Maximum Mixedness (1st order, k=%.3g): X_exit = %.4f\n', ...
                    k, obj.X_exit) ;

            function dXdlambda = ode_mm_1st(lambda, X)
                E_val = E_interp(lambda) ;
                F_val = F_interp(lambda) ;
                denom = max(1 - F_val, 1e-12) ;

                dXdlambda = -k * (1 - X) + (E_val / denom) * X ;
            end
        end

        %% ============== SECOND-ORDER KINETICS ==============

        function obj = compute_secondOrder(obj, k, CA0)
            % Compute exit conversion for second-order irreversible reaction
            %   -rA = k*CA^2, so rA/CA0 = -k*CA0*(1-X)^2
            %
            % ODE: dX/d(lambda) = -k*CA0*(1-X)^2 + E(lambda)/(1-F(lambda)) * X
            %
            % Inputs:
            %   k   - rate constant (m^3/(mol*s))
            %   CA0 - initial concentration (mol/m^3)
            %
            % [HYSYS] k podria obtenerse de Arrhenius k=k0*exp(-Ea/RT).
            %         CA0 podria venir de composicion de corriente Hysys.

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            E_interp = griddedInterpolant(t_rtd, Et, 'pchip', 'nearest') ;
            F_interp = griddedInterpolant(t_rtd, Ft, 'pchip', 'nearest') ;

            Ft = obj.rtd.Ft ;
            valid_idx = find((1 - Ft) > 1e-6, 1, 'last') ;
            if isempty(valid_idx)
                lambda_max = max(t_rtd) * 0.95 ;
            else
                lambda_max = t_rtd(valid_idx) ;
            end

            options = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;

            [lambda_sol, X_sol] = ode45(@ode_mm_2nd, ...
                                        [lambda_max, 0], 0, options) ;

            obj.lambda_profile = flip(lambda_sol') ;
            obj.X_profile = flip(X_sol') ;
            obj.X_exit = X_sol(end) ;

            fprintf('Maximum Mixedness (2nd order, k=%.3g, CA0=%.3g): X_exit = %.4f\n', ...
                    k, CA0, obj.X_exit) ;

            function dXdlambda = ode_mm_2nd(lambda, X)
                E_val = E_interp(lambda) ;
                F_val = F_interp(lambda) ;
                denom = max(1 - F_val, 1e-12) ;

                dXdlambda = -k * CA0 * (1 - X)^2 + (E_val / denom) * X ;
            end
        end

        %% ============== MICHAELIS-MENTEN KINETICS ==============

        function obj = compute_MichaelisMenten(obj, a, b, CA0)
            % compute_MichaelisMenten - Max mixedness for Michaelis-Menten kinetics
            %
            % Rate law: -rA = a * CA / (1 + b * CA)
            % where CA = CA0 * (1 - X)
            %
            % ODE: dX/dlambda = a*(1-X)/(1 + b*CA0*(1-X)) / CA0 * CA0
            %                 + E(lambda)/(1-F(lambda)) * X
            %    = a*(1-X)/(1 + b*CA0*(1-X)) + E(lambda)/(1-F(lambda)) * X
            %
            % [HYSYS] Parametros enzimaticos (a, b) podrian depender de T
            %         via propiedades termodinamicas de Hysys.

            t = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            % Valid lambda range: where (1-F) is significant
            valid = (1 - Ft) > 1e-6 ;
            lambda = t(valid) ;
            E_valid = Et(valid) ;
            F_valid = Ft(valid) ;

            E_interp = griddedInterpolant(lambda, E_valid, 'linear', 'nearest') ;
            F_interp = griddedInterpolant(lambda, F_valid, 'linear', 'nearest') ;

            lambda_max = lambda(end) ;

            ode_fun = @(lam, X) mm_ode(lam, X) ;
            opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;
            [lam_sol, X_sol] = ode45(ode_fun, [lambda_max, 0], 0, opts) ;

            obj.lambda_profile = flip(lam_sol)' ;
            obj.X_profile = flip(X_sol)' ;
            obj.X_exit = X_sol(end) ;

            function dXdl = mm_ode(lam, X)
                E_val = E_interp(lam) ;
                F_val = F_interp(lam) ;
                denom = max(1 - F_val, 1e-12) ;
                CA = CA0 * (1 - X) ;
                rA_over_CA0 = a * (1 - X) / (1 + b * CA) ;
                dXdl = -rA_over_CA0 + (E_val / denom) * X ;
            end
        end

        %% ============== REVERSIBLE 1ST ORDER KINETICS ==============

        function obj = compute_reversible(obj, k_fwd, k_rev, CA0)
            % compute_reversible - Max mixedness for reversible 1st order A <-> B
            %
            % -rA = k_fwd * CA - k_rev * CB = k_fwd*CA0*(1-X) - k_rev*CA0*X
            % rA/CA0 = -(k_fwd*(1-X) - k_rev*X)
            %
            % ODE: dX/dlambda = -(k_fwd*(1-X) - k_rev*X) + E/(1-F) * X
            %
            % [HYSYS] k_fwd y k_rev dependen de T via Arrhenius.
            %         T y CA0 podrian venir de corriente Hysys.

            t = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            valid = (1 - Ft) > 1e-6 ;
            lambda = t(valid) ;
            E_valid = Et(valid) ;
            F_valid = Ft(valid) ;

            E_interp = griddedInterpolant(lambda, E_valid, 'linear', 'nearest') ;
            F_interp = griddedInterpolant(lambda, F_valid, 'linear', 'nearest') ;

            lambda_max = lambda(end) ;

            opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;
            [lam_sol, X_sol] = ode45(@(lam, X) rev_ode(lam, X), [lambda_max, 0], 0, opts) ;

            obj.lambda_profile = flip(lam_sol)' ;
            obj.X_profile = flip(X_sol)' ;
            obj.X_exit = X_sol(end) ;

            function dXdl = rev_ode(lam, X)
                E_val = E_interp(lam) ;
                F_val = F_interp(lam) ;
                denom = max(1 - F_val, 1e-12) ;
                dXdl = -(k_fwd*(1-X) - k_rev*X) + (E_val / denom) * X ;
            end
        end

        %% ============== PARALLEL REACTIONS ==============

        function obj = compute_parallel(obj, k1, n1, k2, n2, CA0)
            % compute_parallel - Max mixedness for parallel reactions
            %
            % A -> B: -r1 = k1 * CA^n1
            % A -> C: -r2 = k2 * CA^n2
            % -rA = k1*CA^n1 + k2*CA^n2
            % rA/CA0 = -(k1*(CA0*(1-X))^n1 + k2*(CA0*(1-X))^n2) / CA0
            %
            % ODE: dX/dlambda = (k1*(CA0*(1-X))^n1 + k2*(CA0*(1-X))^n2)/CA0
            %                 + E/(1-F) * X
            %
            % [HYSYS] k1, k2 dependen de T via Arrhenius.
            %         CA0 podria venir de composicion de corriente Hysys.

            t = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            valid = (1 - Ft) > 1e-6 ;
            lambda = t(valid) ;
            E_valid = Et(valid) ;
            F_valid = Ft(valid) ;

            E_interp = griddedInterpolant(lambda, E_valid, 'linear', 'nearest') ;
            F_interp = griddedInterpolant(lambda, F_valid, 'linear', 'nearest') ;

            lambda_max = lambda(end) ;

            opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;
            [lam_sol, X_sol] = ode45(@(lam, X) par_ode(lam, X), [lambda_max, 0], 0, opts) ;

            obj.lambda_profile = flip(lam_sol)' ;
            obj.X_profile = flip(X_sol)' ;
            obj.X_exit = X_sol(end) ;

            function dXdl = par_ode(lam, X)
                E_val = E_interp(lam) ;
                F_val = F_interp(lam) ;
                denom = max(1 - F_val, 1e-12) ;
                CA = CA0 * max(1 - X, 0) ;
                rA_total = k1 * CA^n1 + k2 * CA^n2 ;
                dXdl = -rA_total / CA0 + (E_val / denom) * X ;
            end
        end

        %% ============== CUSTOM RATE LAW ==============

        function obj = compute_custom(obj, rate_func, CA0)
            % compute_custom - Max mixedness with user-defined rate law
            %
            % Inputs:
            %   rate_func - Function handle @(CA) returning -rA
            %   CA0       - Initial concentration [mol/m^3]
            %
            % [HYSYS] CA0 podria venir de composicion de corriente Hysys.
            %         rate_func podria incluir T de Hysys como parametro.
            %
            % ODE: dX/dlambda = rate_func(CA0*(1-X))/CA0 + E/(1-F) * X

            t = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            valid = (1 - Ft) > 1e-6 ;
            lambda = t(valid) ;
            E_valid = Et(valid) ;
            F_valid = Ft(valid) ;

            E_interp = griddedInterpolant(lambda, E_valid, 'linear', 'nearest') ;
            F_interp = griddedInterpolant(lambda, F_valid, 'linear', 'nearest') ;

            lambda_max = lambda(end) ;

            opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12) ;
            [lam_sol, X_sol] = ode45(@(lam, X) custom_ode(lam, X), [lambda_max, 0], 0, opts) ;

            obj.lambda_profile = flip(lam_sol)' ;
            obj.X_profile = flip(X_sol)' ;
            obj.X_exit = X_sol(end) ;

            function dXdl = custom_ode(lam, X)
                E_val = E_interp(lam) ;
                F_val = F_interp(lam) ;
                denom = max(1 - F_val, 1e-12) ;
                CA = CA0 * max(1 - X, 0) ;
                dXdl = rate_func(CA) / CA0 + (E_val / denom) * X ;
            end
        end

        %% ============== PLOT ON AXES (for App integration) ==============

        function plot_on_axes(obj, ax_Xlambda)
            % Plot max mixedness results on provided uiaxes
            %   ax_Xlambda - axes for X(lambda) profile plot
            %
            % Used by NonIdealReactorApp to embed plots in the GUI.

            if isempty(obj.X_profile) || isempty(obj.X_exit)
                return
            end

            cla(ax_Xlambda) ;
            plot(ax_Xlambda, obj.lambda_profile, obj.X_profile, 'm-', 'LineWidth', 1.5) ;
            hold(ax_Xlambda, 'on') ;
            plot(ax_Xlambda, 0, obj.X_exit, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r') ;
            hold(ax_Xlambda, 'off') ;
            xlabel(ax_Xlambda, 'lambda (life expectancy)') ;
            ylabel(ax_Xlambda, 'X(lambda)') ;
            title(ax_Xlambda, sprintf('Max Mixedness | X_{exit} = %.4f', obj.X_exit)) ;
            grid(ax_Xlambda, 'on') ;
            ylim(ax_Xlambda, [0 1]) ;
            legend(ax_Xlambda, 'X(lambda)', sprintf('X_{exit} = %.4f', obj.X_exit), ...
                   'Location', 'best') ;
        end

        %% ============== PLOTTING ==============

        function fig = plot_results(obj)
            % Plot the maximum mixedness results:
            %   X(lambda) profile showing how conversion builds up
            %   from lambda_max to lambda=0

            if isempty(obj.X_profile) || isempty(obj.X_exit)
                error('Must run compute() or compute_firstOrder() first') ;
            end

            fig = figure('Name', 'Maximum Mixedness Model Results', 'NumberTitle', 'off') ;

            % Main plot: X vs lambda
            ax1 = subplot(1, 2, 1) ;
            plot(ax1, obj.lambda_profile, obj.X_profile, 'm-', 'LineWidth', 1.5) ;
            xlabel(ax1, '\lambda (life expectancy, s)') ;
            ylabel(ax1, 'X(\lambda)') ;
            title(ax1, sprintf('X(\\lambda)  |  X_{exit} = %.4f', obj.X_exit)) ;
            grid(ax1, 'on') ;
            ylim(ax1, [0 1]) ;
            % Mark exit conversion
            hold(ax1, 'on') ;
            plot(ax1, 0, obj.X_exit, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r') ;
            legend(ax1, 'X(\lambda)', sprintf('X_{exit} = %.4f', obj.X_exit), ...
                   'Location', 'best') ;
            hold(ax1, 'off') ;

            % RTD subplot
            ax2 = subplot(1, 2, 2) ;
            plot(ax2, obj.rtd.t, obj.rtd.Et, 'b-', 'LineWidth', 1.5) ;
            xlabel(ax2, 't (s)') ;
            ylabel(ax2, 'E(t) (1/s)') ;
            title(ax2, 'RTD - E(t)') ;
            grid(ax2, 'on') ;

            sgtitle(fig, 'Maximum Mixedness Model (Earliest Mixing)') ;
        end

    end
end
