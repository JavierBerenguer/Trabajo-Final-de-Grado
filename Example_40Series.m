clear, close, clc

%% Example 40 Unit 4: Association of reactors. Reactor Desing I.
% 
% The irreversible gas phase reaction A + B ® C is performed at 227°C and 10 atm. The
% reaction rate (mol/(L·min)) in terms of the conversion is:
% r_A = 0.0167 ? 0.023(XA ? 0.1)+ 0.0234(XA? 0.1)(XA ? 0.7)
% A feeding of 1 L/s containing 41% A, 41% B and 18% inerts (in molar basis) is going to be
% processed.
% a) What is the total conversion if two continuous stirred tank reactors of 400 L each are
% connected in series?
% b) What is the conversion if the two previous reactors are connected in parallel, with a
% volumetric flow rate entering each one being half of the initial?
% c) What is the volume of the plug flow reactor necessary to achieve a conversion of 0.6 if
% the total molar flow of feeding is 2 mol/min, being the composition of the feeding the
% same as in previous cases?
%
% Source: Department of Chemical Engineering, University of Alicante.

global Feed 

RS = ReactionSys ;
RS.stochiometricMatrix = [-1 -1 1 0] ; % A B C Inerts
RS.userDefinedKinetics = @(concentration,T) userDefinedKinetics(concentration,T) ;

Feed = Stream ;
Feed.phase = 'G' ;
Feed.volumetricFlow = 1/1000 ; %m^3/s
Feed.P = 10*101325 ; % Pa
Feed.T = 227 + 273.15 ; %K
Feed.molarFlow = (Feed.P*Feed.volumetricFlow/8.314/Feed.T) * [0.41 0.41 0 0.18] ; %mol/s

R = CSTR ;
R.V = 400/1000 ; % m^3 
R.heatMode = 'Isothermal' ;
%% Solve question a and b
sequence1 = {R,R} ;
auxReactorObj = Reactor ;
[Product1 sequence1] = compute_parallel(auxReactorObj,Feed,RS,sequence1) ; 
XA = (Feed.molarFlow(1) - Product1.molarFlow(1))/Feed.molarFlow(1) ;

%% Kinetics
function r_i = userDefinedKinetics(concentration,T)
global Feed

cA = concentration(1) ; 
nA0 = Feed.molarFlow(1) ;
Qv0 = Feed.volumetricFlow ; 
P = 10* 101325 ; %Pa
T = 227+273.15 ; %K

XA = (cA*Qv0-nA0)*Feed.P/(nA0*(cA*8.314*Feed.T-Feed.P)) ;

r_i = 0.0167 - 0.023* (XA-0.1) + 0.0234*(XA-0.1)*(XA-0.7) ; %mol/L/min
r_i = r_i * 1000/60 ; %mol/m^3/s
end