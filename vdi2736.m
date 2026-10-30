function vdi_results = vdi2736(gear_results, gear, geom)

if nargin < 3
    geom = geometry_calc(gear);
end
if ~geom.valid_planetary_geometry
    error('Planetary pitch geometry does not close.');
end

%% ========================================
%          VDI 2736 GEAR ANALYSIS
%
% Meshes:
%   1. Sun - Planet
%   2. Planet - Inner Ring
%
% Factor functions such as ZE, Yepsilon, YFa,
% YSa, ZH, KH, KF, etc. are treated as the
% authoritative VDI implementations.
%
% This function handles:
%   - mesh-specific geometry
%   - planetary operating conditions
%   - mesh forces
%   - relative pitch-line velocities
%   - VDI factors
%   - tooth-root stresses
%   - flank/contact stresses
%   - deformation
%   - thermal-loss inputs
%
% Units:
%   Geometry: SI internally [m]
%   Forces:   [N]
%   Stress:   [Pa]
%   Power:    [W]
%   Velocity: [m/s]
%
% ========================================


%% ========================================
%          GEAR GEOMETRY
% ========================================

m_n = gear.mod * 1e-3;              % [m]
alpha_n = gear.alpha;               % [rad]
beta = gear.beta;                   % [rad]

D_p = geom.d_p_m;                    % [m], canonical geometry_calc output
D_s = geom.d_s_m;
D_r = geom.d_r_m;

b_p = gear.b_p * 1e-3;              % [m]
b_s = gear.b_s * 1e-3;              % [m]
b_r = gear.b_r1 * 1e-3;             % [m]

% Effective face width for each mesh.
b_sp = min(b_s,b_p);
b_rp = min(b_p,b_r); 


%% ========================================
%          TOOTH COUNTS
% ========================================

N_s = gear.N_s;
N_p = gear.N_p;
N_r = gear.N_r1_i;

N_p_planets = gear.N_p_planets;


%% ========================================
%          MATERIAL PROPERTIES
% ========================================

E_s = gear.E_s;
E_p = gear.E_p;
E_r = gear.E_r;

nu_s = gear.nu_s;
nu_p = gear.nu_p;
nu_r = gear.nu_r1;


%% ========================================
%          OPERATING CONDITIONS
% ========================================

% Absolute angular velocities
omega_s = gear_results.omega_s;
omega_p = gear_results.omega_p1_wld;
omega_r = gear_results.omega_r1;
omega_c = gear_results.omega_o_1;

% Relative angular velocities with respect to carrier
omega_s_rel = omega_s - omega_c;
omega_p_rel = gear_results.omega_p1_rel;
omega_r_rel = omega_r - omega_c;

% Torques
T_s = gear_results.T_s;
T_r = gear_results.T_r1;

if isfield(gear_results,'T_c')
    T_c = gear_results.T_c;
elseif isfield(gear_results,'P_c') && abs(omega_c) > eps
    T_c = gear_results.P_c / omega_c;
else
    T_c = NaN;
end


%% ========================================
%          MESH FORCES
% ========================================

% Tangential force carried by ONE planet.
%
% planetary_gear is responsible for determining
% how the total planetary load is distributed
% among the planets.

if gear_results.N_p_planets ~= N_p_planets
    error('Planet count differs between gear and planetary results.');
end
% VDI Eq. (2)/(10): rating force is taken at the REFERENCE diameter d,
% not the working pitch diameter. planetary_gear returns the working-circle
% force, which is kept for mesh power (F_w*v_w = F_ref*v_ref anyway).
F_t_sp_w = abs(gear_results.F_t_s_planet);
F_t_rp_w = abs(gear_results.F_t_r_planet);
F_t_sp = abs(T_s)/geom.r_s_m/N_p_planets;
F_t_rp = abs(T_r)/geom.r_r_m/N_p_planets;

% Total tangential force across all planets.

F_t_sp_total = N_p_planets * F_t_sp;
F_t_rp_total = N_p_planets * F_t_rp;


%% ========================================
%          PITCH-LINE VELOCITIES
% ========================================

% Absolute pitch-line velocities

