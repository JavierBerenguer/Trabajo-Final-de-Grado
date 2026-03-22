classdef SegregationModel
% This class implements the Segregation Model (complete segregation / macrofluid)
% for predicting conversion in non-ideal reactors.
%
% The segregation model treats the fluid as a collection of small batch
% reactors (aggregates) that do not exchange material. Each aggregate
% reacts independently for a time equal to its residence time.
%
% Mean conversion:  X_bar = integral( X_batch(t) * E(t) dt )
%
% This model gives the UPPER BOUND of conversion for reaction orders > 1
% and the LOWER BOUND for reaction orders < 1.
% For first-order reactions, it gives the exact conversion regardless of
% mixing state.
%
% Features:
%   - Compute mean conversion from RTD and batch kinetics
%   - Works with any kinetics (uses ReactionSys and Batch reactor)
%   - Supports analytical X(t) for simple kinetics
%   - Plots X_batch(t), E(t), and the integrand X(t)*E(t)
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
        X_mean              % Mean conversion (result)
        X_batch             % [1 x N] Batch conversion profile X(t)
        integrand           % [1 x N] X(t)*E(t) - the integrand
        C_batch             % [N x nComp] Concentration profiles from batch
    end

    methods

        %% ============== CONSTRUCTOR ==============

        function obj = SegregationModel(rtd_obj, RS, Feed, V)
            % SegregationModel Constructor
            %   obj = SegregationModel(rtd_obj, RS, Feed, V)
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

        %% ============== COMPUTE CONVERSION ==============

        function obj = compute(obj)
            % Compute the mean conversion using the segregation model
            %   X_bar = integral( X_batch(t) * E(t) dt )
            %
            % Solves the batch reactor ODE for each time point in the RTD
            % and then integrates the product X(t)*E(t).

            if isempty(obj.rtd) || isempty(obj.reactionSys) || isempty(obj.feed)
                error('SegregationModel requires rtd, reactionSys, and feed to be set') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            RS = obj.reactionSys ;

            % Solve the batch reactor ODE over the full time span
            % Initial conditions: feed concentrations
            moles_0 = obj.feed.molarFlow ;
            T0 = obj.feed.T ;
            P0 = obj.feed.P ;

            % Batch ODE: same as Batch.m but we only need concentration evolution
            IC = [moles_0, T0, P0] ;
            tmax = max(t_rtd) ;

            [t_ode, y_ode] = ode45(@ode_batch, [0, tmax], IC) ;

            % Extract molar amounts along time
            moles_vs_t = y_ode(:, 1:RS.nComponents) ;

            % Compute conversion of key component
            n0_key = moles_0(obj.keyComponentIndex) ;
            n_key_vs_t = moles_vs_t(:, obj.keyComponentIndex) ;
            X_vs_t = (n0_key - n_key_vs_t) / n0_key ;

            % Interpolate X(t) at RTD time points
            obj.X_batch = interp1(t_ode, X_vs_t, t_rtd, 'pchip', 0) ;

            % Store concentration profiles interpolated at RTD times
            obj.C_batch = interp1(t_ode, moles_vs_t / obj.V, t_rtd, 'pchip') ;

            % Compute integrand and integrate
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_rtd, obj.integrand) ;

            fprintf('Segregation Model: X_mean = %.4f\n', obj.X_mean) ;

            %% Batch ODE system (nested function)
            function dydt = ode_batch(~, y)
                moles = y(1:RS.nComponents)' ;
                T = y(RS.nComponents + 1) ;
                P = y(RS.nComponents + 2) ;

                % Concentrations
                concentration = moles / obj.V ;

                % Rate of reaction
                RS = RS.computeRate(concentration, T) ;
                constant_WtoV = 1 ;  % no catalyst by default
                r_i = constant_WtoV * RS.r_i ;

                % Mass balance: dN/dt = V * sum(r_i * nu_ij)
                dndt = obj.V * r_i * RS.stochiometricMatrix ;

                % Energy balance: isothermal approximation
                % (for full energy balance, extend as needed)
                componentCp = RS.compute_HeatCapacity(T, P) ;
                DH = RS.DHref + componentCp * RS.stochiometricMatrix' * (T - RS.Tref) ;

                if isempty(obj.feed.phase) || obj.feed.phase == 'L'
                    phase = 'L' ;
                else
                    phase = obj.feed.phase ;
                end

                dTdt = -(obj.V * r_i * DH') / (componentCp * moles') ;

                if phase == 'L'
                    dPdt = 0 ;
                else
                    Rg = 8.314 ;
                    dPdt = (Rg / obj.V) * (T * sum(dndt) + sum(moles) * dTdt) ;
                end

                dydt = [dndt' ; dTdt ; dPdt] ;
            end
        end

        %% ============== ANALYTICAL FIRST-ORDER ==============

        function obj = compute_firstOrder(obj, k)
            % Compute conversion for a first-order irreversible reaction
            % using the analytical formula:
            %   X_bar = 1 - integral( exp(-k*t) * E(t) dt )
            %
            % This is exact for first-order reactions regardless of mixing.
            %
            % Input:
            %   k - rate constant (1/s)

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;

            obj.X_batch = 1 - exp(-k * t_rtd) ;
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_rtd, obj.integrand) ;

            fprintf('Segregation Model (1st order, k=%.3g): X_mean = %.4f\n', ...
                    k, obj.X_mean) ;
        end

        %% ============== ANALYTICAL SECOND-ORDER ==============

        function obj = compute_secondOrder(obj, k, CA0)
            % Compute conversion for a second-order irreversible reaction
            %   A -> Products, -rA = k*CA^2
            %   X_batch(t) = k*CA0*t / (1 + k*CA0*t)
            %   X_bar = integral( X_batch(t) * E(t) dt )
            %
            % Inputs:
            %   k   - rate constant (m^3/(mol*s))
            %   CA0 - initial concentration of A (mol/m^3)

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;

            obj.X_batch = (k * CA0 * t_rtd) ./ (1 + k * CA0 * t_rtd) ;
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_rtd, obj.integrand) ;

            fprintf('Segregation Model (2nd order, k=%.3g, CA0=%.3g): X_mean = %.4f\n', ...
                    k, CA0, obj.X_mean) ;
        end

        %% ============== PLOT ON AXES (for App integration) ==============

        function plot_on_axes(obj, ax_Xbatch, ax_integrand)
            % Plot segregation model results on provided uiaxes
            %   ax_Xbatch    - axes for X_batch(t) plot
            %   ax_integrand - axes for X(t)*E(t) integrand plot
            %
            % Used by NonIdealReactorApp to embed plots in the GUI.

            if isempty(obj.X_batch) || isempty(obj.X_mean)
                return
            end

            % X_batch(t)
            cla(ax_Xbatch) ;
            plot(ax_Xbatch, obj.rtd.t, obj.X_batch, 'b-', 'LineWidth', 1.5) ;
            xlabel(ax_Xbatch, 't') ;
            ylabel(ax_Xbatch, 'X_{batch}(t)') ;
            title(ax_Xbatch, 'Segregation: Batch Conversion') ;
            grid(ax_Xbatch, 'on') ;
            ylim(ax_Xbatch, [0 1]) ;

            % Integrand X(t)*E(t)
            cla(ax_integrand) ;
            area(ax_integrand, obj.rtd.t, obj.integrand, ...
                'FaceColor', [0.3 0.6 0.9], 'FaceAlpha', 0.5, 'EdgeColor', 'b') ;
            xlabel(ax_integrand, 't') ;
            ylabel(ax_integrand, 'X(t) * E(t)') ;
            title(ax_integrand, sprintf('Integrand | X_{mean} = %.4f', obj.X_mean)) ;
            grid(ax_integrand, 'on') ;
        end

        %% ============== PLOTTING ==============

        function fig = plot_results(obj)
            % Plot the segregation model results:
            %   Subplot 1: X_batch(t) vs t
            %   Subplot 2: E(t) vs t
            %   Subplot 3: Integrand X(t)*E(t) vs t (shaded area = X_mean)

            if isempty(obj.X_batch) || isempty(obj.X_mean)
                error('Must run compute() or compute_firstOrder() first') ;
            end

            fig = figure('Name', 'Segregation Model Results', 'NumberTitle', 'off') ;

            % Subplot 1: Batch conversion
            ax1 = subplot(1, 3, 1) ;
            plot(ax1, obj.rtd.t, obj.X_batch, 'b-', 'LineWidth', 1.5) ;
            xlabel(ax1, 't (s)') ;
            ylabel(ax1, 'X_{batch}(t)') ;
            title(ax1, 'Batch Conversion') ;
            grid(ax1, 'on') ;
            ylim(ax1, [0 1]) ;

            % Subplot 2: RTD
            ax2 = subplot(1, 3, 2) ;
            plot(ax2, obj.rtd.t, obj.rtd.Et, 'r-', 'LineWidth', 1.5) ;
            xlabel(ax2, 't (s)') ;
            ylabel(ax2, 'E(t) (1/s)') ;
            title(ax2, 'RTD - E(t)') ;
            grid(ax2, 'on') ;

            % Subplot 3: Integrand
            ax3 = subplot(1, 3, 3) ;
            area(ax3, obj.rtd.t, obj.integrand, ...
                'FaceColor', [0.3 0.6 0.9], 'FaceAlpha', 0.5, 'EdgeColor', 'b') ;
            xlabel(ax3, 't (s)') ;
            ylabel(ax3, 'X(t) \cdot E(t)') ;
            title(ax3, sprintf('Integrand  |  X_mean = %.4f', obj.X_mean)) ;
            grid(ax3, 'on') ;

            sgtitle(fig, 'Segregation Model (Complete Segregation)') ;
        end

    end
end
