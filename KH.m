function K_H = KH(gear_results, gear)
% KH  VDI 2736 Blatt 2 tooth-flank load factor for thermoplastic gears.
%
% VDI 2736-2 (p. 17): K_H = K_A*K_v*K_beta*K_alpha, and for b/m <= 12 the
% standard simplifies this to K_H ~ K_A because of the plastic's elasticity.
% So this just returns gear.K_A. Any extra conservatism belongs in K_A
% (set in main.m), not hidden here.
%
% Equal planet load sharing is assumed elsewhere; this factor does not
% cover planet-to-planet load imbalance.

b_over_m = gear.b_p / gear.mod;
if b_over_m > 12
    error('KH: b/m = %.2f exceeds the b/m <= 12 range of the VDI simplification.', b_over_m);
end

K_H = gear.K_A;

end
