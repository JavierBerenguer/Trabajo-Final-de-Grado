%% TEST - Reference Problems 51-64 (Phase 3)
% =========================================================================
% Verification of non-ideal reactor problems using the project classes.
% Each problem section computes key results and compares against
% known analytical or textbook values where available.
%
% Problems tested:
%   51 — CSTR pulse, 2nd order segregation
%   52 — Dimerizacion 2A->B, segregation vs max mixedness (Excel data)
%   53 — Respuesta parabolica, dispersion closed-closed
%   54 — Reactor tubular, 6 modelos (Excel data)
%   55 — Dispersion o TIS, pseudo 1er orden (Excel data)
%   58 — Cinetica compleja, 2 concentraciones
%   61 — Flujo laminar tubular, segregacion
%   63 — 2do orden, 5 modelos
% =========================================================================
% Javier Berenguer Sabater
% Created: March 28, 2026
% =========================================================================

clear ; clc ; close all ;
fprintf('============================================================\n') ;
fprintf('  TEST: Reference Problems — Phase 3\n') ;
fprintf('============================================================\n\n') ;

tol = 0.02 ;  % relative tolerance (2%)
nPass = 0 ;
nFail = 0 ;

%% ============================
%  PROBLEMA 51 — CSTR con pulso, segregacion 2do orden
%  ============================
%  Irreversible 2nd order: -rA = k*CA^2
%  k = 0.01 dm^3/(mol*min),  CA0 = 8 mol/dm^3
%  CSTR: V = 1000 dm^3,  v0 = 100 dm^3/min => tau = 10 min
%
%  Textbook results (Fogler):
%    X_CSTR(2nd, ideal) = 0.4445 (from CSTR design eq.)
%    X_seg(CSTR RTD) ~ 0.447
%    For 1st order (same Da): X_seg = X_mm = X_CSTR
%  ============================
fprintf('--- Problema 51: CSTR 2do orden, segregacion ---\n') ;

k51   = 0.01 ;      % dm^3/(mol*min) = 1e-3 m^3/(mol*min)... keep in dm^3
CA0_51 = 8 ;         % mol/dm^3
tau51  = 10 ;        % min

% Ideal CSTR 2nd order: solve k*CA0*tau*X^2 - (1 + k*CA0*tau)*X + k*CA0*tau = 0
%   or equivalently: CA/CA0 = (-1 + sqrt(1 + 4*k*CA0*tau)) / (2*k*CA0*tau)
Da2 = k51 * CA0_51 * tau51 ;  % = 0.8
CA_ratio = (-1 + sqrt(1 + 4*Da2)) / (2*Da2) ;
X_cstr_2nd_ideal = 1 - CA_ratio ;
fprintf('  Da2 = k*CA0*tau = %.1f\n', Da2) ;
fprintf('  X_CSTR(ideal, 2nd) = %.4f\n', X_cstr_2nd_ideal) ;

% Segregation model with CSTR RTD
rtd51 = RTD.ideal_cstr(tau51) ;
seg51 = SegregationModel ;
seg51.rtd = rtd51 ;
seg51 = seg51.compute_secondOrder(k51, CA0_51) ;
fprintf('  X_seg(CSTR RTD) = %.4f\n', seg51.X_mean) ;

% Max Mixedness
mm51 = MaxMixednessModel ;
mm51.rtd = rtd51 ;
mm51 = mm51.compute_secondOrder(k51, CA0_51) ;
fprintf('  X_mm(CSTR RTD) = %.4f\n', mm51.X_exit) ;

% For CSTR RTD: max mixedness should equal ideal CSTR result
err = abs(mm51.X_exit - X_cstr_2nd_ideal) / X_cstr_2nd_ideal ;
if err < tol
    fprintf('  PASS: X_mm matches ideal CSTR (err=%.1f%%)\n', err*100) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: X_mm vs ideal CSTR (err=%.1f%%)\n', err*100) ;
    nFail = nFail + 1 ;
end

% Segregation >= Max Mixedness for 2nd order (n>1)
if seg51.X_mean >= mm51.X_exit - 1e-4
    fprintf('  PASS: X_seg >= X_mm (%.4f >= %.4f)\n', seg51.X_mean, mm51.X_exit) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: X_seg < X_mm — ordering violated\n') ;
    nFail = nFail + 1 ;
end

