function geom = geometry_calc(p)
%GEOMETRY_CALC Single source for planetary pitch geometry.
% Inputs use module in mm and tooth counts; output pitch dimensions include
% both mm (legacy/display) and m (calculation) fields.

if isfield(p,'mod')
    m = p.mod;
elseif isfield(p,'m')
    m = p.m;
else
    error('Supply module as p.mod or p.m in mm.');
end
if isfield(p,'N_r1_i')
    N_r = p.N_r1_i;
elseif isfield(p,'N_r')
    N_r = p.N_r;
else
    error('Supply inner-ring tooth count as p.N_r1_i or p.N_r.');
end
if m <= 0 || any([p.N_s,p.N_p,N_r] <= 0)
    error('Module and tooth counts must be positive.');
end

% Standard involute profile-shift geometry (spur gears only in this model).
x_s = field_or_default(p,'x_s',0);
x_p = field_or_default(p,'x_p',0);
x_r = field_or_default(p,'x_r1',0);
alpha_n = field_or_default(p,'alpha',20*pi/180);
beta = field_or_default(p,'beta',0);
if any(~isfinite([x_s,x_p,x_r,alpha_n,beta])) || ...
        any([alpha_n,beta] < 0) || alpha_n >= pi/2
    error('geometry_calc:InvalidAngleOrShift','Angles and shifts must be finite; 0 <= alpha < pi/2.');
end
if abs(beta) > 1e-12 && any(abs([x_s,x_p,x_r]) > 0)
    error('geometry_calc:ShiftedHelicalUnsupported', ...
        'Profile-shifted helical planetary geometry is not implemented.');
end
alpha_t = atan(tan(alpha_n)/cos(beta));
shift_sum_sp = x_s + x_p;
shift_sum_rp = x_r - x_p;
if abs(shift_sum_sp-shift_sum_rp) > 1e-10
    error('geometry_calc:ShiftClosure', ...
        'For planetary closure require x_s + x_p = x_r - x_p.');
end

geom.module_mm = m;
geom.r_s = p.N_s*m/2;
geom.r_p = p.N_p*m/2;
geom.r_r = N_r*m/2;
geom.d_s = 2*geom.r_s;
geom.d_p = 2*geom.r_p;
geom.d_r = 2*geom.r_r;
geom.a = geom.r_s + geom.r_p;
geom.planetary_error = geom.r_r - geom.r_s - 2*geom.r_p;   % closure z_r = z_s + 2z_p, KG p.117
geom.r_s_m = geom.r_s*1e-3;
geom.r_p_m = geom.r_p*1e-3;
geom.r_r_m = geom.r_r*1e-3;
geom.d_s_m = geom.d_s*1e-3;
geom.d_p_m = geom.d_p*1e-3;
geom.d_r_m = geom.d_r*1e-3;
geom.a_m = geom.a*1e-3;

% Working pressure angles from involute compatibility (KG p.30, VDI2 p.22). The external-mesh
% shift sum is x_s+x_p; the internal-mesh sum is x_r-x_p. These equations
% are pressure-angle dependent and do not assume a particular standard angle.
inv_alpha_t = tan(alpha_t)-alpha_t;
alpha_w_sp = invert_involute(inv_alpha_t + ...
    2*tan(alpha_t)*shift_sum_sp/(p.N_s+p.N_p));
alpha_w_rp = invert_involute(inv_alpha_t + ...
    2*tan(alpha_t)*shift_sum_rp/(N_r-p.N_p));
a_sp_ref_m = geom.a_m;
a_rp_ref_m = (geom.r_r-geom.r_p)*1e-3;
geom.alpha_t = alpha_t;
geom.alpha_w_sp = alpha_w_sp;
geom.alpha_w_rp = alpha_w_rp;
geom.a_sp_m = a_sp_ref_m*cos(alpha_t)/cos(alpha_w_sp);
geom.a_rp_m = a_rp_ref_m*cos(alpha_t)/cos(alpha_w_rp);
geom.a_sp_mm = geom.a_sp_m*1e3;
geom.a_rp_mm = geom.a_rp_m*1e3;
geom.r_sw_m = geom.r_s_m*cos(alpha_t)/cos(alpha_w_sp);
geom.r_pw_sp_m = geom.r_p_m*cos(alpha_t)/cos(alpha_w_sp);
geom.r_pw_rp_m = geom.r_p_m*cos(alpha_t)/cos(alpha_w_rp);
geom.r_rw_m = geom.r_r_m*cos(alpha_t)/cos(alpha_w_rp);
geom.profile_shift_s = x_s;
geom.profile_shift_p = x_p;
geom.profile_shift_r = x_r;
geom.profile_shift_sum_sp = shift_sum_sp;
geom.profile_shift_sum_rp = shift_sum_rp;

