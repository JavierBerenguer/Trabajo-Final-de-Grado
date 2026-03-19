clear,clc,close all
%% Example 9.5. Levenspiel, page 231
% Previous operations to obtain kinetic data
Rg = 8.314 ;
T   = [298 338] ; %K
Xeq = [0.993 0.891] ;
t   = [10 1] ; %min
X   = [0.6 0.581];
k1  = zeros(1,length(T)) ;
k2  = zeros(1,length(T)) ;
for i = 1:length(T)
    k1(i) = 1/t(i)*(-Xeq(i))*log(1-X(i)/Xeq(i)) ;
    Keq = Xeq(i)/(1-Xeq(i)) ;
    k2(i) = k1(i)/Keq ;
end
Ea(1) = log(k1(1)/k1(2)) * -Rg/(1/T(1) - 1/T(2)) ;
Ea(2) = log(k2(1)/k2(2)) * -Rg/(1/T(1) - 1/T(2)) ;
k0(1) = k1(1)/exp(-Ea(1)/Rg/T(1)) ;
k0(2) = k2(1)/exp(-Ea(2)/Rg/T(1)) ;
% Definition of the parameters of the reactive system
RS = ReactionSys ;
RS.componentNames       = {'A' , 'R'} ;
RS.stochiometricMatrix  = [-1 1;1 -1] ;
RS.DHref                = [-75300 , 75300] ; %J/mol
RS.k0                   = k0 ;
RS.k0_units             = 'min^-1' ;
RS.Ea                   = Ea ;
keyComponentIndex = 1 ;

% Definition of the feed and product streams
Feed               = Stream ;
Feed.phase         = 'L' ;
Feed.concentration = [4 0] ; % mol/L
Feed.molarFlow = [1000 0] ; % mol/min
Feed.volumetricFlow = Feed.molarFlow(1)/Feed.concentration(1) ; % L
Feed.P = 101325 ;
Feed.T = 273.15 + 25 ; %K

desiredConversion   = 0.8 ;
extent              = Feed.molarFlow(keyComponentIndex)*desiredConversion/(-RS.stochiometricMatrix(1,keyComponentIndex)) ;
Product             = Feed ;
Product.molarFlow   = Feed.molarFlow + RS.stochiometricMatrix(1,:)*extent ;

R = PFR ;
R.heatMode = 'Isothermal' ;
R.heatMode = 'Other' ;


%% Check the function @find_optimalTemperaturePath works properly
[minimumTime,minimumVolume] = find_optimalTemperaturePath(Feed,Product,R,RS,keyComponentIndex)