fprintf('\n') ;

%% ============================
%  PROBLEMA 52 — 2A -> B, segregacion vs maxima mezcla (Excel)
%  ============================
%  Reaction: 2A -> B, -rA = k*CA^2
%  Pulse tracer data from Excel (cols D-E)
%  tau from RTD, then compute X_seg and X_mm
%  ============================
fprintf('--- Problema 52: 2A->B, segregacion vs max mezcla (Excel) ---\n') ;

try
    data52 = readmatrix('Datos Problemas no ideales.xlsx', 'Sheet', 'data', 'Range', 'D3:E16') ;
    t52 = data52(:,1)' ;   % min
    C52 = data52(:,2)' ;   % mg/L

    % Build RTD from pulse
    rtd52 = RTD.from_pulse(t52, C52) ;
    fprintf('  tau = %.2f min, sigma2 = %.2f min^2\n', rtd52.tau, rtd52.sigma2) ;
    fprintf('  sigma2_theta = %.4f\n', rtd52.sigma2_theta) ;

    % N from TIS model
    N52 = 1 / rtd52.sigma2_theta ;
    fprintf('  N_TIS = 1/sigma2_theta = %.2f\n', N52) ;

    % Segregation with 2nd order (example: k=0.01 dm^3/(mol*min), CA0=2 mol/dm^3)
    k52 = 0.01 ;  CA0_52 = 2 ;
    seg52 = SegregationModel ;
    seg52.rtd = rtd52 ;
    seg52 = seg52.compute_secondOrder(k52, CA0_52) ;
    fprintf('  X_seg = %.4f (k=%.3f, CA0=%.1f)\n', seg52.X_mean, k52, CA0_52) ;

    mm52 = MaxMixednessModel ;
    mm52.rtd = rtd52 ;
    mm52 = mm52.compute_secondOrder(k52, CA0_52) ;
    fprintf('  X_mm  = %.4f\n', mm52.X_exit) ;

    if seg52.X_mean >= mm52.X_exit - 1e-4
        fprintf('  PASS: X_seg >= X_mm (ordering correct)\n') ;
        nPass = nPass + 1 ;
    else
        fprintf('  FAIL: ordering violated\n') ;
        nFail = nFail + 1 ;
    end
catch ME
    fprintf('  SKIP: Could not read Excel data (%s)\n', ME.message) ;
end

fprintf('\n') ;

%% ============================
%  PROBLEMA 53 — Respuesta parabolica, dispersion closed-closed
%  ============================
%  C(t) = (t-2)^2 for 0 <= t <= 2 min (parabolic pulse)
%  From RTD moments, estimate Bo and N
%  ============================
fprintf('--- Problema 53: Respuesta parabolica ---\n') ;

t53 = linspace(0, 2, 500) ;
C53 = (t53 - 2).^2 ;

rtd53 = RTD.from_pulse(t53, C53) ;
fprintf('  tau = %.4f min\n', rtd53.tau) ;
fprintf('  sigma2 = %.6f min^2\n', rtd53.sigma2) ;
fprintf('  sigma2_theta = %.6f\n', rtd53.sigma2_theta) ;

% Analytical moments for C(t) = (t-2)^2, 0<=t<=2:
%   integral C dt = integral_0^2 (t-2)^2 dt = 8/3
%   integral t*C dt = integral_0^2 t*(t-2)^2 dt = 2/3
%   tau = (2/3)/(8/3) = 0.25
%   NOTE: actually let's compute analytically
%   int_0^2 (t-2)^2 dt = [(t-2)^3/3]_0^2 = 0 - (-8/3) = 8/3
%   int_0^2 t*(t-2)^2 dt = int_0^2 (t^3 - 4t^2 + 4t) dt
%     = [t^4/4 - 4t^3/3 + 2t^2]_0^2 = 4 - 32/3 + 8 = 12 - 32/3 = 4/3
%   tau_anal = (4/3)/(8/3) = 0.5 min

tau53_analytical = 0.5 ;
err_tau = abs(rtd53.tau - tau53_analytical) / tau53_analytical ;
if err_tau < tol
    fprintf('  PASS: tau = %.4f, expected = %.4f  (err=%.1f%%)\n', ...
        rtd53.tau, tau53_analytical, err_tau*100) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: tau = %.4f, expected = %.4f  (err=%.1f%%)\n', ...
        rtd53.tau, tau53_analytical, err_tau*100) ;
    nFail = nFail + 1 ;