% Ideal full-depth rack undercut screening for external gears only.
% x_min = 1 - z*sin(alpha)^2/2, i.e. (17 - z)/17 at 20 deg (KG p.30).
geom.x_min_undercut_s = 1-p.N_s*sin(alpha_n)^2/2;
geom.x_min_undercut_p = 1-p.N_p*sin(alpha_n)^2/2;
geom.sun_undercut_shift_margin = x_s-geom.x_min_undercut_s;
geom.planet_undercut_shift_margin = x_p-geom.x_min_undercut_p;
geom.sun_undercut_screen_pass = geom.sun_undercut_shift_margin >= 0;
geom.planet_undercut_screen_pass = geom.planet_undercut_shift_margin >= 0;
geom.external_undercut_screen_pass = ...
    geom.sun_undercut_screen_pass && geom.planet_undercut_screen_pass;

% Full-depth basic-rack addenda/dedenda with standard profile-shift signs
% (basic rack h_aP = 1.0m, h_fP = 1.25m, KG p.11).
% External: ha=(1+x)m, hf=(1.25-x)m. Internal: ha=(1-x)m,
% hf=(1.25+x)m. These nominal circles do not model a specific cutter tip.
geom.addendum_s = m*(1+x_s);
geom.addendum_p = m*(1+x_p);
geom.addendum_r = m*(1-x_r);
geom.dedendum_s = m*(1.25-x_s);
geom.dedendum_p = m*(1.25-x_p);
geom.dedendum_r = m*(1.25+x_r);
geom.r_s_outer = geom.r_s + geom.addendum_s;
geom.r_p_outer = geom.r_p + geom.addendum_p;
geom.r_r_tooth_tip = geom.r_r - geom.addendum_r;
geom.r_r_outer = geom.r_r + geom.dedendum_r;
geom.r_s_root = geom.r_s - geom.dedendum_s;
geom.r_p_root = geom.r_p - geom.dedendum_p;
geom.r_r_root = geom.r_r + geom.dedendum_r;
geom.sun_planet_ratio = geom.r_s/geom.r_p;
geom.ring_sun_ratio = geom.r_r/geom.r_s;
geom.ring_planet_ratio = geom.r_r/geom.r_p;
geom.gear_radius = geom.r_r_outer*1e-3;
geom.gear_diameter = 2*geom.gear_radius;
if isfield(p,'housing_radius')
    geom.radial_clearance = p.housing_radius-geom.gear_radius;
else
    geom.radial_clearance = NaN;
end
for name = {'gear_width','planet_width','axial_clearance'}
    if isfield(p,name{1})
        geom.(name{1}) = p.(name{1});
    else
        geom.(name{1}) = NaN;
    end
end
if isfield(p,'theta_deg')
    geom.theta = deg2rad(p.theta_deg);
elseif isfield(p,'theta')
    geom.theta = p.theta;
else
    geom.theta = 0;
end
geom.sin_theta = sin(geom.theta);
geom.cos_theta = cos(geom.theta);

geom.valid_planetary_geometry = abs(geom.planetary_error) <= 1e-9 && ...
    abs(geom.a_sp_m-geom.a_rp_m) <= 1e-9;
if isfield(p,'N_p_planets')
    geom.N_p_planets = p.N_p_planets;
    if p.N_p_planets < 1 || p.N_p_planets ~= floor(p.N_p_planets)
        error('p.N_p_planets must be a positive integer.');
    end
    geom.valid_planet_phasing = mod(p.N_s + N_r,p.N_p_planets) == 0;   % KG p.117
else
    geom.N_p_planets = NaN;
    geom.valid_planet_phasing = NaN;
end

% Optional wheel/package fields retained for callers of the earlier helper.
if isfield(p,'R_wheel') && isfield(p,'R_open')
    geom.R_closed = p.R_wheel;
    geom.R_open = p.R_open;
    geom.D_closed = 2*p.R_wheel;
    geom.D_open = 2*p.R_open;
    geom.delta_R = p.R_open-p.R_wheel;
    geom.radius_ratio = p.R_open/p.R_wheel;
    geom.wheel_to_gear_ratio = p.R_wheel/(geom.r_r_outer*1e-3);
    geom.valid_wheel_geometry = p.R_wheel > 0 && p.R_open >= p.R_wheel;
else
    geom.R_closed = NaN;
    geom.R_open = NaN;
    geom.valid_wheel_geometry = NaN;
end
geom.radial_displacement = geom.R_open-geom.R_closed;
end

function alpha = invert_involute(target)
% Solve inv(alpha)=tan(alpha)-alpha by bisection.
if ~isfinite(target) || target < 0
    error('geometry_calc:InvalidWorkingAngle','Shift set produces invalid involute value.');
end
lo = 0;
hi = pi/2-1e-10;
if target >= tan(hi)-hi
    error('geometry_calc:InvalidWorkingAngle','Working pressure angle is outside the involute range.');
end
for k = 1:80
    mid = (lo+hi)/2;
    if tan(mid)-mid < target, lo = mid; else, hi = mid; end
end
alpha = (lo+hi)/2;
end

function value = field_or_default(s,name,default)
if isfield(s,name) && ~isempty(s.(name)), value = s.(name); else, value = default; end
end