v_s_abs = abs(omega_s) * geom.r_sw_m;
v_p_abs = abs(omega_p) * geom.r_pw_sp_m;
v_r_abs = abs(omega_r) * geom.r_rw_m;

% Relative pitch-line velocities.
%
% VDI mesh calculations for a planetary gear are based
% on the relative motion of the gears with respect to
% the carrier.

v_s_rel = abs(omega_s_rel) * geom.r_sw_m;
v_p_rel = abs(omega_p_rel) * geom.r_pw_sp_m;
v_r_rel = abs(omega_r_rel) * geom.r_rw_m;

% Mesh pitch-line velocities.
%
% For a correctly meshing planetary system, the two
% members of each mesh have the same pitch-line velocity
% magnitude in the carrier frame.

v_sp = v_s_rel;
v_rp = v_r_rel;


%% ========================================
%          MESH RATIOS
% ========================================

% DIN/VDI contact-stress ratio convention: z2/z1 >= 1, with z1 the
% smaller gear. The ratio/d1 term is invariant to swapping the pair.
u_sp = max(N_p,N_s) / min(N_p,N_s);
u_rp = N_r / N_p;


%% ========================================
%          BASIC TOOTH GEOMETRY
% ========================================

alpha_t = atan(tan(alpha_n) / cos(beta));   % VDI2 p.21

r_s = geom.r_s_m;
r_p = geom.r_p_m;
r_r = geom.r_r_m;

r_bs = r_s * cos(alpha_t);                   % d_b = d*cos(alpha_t), VDI2 p.21
r_bp = r_p * cos(alpha_t);
r_br = r_r * cos(alpha_t);


%% ========================================
%          PROFILE-SHIFT VALUES
% ========================================

x_s = gear.x_s;
x_p = gear.x_p;
x_r = gear.x_r1;


%% ========================================
%          ADDENDUM RADII
% ========================================

% Standard reference geometry with profile shift.
%
% External gear:
%   da = d + 2*m*(1+x)
%
% Internal gear (same convention as geometry_calc, where the internal
% mesh shift sum is x_r - x_p):
%   da = d - 2*m*(1-x)

r_as = r_s + m_n*(1 + x_s);
r_ap = r_p + m_n*(1 + x_p);
r_ar = r_r - m_n*(1 - x_r);

if r_ar <= r_br
    error('Ring tip circle (%.3f mm) is inside its base circle (%.3f mm).', ...
        r_ar*1e3, r_br*1e3);
end


%% ========================================
%       SUN - PLANET CONTACT RATIO
% ========================================

a_sp = geom.a_sp_m;

arg_wt_sp = ((r_s+r_p)*cos(alpha_t))/a_sp;
if abs(arg_wt_sp) > 1+1e-10
    error('Sun-planet working pressure-angle geometry is impossible.');
end
alpha_wt_sp = acos(max(-1,min(1,arg_wt_sp)));
pb_t = pi*m_n*cos(alpha_t);                  % base pitch
A_s = sqrt(max(r_as^2-r_bs^2,0));
A_p = sqrt(max(r_ap^2-r_bp^2,0));
% VDI 2736-2 p.22: eps_i = z_i/(2*pi)*(sqrt((d_a/d_b)^2-1) - tan(alpha_wt))
% i.e. (sqrt(r_a^2-r_b^2) - r_b*tan(alpha_wt))/p_bt
epsilon1_sp = (A_s-r_bs*tan(alpha_wt_sp))/pb_t;
epsilon2_sp = (A_p-r_bp*tan(alpha_wt_sp))/pb_t;
epsilon_alpha_sp = epsilon1_sp + epsilon2_sp;


%% ========================================
%       PLANET - RING CONTACT RATIO
% ========================================

a_rp = geom.a_rp_m;

arg_wt_rp = ((r_r-r_p)*cos(alpha_t))/a_rp;
if abs(arg_wt_rp) > 1+1e-10
    error('Planet-ring working pressure-angle geometry is impossible.');
end
alpha_wt_rp = acos(max(-1,min(1,arg_wt_rp)));
A_r = sqrt(max(r_ar^2-r_br^2,0));
epsilon1_rp = (A_p-r_bp*tan(alpha_wt_rp))/pb_t;
epsilon2_rp = (r_br*tan(alpha_wt_rp)-A_r)/pb_t;
epsilon_alpha_rp = epsilon1_rp + epsilon2_rp;

