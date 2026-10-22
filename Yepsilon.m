function Yepsilon = Yepsilon(epsilon_alpha)
%YEPSILON Contact-ratio factor for tooth-root stress
% according to VDI 2736
%
% Input:
%   epsilon_alpha - transverse contact ratio [-]
%
% Output:
%   Yepsilon      - contact-ratio factor [-]


Yepsilon = .25 +.75/ epsilon_alpha;

end