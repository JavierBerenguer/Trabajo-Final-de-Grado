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
% Created: March 21, 2026. Last update: March 21, 2026
% =========================================================================

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
                error('MaxMixednessModel requires rtd, reactionSys, and feed to be set') ;
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
            lambda_max = max(t_rtd) * 0.999 ;  % avoid exact endpoint

            % ODE: dX/d(lambda) = rA(X)/CA0 + E(lambda)/(1-F(lambda)) * X
            % Integrate from lambda_max to 0 (backwards)
            % Use negative span to integrate backwards
            options = odeset('RelTol', 1e-8, 'AbsTol', 1e-10, ...
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

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            E_interp = griddedInterpolant(t_rtd, Et, 'pchip', 'nearest') ;
            F_interp = griddedInterpolant(t_rtd, Ft, 'pchip', 'nearest') ;

            lambda_max = max(t_rtd) * 0.999 ;

            options = odeset('RelTol', 1e-8, 'AbsTol', 1e-10) ;

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

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            Ft = obj.rtd.Ft ;

            E_interp = griddedInterpolant(t_rtd, Et, 'pchip', 'nearest') ;
            F_interp = griddedInterpolant(t_rtd, Ft, 'pchip', 'nearest') ;

            lambda_max = max(t_rtd) * 0.999 ;

            options = odeset('RelTol', 1e-8, 'AbsTol', 1e-10) ;

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
