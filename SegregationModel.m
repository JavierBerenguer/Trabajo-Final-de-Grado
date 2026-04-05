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
        X_mean              % Mean conversion (result)
        X_batch             % [1 x N] Batch conversion profile X(t)
        integrand           % [1 x N] X(t)*E(t) - the integrand
        C_batch             % [N x nComp] Concentration profiles from batch
        selectivity_B    % Overall selectivity S_B = CB/(CB+CC) for parallel reactions
        yield_B          % Overall yield Y_B = CB/(CA0-CA) for parallel reactions
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
                error('SegregationModel requires rtd, reactionSys and feed to be set') ;
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

        %% ============== GENERAL ISOTHERMAL (from ReactionSys) ==============

        function obj = compute_isothermal(obj, RS, C0)
            % Compute mean conversion using a general ReactionSys object
            % under isothermal conditions.
            %
            %   X_bar = integral( X_batch(t) * E(t) dt )
            %
            % The batch ODE is:  dC/dt = r(C) * stoich
            % No energy or pressure balance — pure isothermal.
            %
            % Inputs (set via properties or arguments):
            %   RS  - ReactionSys object (any kinetics)
            %   C0  - Initial concentration vector [1 x nComponents]
            %
            % The key component for conversion is obj.keyComponentIndex (default: 1).

            if isempty(obj.rtd)
                error('RTD must be set before computing') ;
            end

            t_rtd = obj.rtd.t ;
            Et = obj.rtd.Et ;
            stoich = RS.stochiometricMatrix ;
            nComp = length(C0) ;
            T = 298.15 ;  % isothermal — Ea=0 so T value is irrelevant
            idx_key = obj.keyComponentIndex ;

            % Solve batch ODE
            odeOpts = odeset('NonNegative', 1:nComp, 'RelTol', 1e-8) ;
            [t_ode, C_ode] = ode45(@(t, C) batch_ode(C), ...
                [0, max(t_rtd)], C0(:), odeOpts) ;

            % Conversion of key component
            C_key_vs_t = C_ode(:, idx_key) ;
            X_vs_t = (C0(idx_key) - C_key_vs_t) / C0(idx_key) ;

            % Interpolate at RTD time points (ensure row vector like Et)
            obj.X_batch = interp1(t_ode, X_vs_t, t_rtd, 'pchip', 0) ;
            obj.X_batch = obj.X_batch(:)' ;  % force row [1 x N]

            % Store concentration profiles
            obj.C_batch = interp1(t_ode, C_ode, t_rtd, 'pchip') ;

            % Integrate
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_rtd, obj.integrand) ;

            % Selectivity and yield for multi-component systems
            if nComp >= 3
                CB_t = obj.C_batch(:, 2)' ;
                CC_t = obj.C_batch(:, 3)' ;
                CB_mean = trapz(t_rtd, CB_t .* Et) ;
                CC_mean = trapz(t_rtd, CC_t .* Et) ;
                if (CB_mean + CC_mean) > 0
                    obj.selectivity_B = CB_mean / (CB_mean + CC_mean) ;
                end
                CA_mean = trapz(t_rtd, obj.C_batch(:, 1)' .* Et) ;
                if (C0(1) - CA_mean) > 0
                    obj.yield_B = CB_mean / (C0(1) - CA_mean) ;
                end
            end

            function dCdt = batch_ode(C)
                RS_temp = RS.computeRate(C(:)', T) ;
                r = RS_temp.r_i ;
                dCdt = (r * stoich)' ;
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
            %
            % [HYSYS] k podria obtenerse de Arrhenius k=k0*exp(-Ea/RT)
            %         con T de Hysys via Stream.defineStreamFromHysys().

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
            %
            % [HYSYS] k podria obtenerse de Arrhenius k=k0*exp(-Ea/RT).
            %         CA0 podria venir de composicion de corriente Hysys.

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

        %% ============== MICHAELIS-MENTEN KINETICS ==============

        function obj = compute_MichaelisMenten(obj, a, b, CA0)
            % compute_MichaelisMenten - Segregation model for Michaelis-Menten kinetics
            %
            % Rate law: -rA = a * CA / (1 + b * CA)
            %
            % Inputs:
            %   a   - Maximum rate parameter [1/s]
            %   b   - Saturation parameter [m^3/mol]
            %   CA0 - Initial concentration [mol/m^3]
            %
            % [HYSYS] Parametros enzimaticos (a, b) podrian depender de T
            %         via propiedades termodinamicas de Hysys.

            t_span = obj.rtd.t ;
            Et = obj.rtd.Et ;

            % Solve batch ODE: dCA/dt = -a*CA/(1+b*CA)
            [~, CA_sol] = ode45(@(t, CA) -a*CA/(1+b*CA), t_span, CA0) ;

            obj.X_batch = 1 - CA_sol(:)' / CA0 ;
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_span, obj.integrand) ;
        end

        %% ============== REVERSIBLE FIRST-ORDER ==============

        function obj = compute_reversible(obj, k_fwd, k_rev, CA0)
            % compute_reversible - Segregation model for reversible 1st order
            %
            % Reaction: A <-> B
            % Rate law: -rA = k_fwd * CA - k_rev * CB
            %         = k_fwd * CA - k_rev * (CA0 - CA)
            %
            % Inputs:
            %   k_fwd - Forward rate constant [1/s]
            %   k_rev - Reverse rate constant [1/s]
            %   CA0   - Initial concentration of A [mol/m^3]
            %
            % [HYSYS] k_fwd y k_rev dependen de T via Arrhenius.
            %         T y CA0 podrian venir de corriente Hysys.
            %
            % Analytical solution:
            %   CA(t) = CA0 * (k_rev + k_fwd * exp(-(k_fwd+k_rev)*t)) / (k_fwd + k_rev)

            t_span = obj.rtd.t ;
            Et = obj.rtd.Et ;

            % Analytical batch solution
            K = k_fwd + k_rev ;
            CA_t = CA0 * (k_rev + k_fwd * exp(-K * t_span)) / K ;

            obj.X_batch = 1 - CA_t / CA0 ;
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_span, obj.integrand) ;
        end

        %% ============== PARALLEL REACTIONS ==============

        function obj = compute_parallel(obj, k1, n1, k2, n2, CA0)
            % compute_parallel - Segregation model for parallel reactions
            %
            % Reactions: A -> B  with -r1 = k1 * CA^n1
            %            A -> C  with -r2 = k2 * CA^n2
            % Overall:   dCA/dt = -(k1*CA^n1 + k2*CA^n2)
            %
            % Inputs:
            %   k1, k2 - Rate constants [units depend on order]
            %   n1, n2 - Reaction orders (dimensionless)
            %   CA0    - Initial concentration [mol/m^3]
            %
            % [HYSYS] k1, k2 dependen de T via Arrhenius.
            %         CA0 podria venir de composicion de corriente Hysys.
            %
            % Additional outputs stored:
            %   obj.CB_batch, obj.CC_batch - Product concentration profiles
            %   obj.selectivity_B - Instantaneous selectivity S_B = r1/(r1+r2)

            t_span = obj.rtd.t ;
            Et = obj.rtd.Et ;

            % Solve batch ODE system: [CA, CB, CC]
            % dCA/dt = -(k1*CA^n1 + k2*CA^n2)
            % dCB/dt = k1*CA^n1
            % dCC/dt = k2*CA^n2
            y0 = [CA0 ; 0 ; 0] ;
            [~, Y] = ode45(@(t, y) [...
                -(k1*max(y(1),0)^n1 + k2*max(y(1),0)^n2) ; ...
                k1*max(y(1),0)^n1 ; ...
                k2*max(y(1),0)^n2], t_span, y0) ;

            CA_sol = Y(:,1)' ;
            CB_sol = Y(:,2)' ;
            CC_sol = Y(:,3)' ;

            obj.X_batch = 1 - CA_sol / CA0 ;
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_span, obj.integrand) ;

            % Store product profiles and selectivity for later use
            obj.C_batch = [CA_sol ; CB_sol ; CC_sol]' ;

            % Mean product concentrations via segregation integral
            CB_mean = trapz(t_span, CB_sol .* Et) ;
            CC_mean = trapz(t_span, CC_sol .* Et) ;

            % Overall selectivity: S_B = CB / (CB + CC)
            if (CB_mean + CC_mean) > 0
                obj.selectivity_B = CB_mean / (CB_mean + CC_mean) ;
            else
                obj.selectivity_B = NaN ;
            end
            % Yield: Y_B = CB / CA0_consumed
            CA_mean = trapz(t_span, CA_sol .* Et) ;
            if (CA0 - CA_mean) > 0
                obj.yield_B = CB_mean / (CA0 - CA_mean) ;
            else
                obj.yield_B = NaN ;
            end
        end

        %% ============== CUSTOM RATE LAW ==============

        function obj = compute_custom(obj, rate_func, CA0)
            % compute_custom - Segregation model with user-defined rate law
            %
            % Inputs:
            %   rate_func - Function handle @(CA) returning -rA value
            %               Example: @(CA) 0.5*CA/(1+0.5*CA)
            %   CA0       - Initial concentration [mol/m^3]

            t_span = obj.rtd.t ;
            Et = obj.rtd.Et ;

            % Solve batch ODE: dCA/dt = -rate_func(CA)
            [~, CA_sol] = ode45(@(t, CA) -rate_func(max(CA, 0)), t_span, CA0) ;

            obj.X_batch = 1 - CA_sol(:)' / CA0 ;
            obj.integrand = obj.X_batch .* Et ;
            obj.X_mean = trapz(t_span, obj.integrand) ;
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
            title(ax_Xbatch, 'Intrinsic Conversion X(t)') ;
            grid(ax_Xbatch, 'on') ;
            ylim(ax_Xbatch, [0 1]) ;

            % Integrand X(t)*E(t)
            cla(ax_integrand) ;
            area(ax_integrand, obj.rtd.t, obj.integrand, ...
                'FaceColor', [0.3 0.6 0.9], 'FaceAlpha', 0.5, 'EdgeColor', 'b') ;
            xlabel(ax_integrand, 't') ;
            ylabel(ax_integrand, 'X(t) * E(t)') ;
            title(ax_integrand, sprintf('Segregation Integrand | X_{seg} = %.4f', obj.X_mean)) ;
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
