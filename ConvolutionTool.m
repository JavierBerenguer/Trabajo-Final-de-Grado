classdef ConvolutionTool
% ConvolutionTool - Convolution and deconvolution for RTD analysis
%
% Implements the matrix formulation from Tema 4:
%
%   Convolution:   C_out = A * C_in
%     where A is the lower-triangular convolution matrix built from E(t)
%     C_out has (n+m-1) values for E with n values and C_in with m values
%
%   Deconvolution: Given C_in and C_out, recover E(t)
%     Minimize ||C_out - A*E||^2 using fminsearch
%
% Time vector rules:
%   Convolution:
%     t0_conv = t0_Cin + t0_E
%     tf_conv = tf_Cin + tf_E
%     dt_conv = dt (same as inputs, which must share the same dt)
%
%   Deconvolution:
%     t0_E = t0_Cout - t0_Cin
%     tf_E = tf_Cout - tf_Cin
%
% Usage:
%   [C_out, t_out] = ConvolutionTool.convolve(t_E, E, t_Cin, C_in) ;
%   [E_rec, t_E]   = ConvolutionTool.deconvolve(t_Cin, C_in, t_Cout, C_out, nE) ;
%
% =========================================================================
% Javier Berenguer Sabater
% Created: March 26, 2026. Last update: March 26, 2026
% =========================================================================

    methods (Static)

        %% ============== CONVOLUTION ==============

        function [C_out, t_out] = convolve(t_E, E, t_Cin, C_in)
            % Discrete convolution using matrix formulation
            %   C_out = A * C_in  where A is built from E
            %
            % Inputs:
            %   t_E   - [1 x n] time vector for E(t)
            %   E     - [1 x n] RTD values E(t)
            %   t_Cin - [1 x m] time vector for input signal C_in(t)
            %   C_in  - [1 x m] input concentration signal
            %
            % Outputs:
            %   C_out - [1 x (n+m-1)] output concentration signal
            %   t_out - [1 x (n+m-1)] time vector for output

            % Ensure column vectors for matrix operations
            E = E(:) ;
            C_in = C_in(:) ;

            n = length(E) ;
            m = length(C_in) ;
            v = n + m - 1 ;  % output length

            % Time increment (must be equal for both signals)
            dt_E = (t_E(end) - t_E(1)) / (n - 1) ;
            dt_C = (t_Cin(end) - t_Cin(1)) / (m - 1) ;

            % Check that dt is approximately equal
            if abs(dt_E - dt_C) / max(dt_E, dt_C) > 0.01
                warning('ConvolutionTool:dtMismatch', ...
                    'Time increments differ (dt_E=%.4g, dt_C=%.4g). Interpolating C_in to match dt_E.', ...
                    dt_E, dt_C) ;
                t_Cin_new = t_Cin(1):dt_E:t_Cin(end) ;
                C_in = interp1(t_Cin, C_in, t_Cin_new, 'pchip')' ;
                t_Cin = t_Cin_new ;
                m = length(C_in) ;
                v = n + m - 1 ;
            end

            dt = dt_E ;

            % Build convolution matrix A (v x m) from E
            % A(i,j) = E(i-j+1) if 1 <= i-j+1 <= n, else 0
            A = zeros(v, m) ;
            for j = 1:m
                for i = j:(j + n - 1)
                    A(i, j) = E(i - j + 1) ;
                end
            end

            % Convolve: C_out = A * C_in * dt
            C_out = (A * C_in * dt)' ;

            % Output time vector
            t0_out = t_Cin(1) + t_E(1) ;
            t_out = t0_out + (0:(v-1)) * dt ;
        end

        %% ============== DECONVOLUTION ==============

        function [E_rec, t_E, residual] = deconvolve(t_Cin, C_in, t_Cout, C_out, nE)
            % Deconvolution: recover E(t) from C_in and C_out
            %
            %   Minimize ||C_out - A*E*dt||^2 using fminsearch
            %
            % Inputs:
            %   t_Cin  - [1 x m] time vector for input signal
            %   C_in   - [1 x m] input concentration signal
            %   t_Cout - [1 x v] time vector for output signal
            %   C_out  - [1 x v] output concentration signal
            %   nE     - (optional) number of points for E. Default: v - m + 1
            %
            % Outputs:
            %   E_rec    - [1 x nE] recovered E(t)
            %   t_E      - [1 x nE] time vector for E
            %   residual - final residual ||C_out - A*E*dt||^2

            C_in = C_in(:) ;
            C_out = C_out(:) ;
            m = length(C_in) ;
            v = length(C_out) ;

            if nargin < 5
                nE = v - m + 1 ;
            end

            % Time increment
            dt = (t_Cin(end) - t_Cin(1)) / (m - 1) ;

            % Time vector for E
            t0_E = t_Cout(1) - t_Cin(1) ;
            t_E = t0_E + (0:(nE-1)) * dt ;

            % Build convolution matrix A (v x m) from E (unknown)
            % But we need to reformulate: C_out = B * E * dt
            % where B (v x nE) is built from C_in
            n = nE ;
            B = zeros(v, n) ;
            for j = 1:n
                for i = j:(min(j + m - 1, v))
                    if (i - j + 1) <= m
                        B(i, j) = C_in(i - j + 1) ;
                    end
                end
            end

            % Initial guess: uniform E
            E0 = ones(n, 1) / (n * dt) ;

            % Objective function: minimize ||C_out - B*E*dt||^2
            % with constraint E >= 0
            obj_fun = @(E_vec) sum((C_out - B * abs(E_vec(:)) * dt).^2) ;

            % Optimization options
            options = optimset('MaxFunEvals', 50000, 'MaxIter', 10000, ...
                              'TolFun', 1e-12, 'TolX', 1e-10, ...
                              'Display', 'off') ;

            [E_opt, residual] = fminsearch(obj_fun, E0, options) ;

            % Ensure non-negative
            E_rec = abs(E_opt(:))' ;

            % Normalize so integral = 1
            area = trapz(t_E, E_rec) ;
            if area > 0
                E_rec = E_rec / area ;
            end

            fprintf('Deconvolution: residual = %.4e, area(E) = %.4f\n', ...
                    residual, trapz(t_E, E_rec)) ;
        end

        %% ============== BUILD CONVOLUTION MATRIX ==============

        function A = build_conv_matrix(signal, n_out, n_cols)
            % Build the lower-triangular convolution matrix
            %   A(i,j) = signal(i-j+1) if valid index, else 0
            %
            % Inputs:
            %   signal - [n x 1] signal vector
            %   n_out  - number of output rows
            %   n_cols - number of columns

            n = length(signal) ;
            A = zeros(n_out, n_cols) ;
            for j = 1:n_cols
                for i = j:min(j + n - 1, n_out)
                    A(i, j) = signal(i - j + 1) ;
                end
            end
        end

    end
end