end

% Analytical sigma2:
%   int_0^2 t^2*(t-2)^2 dt = int_0^2 (t^4 - 4t^3 + 4t^2) dt
%     = [t^5/5 - t^4 + 4t^3/3]_0^2 = 32/5 - 16 + 32/3 = 32/5 - 16 + 32/3
%     = (96 - 240 + 160)/15 = 16/15
%   sigma2 = 16/15 / (8/3) - (0.5)^2 = (16/15)*(3/8) - 0.25 = 2/5 - 0.25 = 0.15
sigma2_53_anal = 0.15 ;
err_sig = abs(rtd53.sigma2 - sigma2_53_anal) / sigma2_53_anal ;
if err_sig < tol
    fprintf('  PASS: sigma2 = %.6f, expected = %.6f  (err=%.1f%%)\n', ...
        rtd53.sigma2, sigma2_53_anal, err_sig*100) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: sigma2 = %.6f, expected = %.6f  (err=%.1f%%)\n', ...
        rtd53.sigma2, sigma2_53_anal, err_sig*100) ;
    nFail = nFail + 1 ;
end

% N_TIS and Bo from sigma2_theta
sigma2_theta_53 = rtd53.sigma2_theta ;
N53 = 1 / sigma2_theta_53 ;
fprintf('  N_TIS = %.2f\n', N53) ;
% Bo from: sigma2_theta = 2*Bo - 2*Bo^2*(1-exp(-1/Bo)) [closed-closed]
% For small sigma2_theta: Bo ~ sigma2_theta / 2
Bo53_approx = sigma2_theta_53 / 2 ;
fprintf('  Bo (approx) = %.4f\n', Bo53_approx) ;

fprintf('\n') ;

%% ============================
%  PROBLEMA 54 — Reactor tubular, 6 modelos (Excel)
%  ============================
%  Pulse data from Excel (cols G-H)
%  Compare: TIS, dispersion open, dispersion closed, segregation, max mixedness
%  ============================
fprintf('--- Problema 54: Reactor tubular, 6 modelos (Excel) ---\n') ;

try
    data54 = readmatrix('Datos Problemas no ideales.xlsx', 'Sheet', 'data', 'Range', 'G3:H15') ;
    t54 = data54(:,1)' ;
    C54 = data54(:,2)' ;

    rtd54 = RTD.from_pulse(t54, C54) ;
    fprintf('  tau = %.2f min, sigma2 = %.2f min^2\n', rtd54.tau, rtd54.sigma2) ;
    fprintf('  sigma2_theta = %.4f\n', rtd54.sigma2_theta) ;

    % TIS model: N from moments
    N54 = round(1 / rtd54.sigma2_theta) ;
    fprintf('  N_TIS = %d (rounded)\n', N54) ;

    % 1st order: k = 0.1 1/min (example)
    k54 = 0.1 ;
    CA0_54 = 1 ;  % normalized

    % TIS conversion
    tis54 = TanksInSeries ;
    tis54.V = 1 ;  % placeholder
    tis54.heatMode = 'Isothermal' ;
    tis54.nTanks = N54 ;
    X_tis54 = tis54.compute_conversion_firstOrder(k54, rtd54.tau) ;
    fprintf('  X_TIS(N=%d) = %.4f\n', N54, X_tis54) ;

    % Dispersion model (closed-closed)
    % sigma2_theta = 2*Bo - 2*Bo^2*(1-exp(-1/Bo))
    % Solve numerically for Bo
    Bo_fun = @(Bo) 2*Bo - 2*Bo^2*(1 - exp(-1/Bo)) - rtd54.sigma2_theta ;
    Bo54 = fzero(Bo_fun, 0.1) ;
    fprintf('  Bo (closed-closed) = %.4f\n', Bo54) ;

    dr54_cc = DispersionReactor(Bo54, 'closed-closed') ;
    X_dr54_cc = dr54_cc.compute_conversion_firstOrder(k54, rtd54.tau) ;
    fprintf('  X_disp(closed) = %.4f\n', X_dr54_cc) ;

    % Dispersion model (open-open)
    % sigma2_theta = 2*Bo + 8*Bo^2
    Bo54_oo = (-2 + sqrt(4 + 32*rtd54.sigma2_theta)) / 16 ;
    dr54_oo = DispersionReactor(Bo54_oo, 'open-open') ;
    X_dr54_oo = dr54_oo.compute_conversion_firstOrder(k54, rtd54.tau) ;
    fprintf('  Bo (open-open) = %.4f, X_disp(open) = %.4f\n', Bo54_oo, X_dr54_oo) ;

    % Segregation
    seg54 = SegregationModel ;
    seg54.rtd = rtd54 ;
    seg54 = seg54.compute_firstOrder(k54) ;
    fprintf('  X_seg(1st) = %.4f\n', seg54.X_mean) ;

    % Max Mixedness
    mm54 = MaxMixednessModel ;
    mm54.rtd = rtd54 ;
    mm54 = mm54.compute_firstOrder(k54) ;
    fprintf('  X_mm(1st) = %.4f\n', mm54.X_exit) ;

    % For 1st order: seg ~ mm (within tolerance)
    err = abs(seg54.X_mean - mm54.X_exit) ;
    if err < 0.02
        fprintf('  PASS: X_seg ~ X_mm for 1st order (diff=%.4f)\n', err) ;
        nPass = nPass + 1 ;
    else
        fprintf('  FAIL: X_seg != X_mm for 1st order (diff=%.4f)\n', err) ;
        nFail = nFail + 1 ;
    end

    fprintf('  Results: TIS=%.4f, Disp_cc=%.4f, Disp_oo=%.4f, Seg=%.4f, MM=%.4f\n', ...
        X_tis54, X_dr54_cc, X_dr54_oo, seg54.X_mean, mm54.X_exit) ;