if any([epsilon1_sp,epsilon2_sp,epsilon1_rp,epsilon2_rp] < 0)
    error('Contact path is invalid; check addendum, base-circle, and operating geometry.');
end


%% ========================================
%          HELIX OVERLAP
% ========================================

if abs(beta) < 1e-12

    epsilon_beta_sp = 0;
    epsilon_beta_rp = 0;

else

    error(['Nonzero beta requires the corresponding ', ...
           'VDI 2736 helix-overlap implementation.']);

end


%% ========================================
%       TOOTH ROOT GEOMETRY
% ========================================

% These quantities are passed to the factor functions.
% PLACEHOLDER: one critical section for every gear, taken from the
% standard basic rack (KG p.11, Table 3): tooth thickness pi*m/2 at the
% reference line, dedendum h_fP = 1.25m, tip radius rho_fP = 0.38m.
% Not tooth-count or shift specific; see VDI2 Fig. 1/2 for real values.
% Source IDs (VDI2, KG, DYK, ...) are listed in info/Gear_Parameter_Values_and_Sources.txt.

s_Fn_s = pi*m_n/2;
s_Fn_p = pi*m_n/2;
s_Fn_r = pi*m_n/2;

h_Fa_s = 1.25*m_n;
h_Fa_p = 1.25*m_n;
h_Fa_r = 1.25*m_n;

rho_F_s = 0.38*m_n;
rho_F_p = 0.38*m_n;
rho_F_r = 0.38*m_n;

alpha_Fan_s = alpha_n;
alpha_Fan_p = alpha_n;
alpha_Fan_r = alpha_n;


%% ========================================
%       SUN - PLANET FACTORS
% ========================================

ZE_sp = ZE(E_s,nu_s,E_p,nu_p);

Yepsilon_sp = Yepsilon(epsilon_alpha_sp);

Zepsilon_sp = Zepsilon( ...
    epsilon_alpha_sp, ...
    epsilon_beta_sp);

Ybeta_sp = Ybeta(beta);
Zbeta_sp = Zbeta(beta);

% Sun tooth

YFa_s_sp = YFa( ...
    h_Fa_s, ...
    s_Fn_s, ...
    alpha_Fan_s, ...
    alpha_n, ...
    m_n);

YSa_s_sp = YSa( ...
    s_Fn_s, ...
    h_Fa_s, ...
    rho_F_s);

% Planet tooth

YFa_p_sp = YFa( ...
    h_Fa_p, ...
    s_Fn_p, ...
    alpha_Fan_p, ...
    alpha_n, ...
    m_n);

YSa_p_sp = YSa( ...
    s_Fn_p, ...
    h_Fa_p, ...
    rho_F_p);

beta_b = asin(sin(beta)*cos(alpha_n));
ZH_sp = ZH(alpha_t,alpha_wt_sp,beta_b);


%% ========================================
%       PLANET - RING FACTORS
% ========================================

ZE_rp = ZE(E_p,nu_p,E_r,nu_r);

Yepsilon_rp = Yepsilon(epsilon_alpha_rp);

Zepsilon_rp = Zepsilon( ...
    epsilon_alpha_rp, ...
    epsilon_beta_rp);

Ybeta_rp = Ybeta(beta);
Zbeta_rp = Zbeta(beta);

% Planet tooth

YFa_p_rp = YFa( ...
    h_Fa_p, ...
    s_Fn_p, ...
    alpha_Fan_p, ...
    alpha_n, ...
    m_n);

YSa_p_rp = YSa( ...
    s_Fn_p, ...
    h_Fa_p, ...
    rho_F_p);

% Ring tooth

% VDI2 p.11: approximate internal-ring tooth-form factor.
YFa_r_rp = 2.0;

[YSa_r_rp, YSa_r_method] = YSa( ...
    s_Fn_r, ...
    h_Fa_r, ...
    rho_F_r, ...
    'internal_approximation');

ZH_rp = ZH(alpha_t,alpha_wt_rp,beta_b);


