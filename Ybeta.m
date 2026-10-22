function Ybeta = Ybeta(beta)
%YBETA Helix-angle factor for tooth-root stress
% according to VDI 2736
%
% Input:
%   beta   - helix angle [rad]
%
% Output:
%   Ybeta  - helix-angle factor [-]

% ASSUMPTION:
% Current planetary architecture uses spur gears.
% Therefore beta = 0 and Ybeta = 1.

if abs(beta) < 1e-12
    Ybeta = 1;
else
    error(['Nonzero helix angle requires the corresponding ', ...
           'VDI 2736 expression to be implemented.']);
end

end