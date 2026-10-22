function K_H = KH(gear_results, gear)
% KH
% VDI 2736 tooth-flank load factor for thermoplastic gears.
%
% For b/m <= 12, VDI 2736 permits a simplified empirical
% range of approximately 1.0 to 1.25.
%
% ASSUMPTION:
% K_H = 1.25 is the conservative simplified VDI 2736 value.
% This does not explicitly model planetary load sharing.
%% Gear proportions

m = gear.mod;       % [mm]
b = gear.b_p;       % [mm]

b_over_m = b / m;

%% VDI 2736 simplified load factor

if b_over_m <= 12
    K_H = 1.25;
else
    error('KH: b/m = %.2f exceeds the simplified VDI 2736 range.', ...
        b_over_m);
end

end