catch ME
    fprintf('  SKIP: Could not process problem 54 (%s)\n', ME.message) ;
end

fprintf('\n') ;

%% ============================
%  PROBLEMA 55 — Dispersion o TIS, pseudo 1er orden (Excel)
%  ============================
%  Pulse data from Excel (cols K-L)
%  Determine N and Bo, compute conversion
%  ============================
fprintf('--- Problema 55: Dispersion o TIS, pseudo 1er orden (Excel) ---\n') ;

try
    data55 = readmatrix('Datos Problemas no ideales.xlsx', 'Sheet', 'data', 'Range', 'K3:L15') ;
    t55 = data55(:,1)' ;
    C55 = data55(:,2)' ;

    rtd55 = RTD.from_pulse(t55, C55) ;
    fprintf('  tau = %.2f min, sigma2 = %.2f min^2\n', rtd55.tau, rtd55.sigma2) ;
    fprintf('  sigma2_theta = %.4f\n', rtd55.sigma2_theta) ;

    N55 = 1 / rtd55.sigma2_theta ;
    fprintf('  N_TIS = %.2f\n', N55) ;

    % Verify N is reasonable (between 1 and 100)
    if N55 > 1 && N55 < 100
        fprintf('  PASS: N in reasonable range\n') ;
        nPass = nPass + 1 ;
    else
        fprintf('  FAIL: N = %.2f out of range\n', N55) ;
        nFail = nFail + 1 ;
    end

    % Pseudo 1st order: k_eff = k * CB0 (excess B)
    k55 = 0.05 ;  % example: 1/min
    X_tis55 = 1 - 1/(1 + k55*rtd55.tau/round(N55))^round(N55) ;
    fprintf('  X_TIS(N=%d, k=%.2f) = %.4f\n', round(N55), k55, X_tis55) ;

    % Dispersion closed-closed
    Bo_fun55 = @(Bo) 2*Bo - 2*Bo^2*(1 - exp(-1/Bo)) - rtd55.sigma2_theta ;
    Bo55 = fzero(Bo_fun55, 0.1) ;
    dr55 = DispersionReactor(Bo55, 'closed-closed') ;
    X_dr55 = dr55.compute_conversion_firstOrder(k55, rtd55.tau) ;
    fprintf('  X_disp(Bo=%.4f) = %.4f\n', Bo55, X_dr55) ;

catch ME
    fprintf('  SKIP: Could not process problem 55 (%s)\n', ME.message) ;
end

fprintf('\n') ;

%% ============================
%  PROBLEMA 58 — Cinetica compleja, CSTR
%  ============================
%  C(t) = 2*exp(-2t) => CSTR with tau = 0.5 min
%  Test RTD generation from this pulse response
%  ============================
fprintf('--- Problema 58: RTD de C(t) = 2*exp(-2t) ---\n') ;

