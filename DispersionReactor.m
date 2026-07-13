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
%   - sweep_Pe_general()
%   - sweep_Bo_general() as a compatibility wrapper
% =========================================================================
% Javier Berenguer Sabater
% Created: March 25, 2026. Last update: July 10, 2026
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
            % tau is interpreted as the mean residence time used by the UI.

            switch obj.boundaryType
                case 'open-open'
                    tauSpace = tau / (1 + 2 * obj.Bo) ;
                    rtd_obj = RTD.dispersion_open(obj.Bo, tauSpace) ;
                case 'closed-closed'
                    rtd_obj = RTD.dispersion_closed(obj.Bo, tau) ;
                otherwise
                    error('Unknown boundary condition type: %s', obj.boundaryType) ;
            end

            obj.rtd = rtd_obj ;
        end

        function [X, C_out] = compute_conversion_general(obj, RS, C0, tau)
            % Backward-compatible wrapper for the reactive dispersion route.
            %
            % closed-closed:
            %   solves the steady axial-dispersion BVP with Danckwerts BCs.
            %
            % open-open:
            %   exact only for linear first-order kinetics.

            switch obj.boundaryType
                case 'closed-closed'
                    [X, C_out] = obj.compute_conversion_closedClosed_BVP(RS, C0, tau) ;

                case 'open-open'
                    if ~DispersionReactor.is_supported_open_open_first_order(RS)
                        error(['Open-open reactive prediction is only exact for linear first-order kinetics. ' ...
                               'For general kinetics use closed-closed boundary conditions.']) ;
                    end
                    [X, C_out] = obj.compute_conversion_openOpen_firstOrder(RS, C0, tau) ;

                otherwise
                    error('Unknown boundary condition type: %s', obj.boundaryType) ;
            end
        end

        function [X, C_out] = compute_conversion_closedClosed_BVP(obj, RS, C0, tau)
            Pe = 1 / max(obj.Bo, 1e-12) ;

            if Pe > 1e4
                [C_out, X] = TanksInSeries.solve_PFR(RS, C0, tau) ;
                return
            end

            if Pe < 1e-4
                [C_out, X] = TanksInSeries.solve_sequential(1, RS, C0, tau) ;
                return
            end

            stoich = RS.stochiometricMatrix ;
            nComp = numel(C0) ;
            T = 298.15 ;
            lambdaMesh = linspace(0, 1, 80) ;
            [CguessOut, ~] = TanksInSeries.solve_PFR(RS, C0, tau) ;
            guessSlope = CguessOut(:) - C0(:) ;
            guessFun = @(lambda) [C0(:) + lambda * guessSlope; guessSlope] ;
            solinit = bvpinit(lambdaMesh, guessFun) ;
            odeFun = @(lambda, y) obj.axial_dispersion_ode(lambda, y, RS, tau, Pe, stoich, T, nComp) ;
            bcFun = @(ya, yb) obj.axial_dispersion_bc(ya, yb, C0, Pe, nComp) ;
            opts = bvpset('RelTol', 1e-6, 'AbsTol', 1e-8, 'NMax', 5000) ;

            try
                sol = bvp4c(odeFun, bcFun, solinit, opts) ;
            catch
                sol = bvp5c(odeFun, bcFun, solinit, opts) ;
            end

            yL = deval(sol, 1) ;
            C_out = max(yL(1:nComp).', 0) ;
            X = DispersionReactor.component_conversion(C0, C_out, 1) ;
        end

        function [X, C_out] = compute_conversion_openOpen_firstOrder(obj, RS, C0, tau)
            [X, C_out] = obj.compute_conversion_from_rtd_batch(RS, C0, tau) ;
        end

        function [Pe_vec, X_vec, C_out_mat] = sweep_Pe_general(obj, RS, C0, tau, n_points)
            % Parametric sweep of conversion vs Pe.

            if nargin < 5
                n_points = 50 ;
            end

            Pe_vec = logspace(-1, 3, n_points) ;
            X_vec = zeros(size(Pe_vec)) ;
            if nargout >= 3
                C_out_mat = zeros(numel(Pe_vec), numel(C0)) ;
            end

            saved_Bo = obj.Bo ;

            for i = 1:n_points
                obj.Bo = 1 / Pe_vec(i) ;
                if nargout >= 3
                    [X_vec(i), C_out_mat(i, :)] = obj.compute_conversion_general(RS, C0, tau) ;
                else
                    X_vec(i) = obj.compute_conversion_general(RS, C0, tau) ;
                end
            end

            obj.Bo = saved_Bo ;
        end

        function [Bo_vec, X_vec, C_out_mat] = sweep_Bo_general(obj, RS, C0, tau, n_points)
            % Compatibility wrapper that preserves the historical Bo sweep API.

            if nargout >= 3
                [Pe_vec, X_vec, C_out_mat] = obj.sweep_Pe_general(RS, C0, tau, n_points) ;
            else
                [Pe_vec, X_vec] = obj.sweep_Pe_general(RS, C0, tau, n_points) ;
            end

            Bo_vec = 1 ./ Pe_vec ;
            [Bo_vec, order] = sort(Bo_vec) ;
            X_vec = X_vec(order) ;
            if nargout >= 3
                C_out_mat = C_out_mat(order, :) ;
            end
        end

    end

    methods (Static)

        function tf = supports_open_open_first_order(RS)
            tf = DispersionReactor.is_supported_open_open_first_order(RS) ;
        end

    end

    methods (Access = private)

        function [X, C_out] = compute_conversion_from_rtd_batch(obj, RS, C0, tau)
            rtd_obj = obj.generate_RTD(tau) ;
            t_rtd = rtd_obj.t ;
            Et = rtd_obj.Et ;
            stoich = RS.stochiometricMatrix ;
            nComp = numel(C0) ;
            T = 298.15 ;
            odeOpts = odeset('NonNegative', 1:nComp, 'RelTol', 1e-8) ;
            [t_ode, C_ode] = ode45(@(~, C) batch_ode(C), [0, max(t_rtd)], C0(:), odeOpts) ;

            if C0(1) > 0
                X_vs_t = (C0(1) - C_ode(:, 1)) / C0(1) ;
                X_batch = interp1(t_ode, X_vs_t, t_rtd, 'pchip', 0) ;
                X = trapz(t_rtd, X_batch(:)' .* Et) ;
            else
                X = 0 ;
            end
            X = max(0, min(1, X)) ;

            C_interp = interp1(t_ode, C_ode, t_rtd, 'pchip') ;
            if isvector(C_interp)
                C_interp = C_interp(:) ;
            end
            C_out = zeros(1, nComp) ;
            for j = 1:nComp
                C_out(j) = trapz(t_rtd, C_interp(:, j)' .* Et) ;
            end

            function dCdt = batch_ode(C)
                RS_temp = RS.computeRate(C(:)', T) ;
                r = RS_temp.r_i ;
                dCdt = (r * stoich)' ;
            end
        end

        function dydlambda = axial_dispersion_ode(~, ~, y, RS, tau, Pe, stoich, T, nComp)
            nCols = size(y, 2) ;
            dydlambda = zeros(2 * nComp, nCols) ;

            for col = 1:nCols
                C = max(y(1:nComp, col), 0) ;
                G = y(nComp+1:2*nComp, col) ;
                RS_temp = RS.computeRate(C(:)', T) ;
                r = RS_temp.r_i ;
                netRate = (r * stoich).' ;
                dydlambda(:, col) = [G; Pe * (G - tau * netRate)] ;
            end
        end

        function res = axial_dispersion_bc(~, ya, yb, Cfeed, Pe, nComp)
            Ca = ya(1:nComp) ;
            Ga = ya(nComp+1:2*nComp) ;
            Gb = yb(nComp+1:2*nComp) ;
            inletBC = Ca - (1 / Pe) * Ga - Cfeed(:) ;
            outletBC = Gb ;
            res = [inletBC; outletBC] ;
        end

    end

    methods (Static, Access = private)

        function tf = is_supported_open_open_first_order(RS)
            tol = 1e-12 ;

            if isempty(RS)
                tf = false ;
                return
            end

            if ~isempty(RS.k0_denominator) && any(abs(RS.k0_denominator(:)) > tol)
                tf = false ;
                return
            end

            denomOrders = RS.partialOrders_denominator ;
            if ~isempty(denomOrders) && any(abs(denomOrders(:)) > tol)
                tf = false ;
                return
            end

            if isempty(RS.userDefinedKinetics)
                tf = DispersionReactor.is_structural_first_order_kinetics(RS, tol) ;
                return
            end

            tf = DispersionReactor.is_linear_first_order_user_kinetics(RS) ;
        end

        function tf = is_structural_first_order_kinetics(RS, tol)
            partials = RS.partialOrders ;
            tf = true ;
            for i = 1:size(partials, 1)
                row = partials(i, :) ;
                if abs(sum(row) - 1) > tol
                    tf = false ;
                    return
                end
                if sum(abs(row - 1) < tol) ~= 1
                    tf = false ;
                    return
                end
                mask = abs(row) > tol & abs(row - 1) > tol ;
                if any(mask)
                    tf = false ;
                    return
                end
            end
        end

        function tf = is_linear_first_order_user_kinetics(RS)
            tol = 1e-9 ;
            T = 298.15 ;
            nComp = max(RS.nComponents, 1) ;

            c0 = zeros(1, nComp) ;
            c1 = linspace(1, nComp, nComp) ;
            c2 = linspace(0.5, 0.5 * nComp, nComp) ;
            alpha = 1.7 ;

            try
                r0 = DispersionReactor.evaluate_rate_vector(RS, c0, T) ;
                r1 = DispersionReactor.evaluate_rate_vector(RS, c1, T) ;
                r2 = DispersionReactor.evaluate_rate_vector(RS, c2, T) ;
                r12 = DispersionReactor.evaluate_rate_vector(RS, c1 + c2, T) ;
                rAlpha = DispersionReactor.evaluate_rate_vector(RS, alpha * c1, T) ;
            catch
                tf = false ;
                return
            end

            if any(~isfinite([r0(:); r1(:); r2(:); r12(:); rAlpha(:)]))
                tf = false ;
                return
            end

            scale = max([1; abs(r0(:)); abs(r1(:)); abs(r2(:)); abs(r12(:)); abs(rAlpha(:))]) ;
            absTol = tol * scale ;

            tf = norm(r0, inf) <= absTol && ...
                 norm(r12 - (r1 + r2), inf) <= absTol && ...
                 norm(rAlpha - alpha * r1, inf) <= absTol ;
        end

        function rates = evaluate_rate_vector(RS, concentration, T)
            RS_temp = RS.computeRate(concentration, T) ;
            rates = RS_temp.r_i(:) ;
        end

        function X = component_conversion(C0, C_out, idx)
            if idx > numel(C0) || C0(idx) <= 0
                X = 0 ;
                return
            end
            X = 1 - C_out(idx) / C0(idx) ;
            X = max(0, min(1, X)) ;
        end

    end
end
