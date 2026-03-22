%% TEST - Non-Ideal Reactor Models (Phase 1)
% =========================================================================
% This script tests the non-ideal reactor classes:
%   1. RTD class (analytical and from experimental data)
%   2. Tanks-in-Series model
%   3. Segregation Model (complete segregation)
%   4. Maximum Mixedness Model (earliest mixing)
%
% Exercise: Irreversible reaction A -> B in liquid phase
%   - First order: -rA = k*CA, k = 0.1 1/min
%   - CA0 = 1 mol/L = 1000 mol/m^3
%   - Qv = 1 L/min = 1e-3 m^3/min
%   - V = 10 L = 0.01 m^3
%   - tau = V/Qv = 10 min
%
% Known analytical results for comparison:
%   - Ideal PFR:  X = 1 - exp(-k*tau) = 1 - exp(-1) = 0.6321
%   - Ideal CSTR: X = k*tau/(1+k*tau) = 1/(1+1) = 0.5000
%   - For 1st order, segregation = max mixedness = exact
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: March 21, 2026
% =========================================================================

clear ; clc ; close all ;
fprintf('============================================================\n') ;
fprintf('  TEST: Non-Ideal Reactor Models - Phase 1\n') ;
fprintf('============================================================\n\n') ;

%% ============================
%  PARAMETERS
%  ============================
k   = 0.1 ;       % rate constant (1/min)
CA0 = 1000 ;       % mol/m^3 (= 1 mol/L)
Qv  = 1e-3 ;       % m^3/min (= 1 L/min)
V   = 0.01 ;       % m^3 (= 10 L)
tau = V / Qv ;     % 10 min

fprintf('Reaction: A -> B (liquid phase, 1st order)\n') ;
fprintf('k = %.2f 1/min, CA0 = %.0f mol/m^3\n', k, CA0) ;
fprintf('V = %.4f m^3, Qv = %.4f m^3/min, tau = %.1f min\n\n', V, Qv, tau) ;

%% ============================
%  1. ANALYTICAL REFERENCE VALUES
%  ============================
fprintf('--- 1. Analytical Reference Values ---\n') ;
X_pfr  = 1 - exp(-k * tau) ;
X_cstr = k * tau / (1 + k * tau) ;
fprintf('Ideal PFR:  X = %.4f\n', X_pfr) ;
fprintf('Ideal CSTR: X = %.4f\n\n', X_cstr) ;

%% ============================
%  2. TEST RTD CLASS
%  ============================
fprintf('--- 2. Testing RTD Class ---\n') ;

% 2a. Ideal CSTR RTD
rtd_cstr = RTD.ideal_cstr(tau) ;
fprintf('RTD CSTR: tau = %.4f, sigma2 = %.4f, s3 = %.4f\n', ...
        rtd_cstr.tau, rtd_cstr.sigma2, rtd_cstr.s3) ;
fprintf('  Expected: tau = %.1f, sigma2 = %.1f\n', tau, tau^2) ;

% 2b. Ideal PFR RTD
rtd_pfr = RTD.ideal_pfr(tau) ;
fprintf('RTD PFR:  tau = %.4f, sigma2 = %.6f (should be ~0)\n', ...
        rtd_pfr.tau, rtd_pfr.sigma2) ;

% 2c. Tanks-in-Series RTD (N=3)
rtd_tis3 = RTD.tanks_in_series(3, tau) ;
fprintf('RTD TIS(N=3): tau = %.4f, sigma2 = %.4f\n', ...
        rtd_tis3.tau, rtd_tis3.sigma2) ;
fprintf('  Expected: sigma2 = tau^2/N = %.4f\n', tau^2/3) ;

% 2d. Tanks-in-Series RTD (N=10)
rtd_tis10 = RTD.tanks_in_series(10, tau) ;
fprintf('RTD TIS(N=10): tau = %.4f, sigma2 = %.4f\n', ...
        rtd_tis10.tau, rtd_tis10.sigma2) ;
fprintf('  Expected: sigma2 = tau^2/N = %.4f\n', tau^2/10) ;

% 2e. From experimental pulse data (simulate a CSTR response)
t_exp = linspace(0, 50, 100) ;
C_exp = 5 * exp(-t_exp / tau) ;  % CSTR-like pulse response
rtd_exp = RTD.from_pulse(t_exp, C_exp) ;
fprintf('RTD from pulse: tau = %.4f (expected ~%.1f)\n', rtd_exp.tau, tau) ;

fprintf('\n') ;