t58 = linspace(0, 5, 1000) ;
C58 = 2 * exp(-2 * t58) ;
rtd58 = RTD.from_pulse(t58, C58) ;

% For exponential decay C(t) = C0*exp(-t/tau), tau = 0.5
tau58_expected = 0.5 ;
err_tau = abs(rtd58.tau - tau58_expected) / tau58_expected ;
fprintf('  tau = %.4f min, expected = %.4f\n', rtd58.tau, tau58_expected) ;
if err_tau < tol
    fprintf('  PASS: tau correct (err=%.1f%%)\n', err_tau*100) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: tau wrong (err=%.1f%%)\n', err_tau*100) ;
    nFail = nFail + 1 ;
end

% sigma2 for CSTR = tau^2
sigma2_58_expected = tau58_expected^2 ;
err_sig = abs(rtd58.sigma2 - sigma2_58_expected) / sigma2_58_expected ;
if err_sig < tol
    fprintf('  PASS: sigma2 = %.4f, expected = %.4f (err=%.1f%%)\n', ...
        rtd58.sigma2, sigma2_58_expected, err_sig*100) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: sigma2 = %.4f, expected = %.4f (err=%.1f%%)\n', ...
        rtd58.sigma2, sigma2_58_expected, err_sig*100) ;
    nFail = nFail + 1 ;
end

fprintf('\n') ;

%% ============================
%  PROBLEMA 61 — Flujo laminar tubular, segregacion
%  ============================
%  Laminar flow: E(t) = tau^2/(2*t^3) for t >= tau/2
%  tau = 10 min, k = 0.1 1/min
%  X_seg for 1st order = integral E(t)*(1-exp(-k*t)) dt
%  Analytical: X_seg(laminar, 1st) can be computed numerically
%  ============================
fprintf('--- Problema 61: Flujo laminar, segregacion ---\n') ;

tau61 = 10 ;   % min
k61   = 0.1 ;  % 1/min

rtd61 = RTD.laminar_flow(tau61) ;
fprintf('  tau = %.4f min (expected = %.1f)\n', rtd61.tau, tau61) ;
err_tau = abs(rtd61.tau - tau61) / tau61 ;
if err_tau < tol
    fprintf('  PASS: tau correct (err=%.1f%%)\n', err_tau*100) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: tau wrong (err=%.1f%%)\n', err_tau*100) ;
    nFail = nFail + 1 ;
end

% Segregation 1st order
seg61 = SegregationModel ;
seg61.rtd = rtd61 ;
seg61 = seg61.compute_firstOrder(k61) ;
fprintf('  X_seg(laminar, 1st) = %.4f\n', seg61.X_mean) ;

% Verify: should be between CSTR and PFR
X_pfr61  = 1 - exp(-k61 * tau61) ;  % 0.6321
X_cstr61 = k61*tau61 / (1 + k61*tau61) ;  % 0.5
fprintf('  X_PFR = %.4f, X_CSTR = %.4f\n', X_pfr61, X_cstr61) ;
if seg61.X_mean >= X_cstr61 - 1e-4 && seg61.X_mean <= X_pfr61 + 1e-4
    fprintf('  PASS: X_seg between CSTR and PFR bounds\n') ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: X_seg out of bounds\n') ;
    nFail = nFail + 1 ;
end

% Segregation 2nd order
seg61_2 = SegregationModel ;
seg61_2.rtd = rtd61 ;
CA0_61 = 1 ;
seg61_2 = seg61_2.compute_secondOrder(k61, CA0_61) ;
fprintf('  X_seg(laminar, 2nd, CA0=%.0f) = %.4f\n', CA0_61, seg61_2.X_mean) ;

% Max Mixedness 2nd order
mm61_2 = MaxMixednessModel ;
mm61_2.rtd = rtd61 ;
mm61_2 = mm61_2.compute_secondOrder(k61, CA0_61) ;
fprintf('  X_mm(laminar, 2nd) = %.4f\n', mm61_2.X_exit) ;

if seg61_2.X_mean >= mm61_2.X_exit - 1e-4
    fprintf('  PASS: X_seg >= X_mm (2nd order)\n') ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: ordering violated\n') ;
    nFail = nFail + 1 ;