%% ========================================
%       LOAD DISTRIBUTION FACTORS
% ========================================

K_F_sp = KF(gear_results,gear);
K_H_sp = KH(gear_results,gear);

K_F_rp = KF(gear_results,gear);
K_H_rp = KH(gear_results,gear);


%% ========================================
%          TOOTH-ROOT STRESSES
% ========================================

sigma_F_s_sp = ...
    K_F_sp * ...
    YFa_s_sp * ...
    YSa_s_sp * ...
    Yepsilon_sp * ...
    Ybeta_sp * ...
    F_t_sp/(b_sp*m_n);

sigma_F_p_sp = ...
    K_F_sp * ...
    YFa_p_sp * ...
    YSa_p_sp * ...
    Yepsilon_sp * ...
    Ybeta_sp * ...
    F_t_sp/(b_sp*m_n);

sigma_F_p_rp = ...
    K_F_rp * ...
    YFa_p_rp * ...
    YSa_p_rp * ...
    Yepsilon_rp * ...
    Ybeta_rp * ...
    F_t_rp/(b_rp*m_n);

sigma_F_r_rp = ...
    K_F_rp * ...
    YFa_r_rp * ...
    YSa_r_rp * ...
    Yepsilon_rp * ...
    Ybeta_rp * ...
    F_t_rp/(b_rp*m_n);


%% ========================================
%          FLANK / CONTACT STRESSES
% ========================================

sigma_H_sp = ...
    ZE_sp * ...
    ZH_sp * ...
    Zepsilon_sp * ...
    Zbeta_sp * ...
    sqrt( ...
        (F_t_sp*K_H_sp)/(b_sp*min(D_s,D_p)) * ...
        ((u_sp+1)/u_sp));


sigma_H_rp = ...
    ZE_rp * ...
    ZH_rp * ...
    Zepsilon_rp * ...
    Zbeta_rp * ...
    sqrt( ...
        (F_t_rp*K_H_rp)/(b_rp*D_p) * ...
        ((u_rp-1)/u_rp));   % internal mesh: u is negative in DIN 3990, so (u+1)/u -> (|u|-1)/|u|


%% ========================================
%          TOOTH DEFORMATION
% ========================================

% Retained using the current deformation model.
% If this coefficient is part of the factor-function
% audit, it can be replaced independently.

% VDI2 Eq. 22, p.20
lambda_sp = ...
    7.5 * F_t_sp/(b_sp*cos(beta)) * ...
    (1/E_s + 1/E_p);

lambda_rp = ...
    7.5 * F_t_rp/(b_rp*cos(beta)) * ...
    (1/E_p + 1/E_r);


%% ========================================
%          MESH POWER
% ========================================

% Mesh power is calculated using relative pitch-line
% velocity, not absolute gear velocity.

P_sp = F_t_sp_w * v_sp;
P_rp = F_t_rp_w * v_rp;

P_sp_total = N_p_planets * P_sp;
P_rp_total = N_p_planets * P_rp;


%% ========================================
%          INPUT / OUTPUT POWER
% ========================================

P_in = abs(T_s * omega_s);
P_out = abs(T_c * omega_c);

if P_in > eps
    eta = P_out/P_in;
else
    eta = NaN;
end

if abs(omega_s) > eps
    speed_ratio = omega_c/omega_s;
else
    speed_ratio = NaN;
end


%% ========================================
%          THERMAL LOSS FACTOR
% ========================================

% These quantities are retained for the existing
% gear_temperature implementation.

z1_sp = min(N_s,N_p);
z2_sp = max(N_s,N_p);

z1_rp = N_p;
z2_rp = N_r;

epsilon_sp = epsilon_alpha_sp;
epsilon_rp = epsilon_alpha_rp;

% VDI2 Eq. 8, p.10 (sign for internal mesh per DIN 3990 convention)
H_V_sp = ...
    pi*(u_sp + 1) / ...
    (z2_sp*cos(beta)) * ...
    (1 - epsilon1_sp - epsilon2_sp + ...
     epsilon1_sp^2 + epsilon2_sp^2);

