function wear = gear_wear(vdi_c,vdi_o,gear_results_c,gear_results_o,gear,inputs)
%GEAR_WEAR Back-calculate planetary wear life from VDI 2736 Blatt 2 Eqs. 19, 21.
% Average wear only; local sliding wear is intentionally omitted.
% One mesh uses the per-planet transmitted force and torque. For sun/ring,
% cycles per tooth include all three planet mesh locations. Each representative
% planet tooth sees one cycle per relative spin revolution in each mesh.
% k_w_1e6 is the numeric coefficient in units 1e-6 mm^3/(N*m).
if nargin < 6, inputs = struct(); end
required = {'k_w_1e6','fraction_closed','fraction_open','hours_per_day','days_per_year','design_years'};
for i = 1:numel(required)
    if ~isfield(inputs,required{i}) || ~isscalar(inputs.(required{i})) || ~isfinite(inputs.(required{i}))
        error('gear_wear:MissingInput','Missing finite scalar wear input: %s',required{i});
    end
end
if inputs.k_w_1e6 < 0 || inputs.hours_per_day <= 0 || inputs.days_per_year <= 0 || inputs.design_years <= 0
    error('gear_wear:InvalidInput','Coefficient must be nonnegative; use positive life/time inputs.');
end
if abs(inputs.fraction_closed + inputs.fraction_open - 1) > 1e-8 || ...
        inputs.fraction_closed < 0 || inputs.fraction_open < 0
    error('gear_wear:InvalidDutySplit','Closed and open fractions must be nonnegative and sum to 1.');
end
m = gear.mod; % mm
names = {'sun','planet_sp','planet_rp','ring'};
z = [gear.N_s,gear.N_p,gear.N_p,gear.N_r1_i];
bw_mm = [vdi_c.b_sp,vdi_c.b_sp,vdi_c.b_rp,vdi_c.b_rp]*1e3;
HV_c = [vdi_c.H_V_sp,vdi_c.H_V_sp,vdi_c.H_V_rp,vdi_c.H_V_rp];
HV_o = [vdi_o.H_V_sp,vdi_o.H_V_sp,vdi_o.H_V_rp,vdi_o.H_V_rp];
Ft_c = [vdi_c.F_t_sp,vdi_c.F_t_sp,vdi_c.F_t_rp,vdi_c.F_t_rp];
Ft_o = [vdi_o.F_t_sp,vdi_o.F_t_sp,vdi_o.F_t_rp,vdi_o.F_t_rp];
planets = gear.N_p_planets;
omega_c = gear_results_c.omega_o_1;
omega_o = gear_results_o.omega_o_1;

% VDI footnote approximation retained unless the user supplies l_FI per member.
wear.members = struct();
wear.k_w_1e6 = inputs.k_w_1e6;
wear.k_w = inputs.k_w_1e6*1e-6;
wear.k_w_unit = 'mm^3/(N*m)';
wear.k_w_provisional = true;
if isfield(inputs,'k_w_source'), wear.k_w_source = inputs.k_w_source;
else, wear.k_w_source = 'provisional value'; end
wear.k_w_scope = 'PA12/PA12 SLS dry-gear microscopy coefficient; source PV range 9.2-11.03 MPa*m/s';
wear.equations = 'VDI 2736 Blatt 2, Eqs. (19) and (21)';
wear.permissible_mm = [0.1,0.2]*m;   % VDI2 Eq. 21, p.19
wear.duty = inputs;
wear.design_hours = inputs.hours_per_day*inputs.days_per_year*inputs.design_years;
wear.design_years = inputs.design_years;
wear.days_per_year = inputs.days_per_year;
wear.hours_per_day = inputs.hours_per_day;
wear.note = ['Provisional average-wear life using the upper VDI wear limit range; ' ...
    'actual service PV, print process, and material condition may differ from source tests.'];

