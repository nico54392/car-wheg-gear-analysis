function ZH = ZH(alpha_t, alpha_wt, beta_b)
%ZH Zone factor used by the VDI 2736 flank-stress equation.
% The factor equation is the ISO 6336-2:2006 Eq. 16 form, also identified
% by VDI 2736 Blatt 2 p. 16 as a DIN 3990-derived factor. This is only the
% zone-factor relation; it does not make the complete rating an ISO rating.
% Inputs are transverse pressure angles and base helix angle [rad].
if nargin < 2 || isempty(alpha_wt), alpha_wt = alpha_t; end
if nargin < 3 || isempty(beta_b), beta_b = 0; end
if any([alpha_t,alpha_wt] <= 0) || any([alpha_t,alpha_wt] >= pi/2)
    error('ZH: pressure angles must be between 0 and pi/2 radians.');
end
ZH = sqrt((2*cos(beta_b)*cos(alpha_wt)) / ...
    (cos(alpha_t)^2*sin(alpha_wt)));
end