% Internal mesh: same DIN sign convention as sigma_H -> (|u|-1).
H_V_rp = ...
    pi*(u_rp - 1) / ...
    (z2_rp*cos(beta)) * ...
    (1 - epsilon1_rp - epsilon2_rp + ...
     epsilon1_rp^2 + epsilon2_rp^2);


% VDI Eq. (8) is only stated for 1 <= eps_alpha <= 2.
for eps_chk = [epsilon_alpha_sp, epsilon_alpha_rp]
    if eps_chk < 1 || eps_chk > 2
        warning('eps_alpha = %.3f is outside the 1..2 range of VDI Eq. (8) for H_V.', eps_chk);
    end
end


%% ========================================
%          SUN - PLANET RESULTS
% ========================================

vdi_results.sun_planet.F_t = F_t_sp;
vdi_results.sun_planet.F_t_total = F_t_sp_total;

vdi_results.sun_planet.v_s = v_s_abs;
vdi_results.sun_planet.v_p = v_p_abs;

vdi_results.sun_planet.omega_s_rel = omega_s_rel;
vdi_results.sun_planet.omega_p_rel = omega_p_rel;

vdi_results.sun_planet.v_mesh = v_sp;

vdi_results.sun_planet.u = u_sp;

vdi_results.sun_planet.epsilon_alpha = epsilon_alpha_sp;
vdi_results.sun_planet.epsilon1 = epsilon1_sp;
vdi_results.sun_planet.epsilon2 = epsilon2_sp;
vdi_results.sun_planet.alpha_wt = alpha_wt_sp;
vdi_results.sun_planet.epsilon_beta = epsilon_beta_sp;

vdi_results.sun_planet.ZE = ZE_sp;
vdi_results.sun_planet.Yepsilon = Yepsilon_sp;
vdi_results.sun_planet.Zepsilon = Zepsilon_sp;
vdi_results.sun_planet.Ybeta = Ybeta_sp;
vdi_results.sun_planet.Zbeta = Zbeta_sp;
vdi_results.sun_planet.ZH = ZH_sp;

vdi_results.sun_planet.sun.YFa = YFa_s_sp;
vdi_results.sun_planet.sun.YSa = YSa_s_sp;

vdi_results.sun_planet.planet.YFa = YFa_p_sp;
vdi_results.sun_planet.planet.YSa = YSa_p_sp;

vdi_results.sun_planet.K_F = K_F_sp;
vdi_results.sun_planet.K_H = K_H_sp;

vdi_results.sun_planet.root.sun.sigma_F = sigma_F_s_sp;
vdi_results.sun_planet.root.planet.sigma_F = sigma_F_p_sp;

vdi_results.sun_planet.sigma_H = sigma_H_sp;

vdi_results.sun_planet.lambda = lambda_sp;

vdi_results.sun_planet.P = P_sp;
vdi_results.sun_planet.P_total = P_sp_total;
vdi_results.sun_planet.P_per_planet = P_sp;

vdi_results.sun_planet.H_V = H_V_sp;


%% ========================================
%          PLANET - RING RESULTS
% ========================================

vdi_results.planet_ring.F_t = F_t_rp;
vdi_results.planet_ring.F_t_total = F_t_rp_total;

vdi_results.planet_ring.v_p = v_p_abs;
vdi_results.planet_ring.v_r = v_r_abs;

vdi_results.planet_ring.omega_p_rel = omega_p_rel;
vdi_results.planet_ring.omega_r_rel = omega_r_rel;

vdi_results.planet_ring.v_mesh = v_rp;

vdi_results.planet_ring.u = u_rp;

vdi_results.planet_ring.epsilon_alpha = epsilon_alpha_rp;
vdi_results.planet_ring.epsilon1 = epsilon1_rp;
vdi_results.planet_ring.epsilon2 = epsilon2_rp;
vdi_results.planet_ring.alpha_wt = alpha_wt_rp;
vdi_results.planet_ring.epsilon_beta = epsilon_beta_rp;

vdi_results.planet_ring.ZE = ZE_rp;
vdi_results.planet_ring.Yepsilon = Yepsilon_rp;
vdi_results.planet_ring.Zepsilon = Zepsilon_rp;
vdi_results.planet_ring.Ybeta = Ybeta_rp;
vdi_results.planet_ring.Zbeta = Zbeta_rp;
vdi_results.planet_ring.ZH = ZH_rp;