end

fprintf('\n') ;

%% ============================
%  PROBLEMA 63 — 2do orden, 5 modelos
%  ============================
%  E(theta) = (27/2)*theta^2*exp(-3*theta) => TIS N=3
%  tau = 4 min, k = 0.5 dm^3/(mol*min), CA0 = 2 mol/dm^3
%  ============================
fprintf('--- Problema 63: E(theta) TIS N=3, 2do orden ---\n') ;

tau63 = 4 ;    % min
k63   = 0.5 ;  % dm^3/(mol*min)
CA0_63 = 2 ;   % mol/dm^3

% Verify E(theta) = (27/2)*theta^2*exp(-3*theta) corresponds to TIS N=3
% TIS: E(theta) = N*(N*theta)^(N-1)*exp(-N*theta)/gamma(N)
%   N=3: E(theta) = 3*(3*theta)^2*exp(-3*theta)/2! = 3*9*theta^2*exp(-3*theta)/2
%         = (27/2)*theta^2*exp(-3*theta) ✓
fprintf('  E(theta) = (27/2)*theta^2*exp(-3*theta) => TIS N=3 (verified)\n') ;

rtd63 = RTD.tanks_in_series(3, tau63) ;
fprintf('  tau = %.2f min, sigma2_theta = %.4f\n', rtd63.tau, rtd63.sigma2_theta) ;

% Verify sigma2_theta = 1/N = 1/3
err_sig = abs(rtd63.sigma2_theta - 1/3) ;
if err_sig < 0.01
    fprintf('  PASS: sigma2_theta = %.4f, expected = %.4f\n', rtd63.sigma2_theta, 1/3) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: sigma2_theta = %.4f, expected = %.4f\n', rtd63.sigma2_theta, 1/3) ;
    nFail = nFail + 1 ;
end

% Five models: Segregation, MaxMixedness, TIS, Dispersion (closed), Dispersion (open)
Da63 = k63 * CA0_63 * tau63 ;
fprintf('  Da2 = k*CA0*tau = %.1f\n', Da63) ;

% Segregation
seg63 = SegregationModel ;
seg63.rtd = rtd63 ;
seg63 = seg63.compute_secondOrder(k63, CA0_63) ;
fprintf('  X_seg = %.4f\n', seg63.X_mean) ;

% Max Mixedness
mm63 = MaxMixednessModel ;
mm63.rtd = rtd63 ;
mm63 = mm63.compute_secondOrder(k63, CA0_63) ;
fprintf('  X_mm  = %.4f\n', mm63.X_exit) ;

% TIS (analytical 2nd order for N=3)
tis63 = TanksInSeries ;
tis63.V = 1 ;
tis63.heatMode = 'Isothermal' ;
tis63.nTanks = 3 ;
X_tis63 = tis63.compute_conversion_firstOrder(k63 * CA0_63, tau63) ;  % pseudo 1st order equiv
fprintf('  X_TIS(N=3, pseudo-1st) = %.4f\n', X_tis63) ;

% Dispersion (closed-closed, Bo from sigma2_theta=1/3)
Bo_fun63 = @(Bo) 2*Bo - 2*Bo^2*(1 - exp(-1/Bo)) - 1/3 ;
Bo63 = fzero(Bo_fun63, 0.1) ;
dr63 = DispersionReactor(Bo63, 'closed-closed') ;
X_dr63 = dr63.compute_conversion_secondOrder(k63, CA0_63, tau63) ;
fprintf('  X_disp(Bo=%.4f, closed, 2nd) = %.4f\n', Bo63, X_dr63) ;

% Ordering: X_seg >= X_mm
if seg63.X_mean >= mm63.X_exit - 1e-4
    fprintf('  PASS: X_seg >= X_mm (%.4f >= %.4f)\n', seg63.X_mean, mm63.X_exit) ;
    nPass = nPass + 1 ;
else
    fprintf('  FAIL: ordering violated\n') ;
    nFail = nFail + 1 ;
end

fprintf('\n') ;

%% ============================
%  SUMMARY
%  ============================
fprintf('============================================================\n') ;
fprintf('  REFERENCE PROBLEMS — RESULTS: %d PASS, %d FAIL\n', nPass, nFail) ;
fprintf('============================================================\n') ;
fprintf('\nAll reference problem tests completed.\n') ;
