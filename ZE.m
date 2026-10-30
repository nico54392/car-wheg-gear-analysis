function ZE = ZE(E1, nu1, E2, nu2)
%ZE Elasticity factor according to VDI 2736, VDI2 Eq. 15, p.15
%
% Inputs:
%   E1  - Young's modulus of gear 1 [Pa]
%   nu1 - Poisson's ratio of gear 1 [-]
%   E2  - Young's modulus of gear 2 [Pa]
%   nu2 - Poisson's ratio of gear 2 [-]
%
% Output:
%   ZE  - Elasticity factor [Pa^0.5]

ZE = sqrt( ...
    1 / (pi * ((1 - nu1^2)/E1 + (1 - nu2^2)/E2)) ...
    );

end