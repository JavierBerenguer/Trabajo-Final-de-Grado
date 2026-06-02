clear
clc
close all

%% Problem 52 - Non-ideal reactor bounds from pulse RTD data
% Reads the tracer data directly from "Datos Problemas no ideales.xlsx"
% and reproduces the reported conversions for:
%   - Segregation model
%   - Maximum mixedness model
%
% Problem statement summary:
%   2A -> B
%   -rA = k * CA^2
%   k   = 0.01 L/(mol min)
%   CA0 = 8 mol/L
%   Q   = 25 L/min

dataFile = fullfile(fileparts(mfilename('fullpath')), 'Datos Problemas no ideales.xlsx') ;
raw = readmatrix(dataFile, 'Sheet', 'data', 'Range', 'F3:G30') ;

% Problem 52 is stored in columns F:G of the workbook.
t = raw(:, 1) ;
C = raw(:, 2) ;
valid = ~isnan(t) & ~isnan(C) ;
t = t(valid)' ;
C = C(valid)' ;

% Build RTD from pulse experiment.
rtd = RTD.from_pulse(t, C) ;

% Keep the kinetics in the original units of the statement:
% time in min, concentration in mol/L and k in L/(mol min).
RS = ReactionSys.fromSimpleKinetics('2nd_order', struct('k', 0.01)) ;
C0 = 8 ;
Q = 25 ;

seg = SegregationModel(rtd) ;
seg = seg.compute_isothermal(RS, C0) ;

mm = MaxMixednessModel(rtd) ;
mm = mm.compute_isothermal(RS, C0) ;

Veff = rtd.tau * Q ;

fprintf('Problem 52 results\n') ;
fprintf('tau_m = %.4f min\n', rtd.tau) ;
fprintf('X_A (Segregation)      = %.6f\n', seg.X_mean) ;
fprintf('X_A (Max Mixedness)    = %.6f\n', mm.X_exit) ;
fprintf('V_effective            = %.4f L\n', Veff) ;

fprintf('\nReference solution sheet\n') ;
fprintf('X_A (Segregation)      = 0.606\n') ;
fprintf('X_A (Max Mixedness)    = 0.565\n') ;
fprintf('V_effective            = 944.5 L\n') ;