vdi_results.planet_ring.planet.YFa = YFa_p_rp;
vdi_results.planet_ring.planet.YSa = YSa_p_rp;

vdi_results.planet_ring.ring.YFa = YFa_r_rp;
vdi_results.planet_ring.ring.YSa = YSa_r_rp;
vdi_results.planet_ring.ring.YSa_method = YSa_r_method;

vdi_results.planet_ring.K_F = K_F_rp;
vdi_results.planet_ring.K_H = K_H_rp;

vdi_results.planet_ring.root.planet.sigma_F = sigma_F_p_rp;
vdi_results.planet_ring.root.ring.sigma_F = sigma_F_r_rp;

vdi_results.planet_ring.sigma_H = sigma_H_rp;

vdi_results.planet_ring.lambda = lambda_rp;

vdi_results.planet_ring.P = P_rp;
vdi_results.planet_ring.P_total = P_rp_total;
vdi_results.planet_ring.P_per_planet = P_rp;

vdi_results.planet_ring.H_V = H_V_rp;


%% ========================================
%          SYSTEM RESULTS
% ========================================

vdi_results.system.P_in = P_in;
vdi_results.system.P_out = P_out;
vdi_results.system.eta = eta;

vdi_results.system.speed_ratio = speed_ratio;

vdi_results.system.sigma_F_max = max([ ...
    sigma_F_s_sp, ...
    sigma_F_p_sp, ...
    sigma_F_p_rp, ...
    sigma_F_r_rp]);

vdi_results.system.sigma_H_max = max([ ...
    sigma_H_sp, ...
    sigma_H_rp]);


%% ========================================
%          THERMAL COMPATIBILITY FIELDS
% ========================================

% These preserve the interface currently expected by
% gear_temperature.m.

vdi_results.v_sp = v_sp;
vdi_results.P_sp = P_sp_total; % legacy thermal input: full planetary stage
vdi_results.P_sp_per_planet = P_sp;
vdi_results.P_sp_total = P_sp_total;
vdi_results.H_V_sp = H_V_sp;

vdi_results.v_rp = v_rp;
vdi_results.P_rp = P_rp_total; % legacy thermal input: full planetary stage
vdi_results.P_rp_per_planet = P_rp;
vdi_results.P_rp_total = P_rp_total;
vdi_results.H_V_rp = H_V_rp;


%% ========================================
%          BASIC LEGACY OUTPUTS
% ========================================

% Retained so existing scripts that reference these
% values do not immediately break.

vdi_results.F_t_sp = F_t_sp;
vdi_results.F_t_rp = F_t_rp;

vdi_results.F_t_sp_total = F_t_sp_total;
vdi_results.F_t_rp_total = F_t_rp_total;

vdi_results.v_s = v_s_abs;
vdi_results.v_p = v_p_abs;
vdi_results.v_r = v_r_abs;
vdi_results.v_p_rel = v_p_rel;

vdi_results.u_sp = u_sp;
vdi_results.u_rp = u_rp;

vdi_results.P_s = P_in;
vdi_results.P_r = abs(T_r*omega_r);

vdi_results.P_mesh_sp_per_planet = P_sp;
vdi_results.P_mesh_sp_total = P_sp_total;
vdi_results.P_mesh_rp_per_planet = P_rp;
vdi_results.P_mesh_rp_total = P_rp_total;
vdi_results.N_p_planets = N_p_planets;
vdi_results.alpha_t = alpha_t;
vdi_results.b_sp = b_sp;
vdi_results.b_rp = b_rp;

vdi_results.epsilon_alpha_sp = epsilon_alpha_sp;
vdi_results.epsilon_alpha_rp = epsilon_alpha_rp;
vdi_results.epsilon1_sp = epsilon1_sp;
vdi_results.epsilon2_sp = epsilon2_sp;
vdi_results.epsilon1_rp = epsilon1_rp;
vdi_results.epsilon2_rp = epsilon2_rp;
vdi_results.alpha_wt_sp = alpha_wt_sp;
vdi_results.alpha_wt_rp = alpha_wt_rp;

