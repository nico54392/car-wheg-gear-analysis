function Yepsilon = Yepsilon(epsilon_alpha)
%YEPSILON Contact-ratio factor for tooth-root stress
% according to VDI 2736
%
% Input:
%   epsilon_alpha - transverse contact ratio [-]
%
% Output:
%   Yepsilon      - contact-ratio factor [-]


Yepsilon = .25 +.75/ epsilon_alpha;   % VDI2 Eq. 11, p.13 (also DYK Eq. 5)

end