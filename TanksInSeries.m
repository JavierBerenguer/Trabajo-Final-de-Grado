classdef TanksInSeries < Reactor
% This subclass models a non-ideal reactor using the Tanks-in-Series model.
% Features:
%   - Models non-ideal behaviour as N equal-sized CSTRs in series
%   - Computes RTD analytically: E(t) = t^(N-1) / ((N-1)! * tau_i^N) * exp(-t/tau_i)
%   - For first-order reactions: X = 1 - 1/(1 + tau_i*k)^N
%   - For any order: solves N sequential CSTR balances
%   - Can determine N from experimental RTD variance: N = (tm/sigma)^2
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: March 21, 2026
% =========================================================================

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

        %% ============== DETERMINE N FROM EXPERIMENTAL RTD ==============

        function R = compute_nTanks_from_RTD(R, rtd_obj)
            % Determine the number of tanks from an experimental RTD
            %   N = (tm / sigma)^2 = tm^2 / sigma^2
            %
            % Input:
            %   rtd_obj - RTD object with computed moments

            if isempty(rtd_obj.tau) || isempty(rtd_obj.sigma2)
                error('RTD object must have computed moments (tau and sigma2)') ;
            end

            if rtd_obj.sigma2 <= 0
                error('RTD variance must be positive') ;
            end

            R.nTanks = rtd_obj.tau^2 / rtd_obj.sigma2 ;
            R.nTanks_method = 'from_rtd' ;

            fprintf('Tanks-in-Series: N = %.2f (from RTD variance)\n', R.nTanks) ;
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

        %% ============== ANALYTICAL CONVERSION (1st ORDER) ==============

        function XA = compute_conversion_firstOrder(R, k, tau_total)
            % Compute conversion for a first-order irreversible reaction
            %   XA = 1 - 1 / (1 + tau_i * k)^N
            %
            % Inputs:
            %   k         - rate constant (1/s)
            %   tau_total - total mean residence time (s)

            N = R.nTanks ;
            tau_i = tau_total / N ;

            XA = 1 - 1 / (1 + tau_i * k)^N ;

            fprintf('Tanks-in-Series (N=%.1f): X_A = %.4f for k=%.3g, tau=%.3g\n', ...
                    N, XA, k, tau_total) ;
        end

    end
end
