function K_F = KF(gear_results, gear)
% KF  VDI 2736 Blatt 2 tooth-root load factor for thermoplastic gears.
%
% VDI 2736-2 (p. 11): K_F = K_A*K_v*K_beta*K_alpha, and for b/m <= 12 the
% standard simplifies this to K_F ~ K_A because of the plastic's elasticity.
% So this just returns gear.K_A. Any extra conservatism belongs in K_A
% (set in main.m), not hidden here.
%
% Equal planet load sharing is assumed elsewhere; this factor does not
% cover planet-to-planet load imbalance.

b_over_m = gear.b_p / gear.mod;   % VDI2 p.11 / p.17: K ~ K_A for b/m <= 12
if b_over_m > 12
    error('KF: b/m = %.2f exceeds the b/m <= 12 range of the VDI simplification.', b_over_m);
end

K_F = gear.K_A;

end
