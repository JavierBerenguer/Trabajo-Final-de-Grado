classdef RTD
    
% This class defines a Residence Time Distribution (RTD) for non-ideal reactors.
% Features:
%   - Store and manipulate E(t) and F(t) curves
%   - Compute moments: mean residence time (tm), variance (sigma2), skewness (s3)
%   - Normalize RTD to dimensionless form E(theta)
%   - Generate analytical RTDs for ideal reactors and common models
%   - Process experimental tracer data (pulse and step inputs)
%   - Plot E(t), F(t), E(theta)
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: March 22, 2026
% Precision update: increased resolution for numerical accuracy
% =========================================================================

    properties
        t               % [1 x N] time vector (s)
        Et              % [1 x N] E(t) values (1/s)
        source = ''     % char: 'experimental_pulse', 'experimental_step',
                        %       'cstr', 'pfr', 'tanks_in_series',
                        %       'dispersion', 'custom'
    end

    properties (SetAccess = private)
        tau             % mean residence time tm (s) - first moment
        sigma2          % variance (s^2) - second moment
        s3              % skewness - third moment (dimensionless)
    end

    properties (Dependent)
        Ft              % [1 x N] cumulative distribution F(t)
        theta           % [1 x N] dimensionless time t/tau
        Etheta          % [1 x N] dimensionless E(theta) = tau * E(t)
        sigma2_theta    % dimensionless variance sigma2/tau^2
    end

    methods

        %% ============== CONSTRUCTOR ==============
        function obj = RTD(t, Et)
            % RTD Constructor
            %   obj = RTD(t, Et) - Create RTD from time and E(t) vectors
            %   obj = RTD()     - Create empty RTD object
            %
            % Inputs:
            %   t  - [1 x N] time vector (s)
            %   Et - [1 x N] E(t) values (1/s)

            if nargin == 0
                return
            end

            if nargin ~= 2
                error('RTD constructor requires 0 or 2 arguments: RTD(t, Et)') ;
            end

            % Ensure row vectors
            if iscolumn(t),  t  = t' ;  end
            if iscolumn(Et), Et = Et' ; end

            if length(t) ~= length(Et)
                error('Vectors t and Et must have the same length') ;
            end

            if any(t < 0)
                error('Time vector t must contain non-negative values') ;
            end

            if any(Et < 0)
                warning('RTD:negativeValues', 'E(t) contains negative values. These may indicate experimental noise.') ;
            end

            obj.t  = t ;
            obj.Et = Et ;

            % Normalize and compute moments
            obj = obj.normalize() ;
            obj = obj.compute_moments() ;
        end

        %% ============== DEPENDENT PROPERTY GETTERS ==============

        function Ft = get.Ft(obj)
            % Cumulative distribution F(t) = integral of E(t) from 0 to t
            if isempty(obj.t) || isempty(obj.Et)
                Ft = [] ;
                return
            end
            Ft = cumtrapz(obj.t, obj.Et) ;
        end

        function theta = get.theta(obj)
            % Dimensionless time theta = t / tau
            if isempty(obj.t) || isempty(obj.tau) || obj.tau == 0
                theta = [] ;
                return
            end
            theta = obj.t / obj.tau ;
        end

        function Etheta = get.Etheta(obj)
            % Dimensionless RTD: E(theta) = tau * E(t)
            if isempty(obj.Et) || isempty(obj.tau)
                Etheta = [] ;
                return
            end
            Etheta = obj.tau * obj.Et ;
        end

        function sigma2_theta = get.sigma2_theta(obj)
            % Dimensionless variance: sigma2_theta = sigma2 / tau^2
            if isempty(obj.sigma2) || isempty(obj.tau) || obj.tau == 0
                sigma2_theta = [] ;
                return
            end
            sigma2_theta = obj.sigma2 / obj.tau^2 ;
        end

        %% ============== NORMALIZATION ==============

        function obj = normalize(obj)
            % Normalize E(t) so that integral from 0 to inf of E(t)dt = 1
            if isempty(obj.t) || isempty(obj.Et)
                return
            end

            area = trapz(obj.t, obj.Et) ;

            if area <= 0
                warning('RTD:zeroArea', 'Area under E(t) is zero or negative. Cannot normalize.') ;
                return
            end

            if abs(area - 1) > 1e-6
                obj.Et = obj.Et / area ;
            end
        end

        %% ============== MOMENTS ==============

        function obj = compute_moments(obj)
            % Compute the three main moments of the RTD:
            %   tau    = first moment (mean residence time)
            %   sigma2 = second central moment (variance)
            %   s3     = third standardized moment (skewness)

            if isempty(obj.t) || isempty(obj.Et)
                return
            end

            % First moment: mean residence time
            % tm = integral( t * E(t) dt )
            obj.tau = trapz(obj.t, obj.t .* obj.Et) ;

            % Second central moment: variance
            % sigma2 = integral( (t - tm)^2 * E(t) dt )
            obj.sigma2 = trapz(obj.t, (obj.t - obj.tau).^2 .* obj.Et) ;

            % Third standardized moment: skewness
            % s3 = (1/sigma^(3/2)) * integral( (t - tm)^3 * E(t) dt )
            if obj.sigma2 > 0
                third_moment = trapz(obj.t, (obj.t - obj.tau).^3 .* obj.Et) ;
                obj.s3 = third_moment / (obj.sigma2^(3/2)) ;
            else
                obj.s3 = 0 ;
            end
        end

        %% ============== PLOTTING METHODS ==============

        function fig = plot_Et(obj, ax)
            % Plot E(t) vs t
            %   plot_Et(obj)     - plot in new figure
            %   plot_Et(obj, ax) - plot on specified axes

            if isempty(obj.t) || isempty(obj.Et)
                error('RTD object is empty. Cannot plot.') ;
            end

            if nargin < 2
                fig = figure ;
                ax = axes(fig) ;
            else
                fig = ancestor(ax, 'figure') ;
            end

            plot(ax, obj.t, obj.Et, 'b-', 'LineWidth', 1.5) ;
            xlabel(ax, 't (s)') ;
            ylabel(ax, 'E(t) (1/s)') ;
            title(ax, 'Residence Time Distribution - E(t)') ;
            grid(ax, 'on') ;

            % Add moments info as text
            if ~isempty(obj.tau)
                str = sprintf('t_m = %.3g s\n\\sigma^2 = %.3g s^2', obj.tau, obj.sigma2) ;
                text(ax, 0.95, 0.95, str, 'Units', 'normalized', ...
                    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
                    'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', 'k') ;
            end
        end

        function fig = plot_Ft(obj, ax)
            % Plot F(t) vs t (cumulative distribution)
            %   plot_Ft(obj)     - plot in new figure
            %   plot_Ft(obj, ax) - plot on specified axes

            if isempty(obj.t) || isempty(obj.Et)
                error('RTD object is empty. Cannot plot.') ;
            end

            if nargin < 2
                fig = figure ;
                ax = axes(fig) ;
            else
                fig = ancestor(ax, 'figure') ;
            end

            plot(ax, obj.t, obj.Ft, 'r-', 'LineWidth', 1.5) ;
            xlabel(ax, 't (s)') ;
            ylabel(ax, 'F(t)') ;
            title(ax, 'Cumulative Distribution - F(t)') ;
            grid(ax, 'on') ;
            ylim(ax, [0 1.05]) ;
        end

        function fig = plot_Etheta(obj, ax)
            % Plot dimensionless E(theta) vs theta
            %   plot_Etheta(obj)     - plot in new figure
            %   plot_Etheta(obj, ax) - plot on specified axes

            if isempty(obj.t) || isempty(obj.Et) || isempty(obj.tau)
                error('RTD object is empty or tau not computed. Cannot plot.') ;
            end

            if nargin < 2
                fig = figure ;
                ax = axes(fig) ;
            else
                fig = ancestor(ax, 'figure') ;
            end

            plot(ax, obj.theta, obj.Etheta, 'g-', 'LineWidth', 1.5) ;
            xlabel(ax, '\Theta = t/\tau') ;
            ylabel(ax, 'E(\Theta)') ;
            title(ax, 'Dimensionless RTD - E(\Theta)') ;
            grid(ax, 'on') ;
        end

        function fig = plot_all(obj, figHandle)
            % Plot E(t), F(t) and E(theta) in a single figure with 3 subplots
            %   plot_all(obj)          - create new figure
            %   plot_all(obj, figHandle) - use specified figure

            if nargin < 2
                fig = figure('Name', 'RTD Analysis', 'NumberTitle', 'off') ;
            else
                fig = figHandle ;
                clf(fig) ;
            end

            ax1 = subplot(1, 3, 1, 'Parent', fig) ;
            obj.plot_Et(ax1) ;

            ax2 = subplot(1, 3, 2, 'Parent', fig) ;
            obj.plot_Ft(ax2) ;

            ax3 = subplot(1, 3, 3, 'Parent', fig) ;
            obj.plot_Etheta(ax3) ;

            sgtitle(fig, sprintf('RTD Analysis  |  Source: %s', obj.source)) ;
        end

    end

    %% ============== STATIC METHODS (FACTORY) ==============

    methods (Static)

        function obj = ideal_cstr(tau_val, tspan)
            % Generate E(t) for an ideal CSTR
            %   obj = RTD.ideal_cstr(tau)        - default time span [0, 10*tau]
            %   obj = RTD.ideal_cstr(tau, tspan)  - custom time vector
            %
            % E(t) = (1/tau) * exp(-t/tau)
            % Analytical moments: tau = tau_val, sigma2 = tau_val^2, s3 = 2

            if nargin < 2
                tspan = linspace(0, 15 * tau_val, 3000) ;
            end

            Et = (1/tau_val) * exp(-tspan / tau_val) ;

            obj = RTD(tspan, Et) ;
            obj.source = 'cstr' ;

            % Override with exact analytical moments (avoid trapz truncation)
            obj.tau    = tau_val ;
            obj.sigma2 = tau_val^2 ;
            obj.s3     = 2 ;
        end

        function obj = ideal_pfr(tau_val, tspan)
            % Generate E(t) for an ideal PFR (approximated as narrow Gaussian)
            %   obj = RTD.ideal_pfr(tau)        - default time span [0, 2*tau]
            %   obj = RTD.ideal_pfr(tau, tspan)  - custom time vector
            %
            % E(t) = delta(t - tau) approximated as narrow Gaussian
            % Analytical moments: tau = tau_val, sigma2 = 0, s3 = 0

            if nargin < 2
                tspan = linspace(0, 2 * tau_val, 1000) ;
            end

            % Approximate delta function with narrow Gaussian
            % sigma_gauss chosen as tau/200 for a sharp peak
            sigma_gauss = tau_val / 200 ;
            Et = (1 / (sigma_gauss * sqrt(2*pi))) * ...
                 exp(-0.5 * ((tspan - tau_val) / sigma_gauss).^2) ;

            obj = RTD(tspan, Et) ;
            obj.source = 'pfr' ;

            % Override with exact analytical moments
            obj.tau    = tau_val ;
            obj.sigma2 = 0 ;
            obj.s3     = 0 ;
        end

        function obj = tanks_in_series(n, tau_total, tspan)
            % Generate E(t) for the tanks-in-series model
            %   obj = RTD.tanks_in_series(n, tau_total)        - default time span
            %   obj = RTD.tanks_in_series(n, tau_total, tspan)  - custom time vector
            %
            % E(t) = (n/tau_total) * (n*t/tau_total)^(n-1) / (n-1)! * exp(-n*t/tau_total)
            % Analytical moments: tau = tau_total, sigma2 = tau_total^2/n, s3 = 2/sqrt(n)
            %
            % Inputs:
            %   n         - number of tanks (can be non-integer for the model)
            %   tau_total - total mean residence time (s)

            if nargin < 3
                % Extend range for low N (exponential tail longer)
                multiplier = max(5, 15/sqrt(n)) ;
                npts = max(1000, round(3000/sqrt(n))) ;
                tspan = linspace(0, multiplier * tau_total, npts) ;
            end

            tau_i = tau_total / n ;  % residence time per tank

            % Use gamma function for non-integer n:
            % E(t) = t^(n-1) / (gamma(n) * tau_i^n) * exp(-t/tau_i)
            Et = (tspan.^(n-1)) ./ (gamma(n) * tau_i^n) .* exp(-tspan / tau_i) ;

            % Handle t=0 for n=1 (E(0) = 1/tau_i)
            % For n>1, E(0) = 0, which is already correct
            % For n=1, 0^0 = 1 in MATLAB, so it works

            obj = RTD(tspan, Et) ;
            obj.source = 'tanks_in_series' ;

            % Override with exact analytical moments
            obj.tau    = tau_total ;
            obj.sigma2 = tau_total^2 / n ;
            obj.s3     = 2 / sqrt(n) ;
        end

        function obj = dispersion_open(Bo, tau_val, tspan)
            % Generate E(t) for the dispersion model (small dispersion / open-open)
            %   obj = RTD.dispersion_open(Bo, tau)
            %   obj = RTD.dispersion_open(Bo, tau, tspan)
            %
            % E(t) = 1/(t_bar * sqrt(4*pi*Bo)) * exp(-(1 - t/t_bar)^2 / (4*Bo))
            %
            % Valid approximation for small dispersion (Bo < 0.01, i.e., Pe > 100)
            % Bo = De/(u*L) = 1/Pe (Bodenstein inverse = dispersion number)

            if nargin < 3
                spread = max(3, 1 + 6*sqrt(Bo)) ;  % wider range for large Bo
                tspan = linspace(0, spread * tau_val, 2000) ;
            end

            Et = zeros(size(tspan)) ;
            idx = tspan > 0 ;  % avoid division by zero at t=0
            Et(idx) = (1 ./ (tau_val * sqrt(4*pi*Bo))) .* ...
                      exp(-(1 - tspan(idx)/tau_val).^2 ./ (4*Bo)) ;

            obj = RTD(tspan, Et) ;
            obj.source = 'dispersion' ;

            % Override with exact analytical moments (open-open BC)
            % sigma2_theta = 2*Bo + 8*Bo^2 → sigma2 = tau^2 * (2*Bo + 8*Bo^2)
            obj.tau    = tau_val ;
            obj.sigma2 = tau_val^2 * (2*Bo + 8*Bo^2) ;
        end

        function obj = dispersion_closed(Bo, tau_val, tspan)
            % Generate E(t) for the dispersion model with closed-closed BCs
            %   obj = RTD.dispersion_closed(Bo, tau, tspan)
            %
            % Uses numerical inverse of the Danckwerts solution.
            % For small Bo (< 0.01), it converges to the open approximation.
            % For larger Bo, uses the series solution.
            %
            % Bo = De/(u*L) = dispersion number

            if nargin < 3
                spread = max(3, 1 + 6*sqrt(Bo)) ;
                tspan = linspace(0, spread * tau_val, 2000) ;
            end

            theta = tspan / tau_val ;
            Etheta = zeros(size(theta)) ;

            if Bo < 0.01
                % Small dispersion: Gaussian approximation
                idx = theta > 0 ;
                Etheta(idx) = (1 ./ sqrt(4*pi*Bo)) .* ...
                             exp(-(1 - theta(idx)).^2 ./ (4*Bo)) ;
            else
                % Larger dispersion: numerical series solution (Nauman, 1981)
                % E(theta) = sum_{n=1}^{inf} c_n * exp(-lambda_n * theta)
                % Approximation using eigenvalue expansion
                idx = theta > 0 ;
                nTerms = 200 ;
                for k = 1:nTerms
                    % Eigenvalues from: tan(alpha) = 2*alpha*Bo / (alpha^2*Bo^2 - 1)
                    % Approximate eigenvalues
                    alpha_k = k * pi ;  % initial guess
                    try
                        alpha_k = fzero(@(a) tan(a) - 2*a*Bo./(a.^2*Bo^2 - 1), ...
                                       alpha_k + 0.1) ;
                    catch
                        continue ;
                    end
                    lambda_k = (1 + alpha_k^2 * Bo) / (2*Bo) ;
                    c_k = 2 * Bo * alpha_k^2 / ...
                          (alpha_k^2 * Bo^2 + Bo + alpha_k^2 * Bo) ;
                    Etheta(idx) = Etheta(idx) + c_k * exp(-lambda_k * theta(idx)) ;
                end
            end

            Et = Etheta / tau_val ;
            obj = RTD(tspan, Et) ;
            obj.source = 'dispersion' ;

            % Override with exact analytical moments (closed-closed BC)
            % sigma2_theta = 2*Bo - 2*Bo^2*(1-exp(-1/Bo))
            obj.tau    = tau_val ;
            obj.sigma2 = tau_val^2 * (2*Bo - 2*Bo^2*(1 - exp(-1/Bo))) ;
        end

        function obj = from_pulse(t, Cpulse)
            % Create RTD from experimental pulse (impulse) tracer data
            %   obj = RTD.from_pulse(t, Cpulse)
            %
            % E(t) = C(t) / integral(C(t) dt)
            %
            % Inputs:
            %   t      - [1 x N] time vector (s)
            %   Cpulse - [1 x N] tracer concentration at outlet

            if iscolumn(t),      t      = t' ;      end
            if iscolumn(Cpulse), Cpulse = Cpulse' ; end

            if length(t) ~= length(Cpulse)
                error('Vectors t and Cpulse must have the same length') ;
            end

            % Normalize: E(t) = C(t) / integral(C(t)dt)
            area = trapz(t, Cpulse) ;
            if area <= 0
                error('Area under pulse response is zero or negative. Check data.') ;
            end

            Et = Cpulse / area ;

            obj = RTD(t, Et) ;
            obj.source = 'experimental_pulse' ;
        end

        function obj = from_step(t, Cstep, C0)
            % Create RTD from experimental step tracer data
            %   obj = RTD.from_step(t, Cstep)
            %   obj = RTD.from_step(t, Cstep, C0)
            %
            % F(t) = Cstep(t) / C0
            % E(t) = dF/dt
            %
            % Inputs:
            %   t     - [1 x N] time vector (s)
            %   Cstep - [1 x N] tracer concentration at outlet (step response)
            %   C0    - (optional) inlet tracer concentration. If not given,
            %           C0 = max(Cstep) is used

            if iscolumn(t),     t     = t' ;     end
            if iscolumn(Cstep), Cstep = Cstep' ; end

            if length(t) ~= length(Cstep)
                error('Vectors t and Cstep must have the same length') ;
            end

            if nargin < 3
                C0 = Cstep(end) ;  % assume final value is the steady-state
                if C0 <= 0
                    C0 = max(Cstep) ;
                end
            end

            % F(t) = Cstep / C0
            Ft_data = Cstep / C0 ;

            % Clip to [0, 1]
            Ft_data = max(0, min(1, Ft_data)) ;

            % E(t) = dF/dt (numerical differentiation)
            Et = gradient(Ft_data, t) ;

            % Remove negative values from numerical differentiation
            Et = max(0, Et) ;

            obj = RTD(t, Et) ;
            obj.source = 'experimental_step' ;
        end

        function obj = from_cstr_series_with_pfr(tau_cstr, tau_pfr, tspan)
            % Generate E(t) for a CSTR + PFR in series
            %   obj = RTD.from_cstr_series_with_pfr(tau_cstr, tau_pfr)
            %   obj = RTD.from_cstr_series_with_pfr(tau_cstr, tau_pfr, tspan)
            %
            % E(t) = 0                                     for t < tau_pfr
            % E(t) = (1/tau_cstr) * exp(-(t-tau_pfr)/tau_cstr)  for t >= tau_pfr

            if nargin < 3
                tspan = linspace(0, 5 * (tau_cstr + tau_pfr), 500) ;
            end

            Et = zeros(size(tspan)) ;
            idx = tspan >= tau_pfr ;
            Et(idx) = (1/tau_cstr) * exp(-(tspan(idx) - tau_pfr) / tau_cstr) ;

            obj = RTD(tspan, Et) ;
            obj.source = 'custom' ;

            % Override with exact analytical moments
            % tau = tau_cstr + tau_pfr, sigma2 = tau_cstr^2
            obj.tau    = tau_cstr + tau_pfr ;
            obj.sigma2 = tau_cstr^2 ;
        end

    end

end
