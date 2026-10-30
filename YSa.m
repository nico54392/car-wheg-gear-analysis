function [YSa, method_info] = YSa(s_Fn, h_Fa, rho_F, member_type)
%YSA Tooth-root stress-correction factor using the DIN 3990-3 equation.
% Formula: DYK Eq. 4; VDI2 p.13 fn. 6 allows DIN 3990-3 (VDI 2737 for internal).
% For an internal ring, this is an explicit project approximation. VDI 2736
% points to VDI 2737 for internal toothings; the DIN equation here does not
% model VDI 2737 gear-rim influence.
%
% Inputs:
%   s_Fn - tooth-root thickness at critical section [m]
%   h_Fa - bending arm [m]
%   rho_F - root fillet radius at critical section [m]
%   member_type - 'external' (default) or 'internal_approximation'
%
% Output:
%   YSa - stress-correction factor [-]

if nargin < 4 || isempty(member_type)
    member_type = 'external';
end

if ~ischar(member_type)
    error('member_type must be ''external'' or ''internal_approximation''.');
end

member_type = lower(strtrim(member_type));
if ~any(strcmp(member_type, {'external', 'internal_approximation'}))
    error('member_type must be ''external'' or ''internal_approximation''.');
end

if s_Fn <= 0
    error('s_Fn must be greater than zero.');
end

if h_Fa <= 0
    error('h_Fa must be greater than zero.');
end

if rho_F <= 0
    error('rho_F must be greater than zero.');
end

L_a = s_Fn / h_Fa;
q_s = s_Fn / (2 * rho_F);

if q_s < 1 || q_s >= 8
    warning('q_s = %.3f is outside the recommended range 1 <= q_s < 8.', q_s);
end

YSa = (1.2 + 0.13 * L_a) ...
    * q_s^(1 / (1.21 + 2.3 / L_a));

method_info.equation = 'DIN 3990-3 analytic YSa equation';
method_info.member_type = member_type;
method_info.vdi2737_applied = false;
if strcmp(member_type, 'internal_approximation')
    method_info.is_project_approximation = true;
    method_info.note = ['Approximation for internal ring tooth: VDI 2737 ' ...
        'rim effects and internal-gear-specific stress treatment are not included.'];
else
    method_info.is_project_approximation = false;
    method_info.note = ['External-tooth application using the DIN 3990-3 ' ...
        'analytic equation; geometry inputs must match the actual tooth form.'];
end

end