for i = 1:numel(names)
    name = names{i};
    lFI = 2*m;   % VDI2 p.19 footnote 13
    if isfield(inputs,'l_FI_mm') && isstruct(inputs.l_FI_mm) && isfield(inputs.l_FI_mm,name) && ...
            isscalar(inputs.l_FI_mm.(name)) && isfinite(inputs.l_FI_mm.(name))
        lFI = inputs.l_FI_mm.(name);
        lFI_source = 'user supplied';
    else
        lFI_source = 'VDI footnote approximation l_FI=2*m_n';
    end
    % One mesh torque (not the three-mesh system total): equal sharing is
    % represented by per-planet force; planetary mesh counts are applied below.
    Td_c = Ft_c(i)*(z(i)*m*1e-3/2);
    Td_o = Ft_o(i)*(z(i)*m*1e-3/2);
    if i == 1
        cycles_per_hour_c = planets*abs(gear_results_c.omega_s-omega_c)/(2*pi)*3600;
        cycles_per_hour_o = planets*abs(gear_results_o.omega_s-omega_o)/(2*pi)*3600;
    elseif i == 4
        % Fixed ring teeth are loaded as each planet passes; ring speed is zero.
        cycles_per_hour_c = planets*abs(omega_c)/(2*pi)*3600;
        cycles_per_hour_o = planets*abs(omega_o)/(2*pi)*3600;
    else
        cycles_per_hour_c = abs(gear_results_c.omega_p1_rel)/(2*pi)*3600;
        cycles_per_hour_o = abs(gear_results_o.omega_p1_rel)/(2*pi)*3600;
    end
    factor = 2*pi*(inputs.k_w_1e6*1e-6)/(bw_mm(i)*z(i)*lFI);
    rate_c = Td_c*HV_c(i)*factor*cycles_per_hour_c;
    rate_o = Td_o*HV_o(i)*factor*cycles_per_hour_o;
    rate_mix = inputs.fraction_closed*rate_c + inputs.fraction_open*rate_o;
    Wzul_lo = wear.permissible_mm(1);
    Wzul_hi = wear.permissible_mm(2);
    result.T_d_closed_Nm = Td_c;
    result.T_d_open_Nm = Td_o;
    result.b_w_mm = bw_mm(i);
    result.z = z(i);
    result.H_V_closed = HV_c(i);
    result.H_V_open = HV_o(i);
    result.l_FI_mm = lFI;
    result.l_FI_source = lFI_source;
    result.N_L_per_hour_closed = cycles_per_hour_c;
    result.N_L_per_hour_open = cycles_per_hour_o;
    result.W_rate_mm_per_hour_closed = rate_c;
    result.W_rate_mm_per_hour_open = rate_o;
    result.W_rate_mm_per_hour_mixed = rate_mix;
    result.N_L_per_hour_mixed = inputs.fraction_closed*cycles_per_hour_c + ...
        inputs.fraction_open*cycles_per_hour_o;
    result.W_after_design_life_mm = rate_mix*wear.design_hours;
    if rate_mix > 0
        result.life_to_Wzul_low_hours = Wzul_lo/rate_mix;
        result.life_to_Wzul_high_hours = Wzul_hi/rate_mix;
        result.life_to_Wzul_low_years = result.life_to_Wzul_low_hours/(inputs.hours_per_day*inputs.days_per_year);
        result.life_to_Wzul_high_years = result.life_to_Wzul_high_hours/(inputs.hours_per_day*inputs.days_per_year);
        result.N_L_to_Wzul_low = result.N_L_per_hour_mixed*result.life_to_Wzul_low_hours;
        result.N_L_to_Wzul_high = result.N_L_per_hour_mixed*result.life_to_Wzul_high_hours;
        result.life_status = 'provisional';
    else
        result.life_to_Wzul_low_hours = Inf;
        result.life_to_Wzul_high_hours = Inf;
        result.life_to_Wzul_low_years = Inf;
        result.life_to_Wzul_high_years = Inf;
        result.N_L_per_hour_mixed = 0;
        result.N_L_to_Wzul_low = Inf;
        result.N_L_to_Wzul_high = Inf;
        result.life_status = 'zero_wear_rate';
    end
    wear.members.(name) = result;
end

lowLife = zeros(1,numel(names));
highLife = zeros(1,numel(names));
for i = 1:numel(names)
    memberResult = wear.members.(names{i});
    lowLife(i) = memberResult.life_to_Wzul_low_hours;
    highLife(i) = memberResult.life_to_Wzul_high_hours;
end
[wear.governing_low_limit_hours,idxLo] = min(lowLife);
[wear.governing_high_limit_hours,idxHi] = min(highLife);
wear.governing_member_low_limit = names{idxLo};
wear.governing_member_high_limit = names{idxHi};
wear.governing_low_limit_years = wear.governing_low_limit_hours/(inputs.hours_per_day*inputs.days_per_year);
wear.governing_high_limit_years = wear.governing_high_limit_hours/(inputs.hours_per_day*inputs.days_per_year);
wear.within_5y_limit_low = all(arrayfun(@(i) wear.members.(names{i}).W_after_design_life_mm <= wear.permissible_mm(1),1:numel(names)));
wear.within_5y_limit_high = all(arrayfun(@(i) wear.members.(names{i}).W_after_design_life_mm <= wear.permissible_mm(2),1:numel(names)));
end