vdi_results.ZE_sp = ZE_sp;
vdi_results.ZE_rp = ZE_rp;

vdi_results.Yepsilon_sp = Yepsilon_sp;
vdi_results.Yepsilon_rp = Yepsilon_rp;

vdi_results.Zepsilon_sp = Zepsilon_sp;
vdi_results.Zepsilon_rp = Zepsilon_rp;

vdi_results.Ybeta_sp = Ybeta_sp;
vdi_results.Ybeta_rp = Ybeta_rp;

vdi_results.Zbeta_sp = Zbeta_sp;
vdi_results.Zbeta_rp = Zbeta_rp;

vdi_results.YFa_sp = YFa_s_sp;
vdi_results.YFa_rp = YFa_p_rp;

vdi_results.YSa_sp = YSa_s_sp;
vdi_results.YSa_rp = YSa_p_rp;

vdi_results.ZH_sp = ZH_sp;
vdi_results.ZH_rp = ZH_rp;

vdi_results.K_F = K_F_sp;
vdi_results.K_H = K_H_sp;

% Compatibility summary stresses are the governing member stress per mesh.
vdi_results.sigma_F_sp = max(sigma_F_s_sp,sigma_F_p_sp);
vdi_results.sigma_F_rp = max(sigma_F_p_rp,sigma_F_r_rp);

vdi_results.sigma_H_sp = sigma_H_sp;
vdi_results.sigma_H_rp = sigma_H_rp;

vdi_results.lambda_sp = lambda_sp;
vdi_results.lambda_rp = lambda_rp;
vdi_results.lambda_zul = 0.07*m_n; % VDI2 p.20 guide value

vdi_results.P_in = P_in;
vdi_results.P_out = P_out;

vdi_results.eta = eta;
vdi_results.speed_ratio = speed_ratio;


%% ========================================
%          PRINT RESULTS
% ========================================

fprintf('\n========================================\n');
fprintf('          VDI 2736 GEAR ANALYSIS\n');
fprintf('========================================\n');

fprintf('\n--- Sun - Planet Mesh ---\n');
fprintf('Tangential Force / Planet: %.3f N\n',F_t_sp);
fprintf('Total Tangential Force:    %.3f N\n',F_t_sp_total);
fprintf('Mesh Velocity:             %.3f m/s\n',v_sp);
fprintf('Gear Ratio:                %.4f\n',u_sp);
fprintf('Contact Ratio:             %.4f\n',epsilon_alpha_sp);
fprintf('  Partial ratios:           %.4f + %.4f\n',epsilon1_sp,epsilon2_sp);

fprintf('\nRoot Stress:\n');
fprintf('  Sun:                     %.3f MPa\n',sigma_F_s_sp/1e6);
fprintf('  Planet:                  %.3f MPa\n',sigma_F_p_sp/1e6);

fprintf('Flank Stress:              %.3f MPa\n',sigma_H_sp/1e6);


fprintf('\n--- Planet - Ring Mesh ---\n');
fprintf('Tangential Force / Planet: %.3f N\n',F_t_rp);
fprintf('Total Tangential Force:    %.3f N\n',F_t_rp_total);
fprintf('Mesh Velocity:             %.3f m/s\n',v_rp);
fprintf('Gear Ratio:                %.4f\n',u_rp);
fprintf('Contact Ratio:             %.4f\n',epsilon_alpha_rp);
fprintf('  Partial ratios:           %.4f + %.4f\n',epsilon1_rp,epsilon2_rp);

fprintf('\nRoot Stress:\n');
fprintf('  Planet:                  %.3f MPa\n',sigma_F_p_rp/1e6);
fprintf('  Ring:                    %.3f MPa\n',sigma_F_r_rp/1e6);

fprintf('Flank Stress:              %.3f MPa\n',sigma_H_rp/1e6);


fprintf('\n--- Governing Values ---\n');
fprintf('Maximum Root Stress:       %.3f MPa\n', ...
    vdi_results.system.sigma_F_max/1e6);

fprintf('Maximum Flank Stress:      %.3f MPa\n', ...
    vdi_results.system.sigma_H_max/1e6);

fprintf('\n========================================\n');

end
