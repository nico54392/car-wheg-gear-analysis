function Zbeta = Zbeta(beta)
%ZBETA Helix-angle factor for flank/contact stress
% according to VDI 2736
%
% Input:
%   beta   - helix angle [rad]
%
% Output:
%   Zbeta  - helix-angle factor [-]

if abs(beta) < 1e-12
    Zbeta = 1;
else
    error(['Nonzero helix angle requires the corresponding ', ...
           'VDI 2736 expression to be implemented.']);
end

end