%% ============================
%  3. TEST TANKS-IN-SERIES REACTOR
%  ============================
fprintf('--- 3. Testing Tanks-in-Series Reactor ---\n') ;

% 3a. Analytical first-order conversion
tis = TanksInSeries ;
tis.V = V ;
tis.heatMode = 'Isothermal' ;

% N=1 should give CSTR result
tis.nTanks = 1 ;
X_tis1 = tis.compute_conversion_firstOrder(k, tau) ;
fprintf('  Expected (CSTR): X = %.4f\n', X_cstr) ;

% N=3
tis.nTanks = 3 ;
X_tis3 = tis.compute_conversion_firstOrder(k, tau) ;
X_tis3_expected = 1 - 1/(1 + k*tau/3)^3 ;
fprintf('  Expected: X = %.4f\n', X_tis3_expected) ;

% N=100 should approach PFR
tis.nTanks = 100 ;
X_tis100 = tis.compute_conversion_firstOrder(k, tau) ;
fprintf('  Expected (~PFR): X = %.4f\n', X_pfr) ;

% 3b. Full compute_output with CSTR objects (N=3)
fprintf('\n  Testing compute_output with N=3 CSTRs:\n') ;

% Define reaction system
RS = ReactionSys ;
RS.stochiometricMatrix = [-1, 1] ;  % A -> B
RS.k0 = k ;                         % k at reference T (no Ea)
RS.Ea = 0 ;
RS.componentCp = [75, 75] ;         % J/(mol*K) - arbitrary
RS.DHref = 0 ;                      % Isothermal

% Define feed stream
Feed = Stream ;
Feed.molarFlow = [CA0 * Qv, 0] ;    % [FA0, FB0] in mol/min
Feed.T = 298.15 ;
Feed.P = 101325 ;
Feed.phase = 'L' ;
Feed.volumetricFlow = Qv ;
Feed.density = 1000 ;               % kg/m^3 (water)

tis3 = TanksInSeries ;
tis3.V = V ;
tis3.nTanks = 3 ;
tis3.heatMode = 'Isothermal' ;

[Product_tis3, tis3] = tis3.compute_output(Feed, RS) ;
X_computed = 1 - Product_tis3.molarFlow(1) / Feed.molarFlow(1) ;
fprintf('  Computed X (compute_output, N=3) = %.4f\n', X_computed) ;
fprintf('  Expected X (analytical, N=3)     = %.4f\n', X_tis3_expected) ;

% 3c. Determine N from RTD
tis_fromRTD = TanksInSeries ;
tis_fromRTD.V = V ;
tis_fromRTD.heatMode = 'Isothermal' ;
tis_fromRTD = tis_fromRTD.compute_nTanks_from_RTD(rtd_tis3) ;
fprintf('  N determined from RTD(N=3): %.2f (expected ~3.00)\n', tis_fromRTD.nTanks) ;

fprintf('\n') ;

%% ============================
%  4. TEST SEGREGATION MODEL
%  ============================
fprintf('--- 4. Testing Segregation Model ---\n') ;

% 4a. First order with CSTR RTD
seg_cstr = SegregationModel ;
seg_cstr.rtd = rtd_cstr ;
seg_cstr = seg_cstr.compute_firstOrder(k) ;
fprintf('  Expected (CSTR, 1st order): X = %.4f\n', X_cstr) ;

% 4b. First order with PFR RTD
seg_pfr = SegregationModel ;
seg_pfr.rtd = rtd_pfr ;
seg_pfr = seg_pfr.compute_firstOrder(k) ;
fprintf('  Expected (PFR, 1st order): X = %.4f\n', X_pfr) ;

% 4c. First order with TIS(N=3) RTD
seg_tis3 = SegregationModel ;
seg_tis3.rtd = rtd_tis3 ;
seg_tis3 = seg_tis3.compute_firstOrder(k) ;
fprintf('  Expected TIS(N=3): X = %.4f\n', X_tis3_expected) ;

% 4d. Second order with CSTR RTD
%   For 2nd order: segregation gives higher X than max mixedness (CSTR)
%   CSTR 2nd order: X = (-1 + sqrt(1+4*k*CA0*tau)) / (2*k*CA0*tau)
%   Wait - that's for CA: CA/CA0 = (-1+sqrt(1+4*Da))/(2*Da)
Da = k * CA0 * tau ;  % Damkohler for 2nd order (dimensionless only if k has right units)
% Actually for -rA = k*CA^2: tau = X/(k*CA0*(1-X)^2) for CSTR
% Let's use Da2 = k*CA0*tau
% CSTR: X_cstr_2nd from quadratic: 1/(1+k*CA0*tau*(1-X)) - need fsolve
% Simpler: use the analytical for segregation
fprintf('\n  Second-order reaction (-rA = k*CA^2):\n') ;
fprintf('  Da = k*CA0*tau = %.1f\n', k * CA0 * tau) ;

seg_2nd = SegregationModel ;
seg_2nd.rtd = rtd_cstr ;
seg_2nd = seg_2nd.compute_secondOrder(k, CA0) ;

fprintf('\n') ;

%% ============================
%  5. TEST MAXIMUM MIXEDNESS MODEL
%  ============================
fprintf('--- 5. Testing Maximum Mixedness Model ---\n') ;

% 5a. First order with CSTR RTD
mm_cstr = MaxMixednessModel ;
mm_cstr.rtd = rtd_cstr ;
mm_cstr = mm_cstr.compute_firstOrder(k) ;
fprintf('  Expected (CSTR, 1st order): X = %.4f\n', X_cstr) ;

% 5b. First order with TIS(N=3) RTD
mm_tis3 = MaxMixednessModel ;
mm_tis3.rtd = rtd_tis3 ;
mm_tis3 = mm_tis3.compute_firstOrder(k) ;
fprintf('  Expected TIS(N=3): X = %.4f\n', X_tis3_expected) ;

% 5c. Second order with CSTR RTD - should give LOWER bound
fprintf('\n  Second-order comparison (CSTR RTD):\n') ;
mm_2nd = MaxMixednessModel ;
mm_2nd.rtd = rtd_cstr ;
mm_2nd = mm_2nd.compute_secondOrder(k, CA0) ;
fprintf('  Segregation X  = %.4f (upper bound for n>1)\n', seg_2nd.X_mean) ;
fprintf('  Max Mixedness X = %.4f (lower bound for n>1)\n', mm_2nd.X_exit) ;

fprintf('\n') ;

%% ============================
%  6. SUMMARY TABLE
%  ============================
fprintf('============================================================\n') ;
fprintf('  SUMMARY - First Order Reaction (k=%.2f, tau=%.0f)\n', k, tau) ;
fprintf('============================================================\n') ;
fprintf('  %-30s  X_A\n', 'Model') ;
fprintf('  %-30s  ------\n', '------------------------------') ;
fprintf('  %-30s  %.4f\n', 'Ideal PFR (analytical)', X_pfr) ;
fprintf('  %-30s  %.4f\n', 'TIS N=100 (analytical)', X_tis100) ;
fprintf('  %-30s  %.4f\n', 'TIS N=3 (analytical)', X_tis3) ;
fprintf('  %-30s  %.4f\n', 'TIS N=3 (compute_output)', X_computed) ;
fprintf('  %-30s  %.4f\n', 'Segregation (CSTR RTD)', seg_cstr.X_mean) ;
fprintf('  %-30s  %.4f\n', 'Segregation (TIS N=3 RTD)', seg_tis3.X_mean) ;
fprintf('  %-30s  %.4f\n', 'Max Mixedness (CSTR RTD)', mm_cstr.X_exit) ;
fprintf('  %-30s  %.4f\n', 'Max Mixedness (TIS N=3 RTD)', mm_tis3.X_exit) ;
fprintf('  %-30s  %.4f\n', 'Ideal CSTR (analytical)', X_cstr) ;
fprintf('============================================================\n') ;
fprintf('\nNOTE: For 1st order reactions, Segregation = Max Mixedness = Exact\n') ;
fprintf('      regardless of mixing state. All should match analytical values.\n') ;

%% ============================
%  7. PLOTS
%  ============================
fprintf('\nGenerating plots...\n') ;

% Plot RTDs comparison
figure('Name', 'RTD Comparison', 'NumberTitle', 'off') ;
hold on ;
plot(rtd_cstr.t, rtd_cstr.Et, 'b-', 'LineWidth', 1.5) ;
plot(rtd_tis3.t, rtd_tis3.Et, 'r-', 'LineWidth', 1.5) ;
plot(rtd_tis10.t, rtd_tis10.Et, 'g-', 'LineWidth', 1.5) ;
xlabel('t (min)') ;
ylabel('E(t) (1/min)') ;
title('RTD Comparison') ;
legend('CSTR (N=1)', 'TIS N=3', 'TIS N=10', 'Location', 'best') ;
grid on ;
hold off ;

% Plot segregation results
seg_tis3.plot_results() ;

% Plot max mixedness results
mm_tis3.plot_results() ;

fprintf('\nAll tests completed.\n') ;
