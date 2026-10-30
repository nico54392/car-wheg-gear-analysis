% CAR wheg planetary gear analysis (VDI 2736 Blatt 2)
%
% This is a research prototype for short lab tests. The pass/fail checks are:
%   1. Static strength at the largest torque the motor can apply (stall),
%      VDI 2736-2 Section 3.3           -> static_peak_check.m
%   2. PA12 temperature, hottest point on the whole motor line with the
%      gears running the entire test   -> thermal_worst_case.m
% Wear and fatigue life are reported for reference only, together with
% the operating conditions they assume.

close all;
clc;
clear;


%% ========================================
%          OPERATING CONDITIONS
% ========================================

m_vcl = 8;                              % [kg]
Crr = 0.1;                              % [-]
theta = 0 * (pi/180);                    % [rad]
rho_air = 1.225;                         % [kg/m^3]

A_vcl = ...
    0.07*0.24 + ...
    0.14*0.07*2;                         % [m^2]

nu_drvtr = 0.94;                         % [-]

% Motor operating limit
motor.voltage_nominal = 12;       % [V]
motor.voltage_fraction = 1.0;    % [-] 80% voltage command

% Motor torque-speed limits at nominal voltage
motor.T_stall_nominal = 7.65;     % [N*m]
motor.omega_0_nominal = 170*2*pi/60; % [rad/s]

% Effective limits at commanded voltage
motor.voltage = motor.voltage_fraction * motor.voltage_nominal;
T_stall = motor.voltage_fraction * motor.T_stall_nominal;
omega_0 = motor.voltage_fraction * motor.omega_0_nominal;

%% ========================================
%          WHEEL GEOMETRY
% ========================================

% Wheel closed

r_wheel_c = 0.06;                        % [m]

% Wheel open

r_wheel_o = 0.1029;                      % [m]


%% ========================================
%          GEAR PARAMETERS
% ========================================

T_q = 0;                                 % [N*m]
omega_q = 0;                             % [rad/s]

mod = 1;                                 % [mm]

N_p = 11;
N_s = 16;
N_r1_i = 38;

N_r2 = 38;
N_r1_o = 50;
N_q = 50;

D_r2 = N_r2*mod;                         % [mm]
D_r1_o = N_r1_o*mod;                     % [mm]
D_q = N_q*mod;                           % [mm]

N_p_planets = 3;



%% ========================================
%          MATERIAL / STATIC STRENGTH
% ========================================

T_ambient = 25;  % [deg C]

%% MATERIAL PROPERTIES

% ============================================================
% PA12 - HP High Reusability PA12, MJF
% Provisional values; verify against the exact material datasheet.
% ============================================================

PA12.E_XY = 1.7e9;                 % Young's modulus, XY plane [Pa]
PA12.E_Z  = 1.8e9;                 % Young's modulus, Z direction [Pa]
PA12.nu   = 0.47;                  % Poisson's ratio [-]

PA12.tensile_strength_XY = 48e6;   % Tensile strength, XY [Pa]
PA12.tensile_strength_Z  = 48e6;   % Tensile strength, Z [Pa]

PA12.flexural_strength_XY = 65e6;  % Flexural strength, XY [Pa]
PA12.flexural_strength_Z  = 70e6;  % Flexural strength, Z [Pa]

PA12.HDT_182 = 95;                 % Heat deflection temperature at 1.82 MPa [°C]
PA12.HDT_045 = 175;                % Heat deflection temperature at 0.45 MPa [°C]

% Select the effective modulus for the current gear orientation.
% This assumes XY properties for the current preliminary model.
PA12.E = PA12.E_XY;

% Preliminary static root-strength reference.
% Flexural strength is a screening reference, not a validated
% allowable gear-tooth root stress.
PA12.flexural_strength = PA12.flexural_strength_XY;

% Tensile strength retained as a separate material property.
PA12.tensile_strength = PA12.tensile_strength_XY;

% Static strength for the peak-load check. MJF PA12 fails ductile without a
% clear yield point, so tensile strength stands in for sigma_S.
% (MJF PA12 X/Y/Z 47/48/49 MPa, UCD MJF PA12 vs PA12-GB study.)
PA12.sigma_S = PA12.tensile_strength_XY;  % [Pa], at 23 C

% Temperature limits for short tests
PA12.Tg = 44;          % [deg C] glass transition, DSC, MJF PA12 (UCD study).
                       % Above this, stiffness and strength drop noticeably.
PA12.T_melt = 187;     % [deg C] HP 3D HR PA12 datasheet


% ============================================================
% STAINLESS STEEL - PLANETS
% Fill in strength properties once the exact grade is known.
% ============================================================

steel.E = 193e9;                   % Approximate Young's modulus [Pa]
steel.nu = 0.30;                   % Approximate Poisson's ratio [-]

steel.sigma_y = 205e6;               % Yield strength [Pa] - FILL IN
steel.sigma_u = 515e6;               % Ultimate tensile strength [Pa] - FILL IN
steel.sigma_F = NaN;               % Allowable tooth-root bending stress [Pa]
                                   % FILL IN if a justified value is available

% Optional: record the grade once identified.
steel.grade = 'FILL IN';



% Provisional PA12 fatigue screening data from TA Instruments EF037.
% All PA12 tensile coupons ran out at 25 MPa through 1e7 cycles. Project
% this only as a lower-bound root-fatigue screen. It is room-temperature
% tensile-coupon data, not gear-tooth data; no temperature correction exists.
% Flank contact fatigue remains unassessed.
fatigue_data.runout_stress_Pa = 25e6;
fatigue_data.runout_cycles = 1e7;

T_HDT_1p82 = 95;                          % [deg C]
T_HDT_0p45 = 175;                         % [deg C]


%% ========================================
%          THERMAL PARAMETERS
% ========================================

mu_gear = 0.20;                          % [-], VDI 2736-2 Table 2, dry plastic/steel (PA12 sun & ring vs steel planets)
k_theta_root = 900;                      % [K*(m/s)^0.75*mm^1.75], VDI Table 3 dry plastic/steel
k_theta_flank = 6300;                    % [K*(m/s)^0.75*mm^1.75], VDI Table 3 dry plastic/steel

ED = .3;                               % [-], assumed relative engagement/duty fraction

R_lambda_G = 0;                          % [K*m^2/W]

A_G = 1;                                 % [m^2]


%% ========================================
%          RESEARCH-USE PASS/FAIL CRITERIA
% ========================================

crit.S_Smin = 1.5;                       % VDI 2736-2 Eq. (24), against yield
crit.sigma_S_PA12 = PA12.sigma_S;        % [Pa]
crit.sigma_y_steel = steel.sigma_y;      % [Pa]
crit.T_soft = PA12.Tg;                   % [deg C] PASS below, CAUTION above
crit.T_limit = PA12.HDT_182;             % [deg C] FAIL above (HDT 1.82 MPa)
crit.T_melt = PA12.T_melt;               % [deg C] reported only


%% ========================================
%          GEAR STRUCTURE
% ========================================

gear.mod = mod;
gear.alpha = 20*pi/180;                 % [rad], normal reference pressure angle; match CAD
gear.beta = 0;

gear.N_p_planets = N_p_planets;


% Planet
gear.N_p = N_p;
gear.x_p = 0.15;                        % [module], positive profile shift
gear.E_p = steel.E;
gear.nu_p = steel.nu;
gear.sigma_y_p_Pa = steel.sigma_y;


% Sun
gear.N_s = N_s;
gear.x_s = 0.40;                        % [module], x_s+x_p=0.55
gear.E_s = PA12.E;
gear.nu_s = PA12.nu;
gear.sigma_F_s_PA12_Pa = PA12.flexural_strength_XY;
gear.b_s = 10;  % [mm] Sun face width
gear.b_p = 10;  % [mm] Planet face width


% Inner ring

gear.N_r1_i = N_r1_i;
gear.b_r1 = 10;                          % [mm]
gear.x_r1 = 0.70;                       % [module], x_r-x_p=0.55
gear.E_r = PA12.E;
gear.nu_r1 = PA12.nu;
gear.sigma_F_r_PA12_Pa = PA12.flexural_strength_XY;
gear.b_r1 = 10; % [mm] Inner-ring face width


% Other gears

gear.N_r1_o = N_r1_o;
gear.D_r1_o = D_r1_o;

gear.N_r2 = N_r2;
gear.D_r2 = D_r2;

gear.N_q = N_q;
gear.D_q = D_q;


% Gear operating parameters

gear.K_A = 1.25;                         % [-], VDI 2736-2 p.7: K_A ~ 1...1.25 for electric-motor drives.
                                         % Upper end kept for conservatism. KF/KH return K_A (VDI p.11/17, b/m<=12).
gear.Q = 9;


% Manufacturing / alignment parameters

gear.f_beta = 0;
gear.f_alpha = 0;

gear.f_sh = 0;
gear.f_b = 0;

% Dimensional tolerance inputs for the mesh backlash/interference screen.
% Enter +/- half-widths in mm from part drawings or measured parts.
% Nominal backlash defaults to zero until an intentional value is specified.
gear_tol.sun_tooth_thickness_mm = 0;     % [mm], +/- circumferential thickness
gear_tol.planet_tooth_thickness_mm = 0;  % [mm], +/- circumferential thickness
gear_tol.ring_tooth_thickness_mm = 0;    % [mm], +/- circumferential thickness
gear_tol.planet_radial_position_mm = 0;  % [mm], +/- planet center location
gear_tol.nominal_backlash_sp_mm = 0;     % [mm], sun-planet mesh
gear_tol.nominal_backlash_rp_mm = 0;     % [mm], planet-ring mesh
interference_cases = gear_interference_cases(gear,gear_tol);


%% ========================================
%          GEOMETRY CHECKS
% ========================================

gear_geom = geometry_calc(gear);
if ~gear_geom.valid_planetary_geometry
    error('Inner planetary geometry fails pitch-radius closure.');
end
fprintf('Reference pressure angle: %.1f deg; working mesh angles: %.2f / %.2f deg\n', ...
    rad2deg(gear.alpha),rad2deg(gear_geom.alpha_w_sp),rad2deg(gear_geom.alpha_w_rp));
fprintf('Profile shifts sun/planet/ring: %.2f / %.2f / %.2f; working center: %.3f mm\n', ...
    gear.x_s,gear.x_p,gear.x_r1,gear_geom.a_sp_mm);
fprintf('Rack undercut screen sun/planet margins: %.3f / %.3f module\n', ...
    gear_geom.sun_undercut_shift_margin,gear_geom.planet_undercut_shift_margin);
if ~gear_geom.valid_planet_phasing
    error('Tooth counts are incompatible with equally spaced planets.');
end

% Use the shared geometry result wherever pitch radii are needed.
r_p = gear_geom.r_p;
r_s = gear_geom.r_s;
r_r1_i = gear_geom.r_r;
r_r2 = D_r2/2;
r_r1_o = D_r1_o/2;
r_q = D_q/2;
a_sp = gear_geom.a;
planetary_error_inner = gear_geom.planetary_error;
planetary_error_outer = r_r1_o-r_s-2*r_p;

% Wheel geometry

D_wheel_c = 2*r_wheel_c;
D_wheel_o = 2*r_wheel_o;

delta_r_wheel = r_wheel_o - r_wheel_c;

% Maximum gear radius

r_gear_max = r_r1_o;

% Gear-to-wheel ratios

gear_wheel_ratio_c = ...
    r_wheel_c/r_gear_max;

gear_wheel_ratio_o = ...
    r_wheel_o/r_gear_max;


%% ========================================
%          CONDITION 1
%          WHEEL CLOSED
% ========================================

F_trac_c = @(v) ...
    nu_drvtr*T_stall/r_wheel_c .* ...
    (1 - v/(omega_0*r_wheel_c));

F_grade_c = ...
    m_vcl*9.81*sin(theta);

F_rr_c = ...
    Crr*m_vcl*9.81*cos(theta);

F_drag_c = @(v) ...
    0.5*rho_air*A_vcl*v.^2;

F_balance_c = @(v) ...
    F_trac_c(v) - ...
    F_grade_c - ...
    F_rr_c - ...
    F_drag_c(v);

v_max_c = ...
    fzero(F_balance_c,[0,omega_0*r_wheel_c]);


%% ========================================
%          CONDITION 2
%          WHEEL OPEN
% ========================================

F_trac_o = @(v) ...
    nu_drvtr*T_stall/r_wheel_o .* ...
    (1 - v/(omega_0*r_wheel_o));

F_grade_o = ...
    m_vcl*9.81*sin(theta);

F_rr_o = ...
    Crr*m_vcl*9.81*cos(theta);

F_drag_o = @(v) ...
    0.5*rho_air*A_vcl*v.^2;

F_balance_o = @(v) ...
    F_trac_o(v) - ...
    F_grade_o - ...
    F_rr_o - ...
    F_drag_o(v);

v_max_o = ...
    fzero(F_balance_o,[0,omega_0*r_wheel_o]);



%% ========================================
%          WHEEL CLOSED RESULTS
% ========================================

omega_c_closed = ...
    v_max_c/r_wheel_c;

T_c_closed = ...
    T_stall*(1 - omega_c_closed/omega_0);

P_c_closed = ...
    T_c_closed*omega_c_closed;


%% ========================================
%          PLANETARY GEAR
%          WHEEL CLOSED
% ========================================

gear_results_c = planetary_gear( ...
    omega_q, ...
    T_q, ...
    T_c_closed, ...
    omega_c_closed, ...
    gear, ...
    gear_geom);


%% ========================================
%          VDI 2736
%          WHEEL CLOSED
% ========================================

vdi_results_c = vdi2736( ...
    gear_results_c, ...
    gear, ...
    gear_geom);



%% ========================================
%          THERMAL ANALYSIS
%          WHEEL CLOSED
% ========================================

temp_results_c = gear_temperature( ...
    vdi_results_c, ...
    gear, ...
    T_ambient, ...
    mu_gear, ...
    k_theta_root, ...
    R_lambda_G, ...
    A_G, ...
    ED, ...
    k_theta_flank);

safety_results_c = gear_safety( ...
    vdi_results_c, gear, temp_results_c.T_max, ...
    PA12.flexural_strength_XY, PA12.tensile_strength_XY, ...
    vdi_results_c.lambda_zul, fatigue_data);


%% ========================================
%          WHEEL OPEN RESULTS
% ========================================

omega_o_open = ...
    v_max_o/r_wheel_o;

T_o_open = ...
    T_stall*(1 - omega_o_open/omega_0);

P_o_open = ...
    T_o_open*omega_o_open;


%% ========================================
%          PLANETARY GEAR
%          WHEEL OPEN
% ========================================

gear_results_o = planetary_gear( ...
    omega_q, ...
    T_q, ...
    T_o_open, ...
    omega_o_open, ...
    gear, ...
    gear_geom);


%% ========================================
%          VDI 2736
%          WHEEL OPEN
% ========================================

vdi_results_o = vdi2736( ...
    gear_results_o, ...
    gear, ...
    gear_geom);



%% ========================================
%          THERMAL ANALYSIS
%          WHEEL OPEN
% ========================================

temp_results_o = gear_temperature( ...
    vdi_results_o, ...
    gear, ...
    T_ambient, ...
    mu_gear, ...
    k_theta_root, ...
    R_lambda_G, ...
    A_G, ...
    ED, ...
    k_theta_flank);

safety_results_o = gear_safety( ...
    vdi_results_o, gear, temp_results_o.T_max, ...
    PA12.flexural_strength_XY, PA12.tensile_strength_XY, ...
    vdi_results_o.lambda_zul, fatigue_data);

% VDI 2736 Blatt 2 average-wear life estimate (Eqs. 19 and 21).
% k_w for printed PA12 against steel, dry. Values in 10^-6 mm^3/(N*m):
%   16       molded PA12 vs 100Cr6, pin-on-disc, Rz 3.2, 4 MPa, 0.5 m/s
%            (VDI 2736 Blatt 1 Fig. 5) -> best case, not printed material
%   320-480  laser-sintered PA12 vs stainless ball, 0.35 m/s
%            (White Rose eprint 202329, Wear 2023)
%   56-512   SLS PA12/PA12 gears (Odrobina thesis), 284 = midpoint
% 284 kept: it sits inside the printed-PA12-on-steel range. Life ~ 1/k_w.
wear_inputs.k_w_1e6 = 284;
wear_inputs.k_w_provisional = true;
wear_inputs.k_w_source = ['Printed PA12 on steel: LS PA12 vs stainless 320-480, ' ...
    'Odrobina SLS gears 56-512 (284 midpoint); molded best case 16 (VDI 2736-1 Fig. 5)'];
wear_inputs.fraction_closed = 0.50;
wear_inputs.fraction_open = 0.50;
wear_inputs.hours_per_day = 3;
wear_inputs.days_per_year = 365;
wear_inputs.design_years = 5;
wear_life = gear_wear(vdi_results_c,vdi_results_o, ...
    gear_results_c,gear_results_o,gear,wear_inputs);

% Static strength references are screening values, not fatigue/yield allowables.
% Root has a provisional TA coupon runout floor; flank fatigue is unassessed.
strength_assessment.status = 'static_screen_plus_provisional_root_runout';
strength_assessment.note = ['Root fatigue uses a provisional TA EF037 SLS PA12 coupon ' ...
    'runout floor, not a gear S-N curve; no temperature correction or flank ' ...
    'contact-fatigue life is available.'];
strength_assessment.root_cycles_lower_bound_open = ...
    safety_results_o.root_cycles_to_failure_lower_bound;
strength_assessment.root_fatigue_status_open = ...
    safety_results_o.root_fatigue_status;
strength_assessment.flank_fatigue_status = ...
    safety_results_o.flank_fatigue_status;


%% ========================================
%          RESEARCH-USE CHECKS
% ========================================

% 1. Static strength at motor stall. The motor drives the carrier directly,
%    so stall torque is the most the gears can see from the motor.
T_c_peak = T_stall;                      % [N*m]
static_results = static_peak_check(vdi_results_o, gear, T_c_peak, crit);

% 2. PA12 temperature at the test operating points, gears running the
%    whole test (ED = 1). Add rows for any other test you plan to run,
%    e.g. a climb: [T_c, omega_c]. The whole motor line is also swept and
%    reported as a warning.
test_points = [T_c_closed, omega_c_closed; ...
               T_o_open,   omega_o_open];
thermal_inputs.T_ambient = T_ambient;
thermal_inputs.mu = mu_gear;
thermal_inputs.k_theta_root = k_theta_root;
thermal_inputs.k_theta_flank = k_theta_flank;
thermal_inputs.R_lambda_G = R_lambda_G;
thermal_inputs.A_G = A_G;
thermal_inputs.test_names = {'closed wheel, top speed','open wheel, top speed'};
thermal_results = thermal_check(gear, gear_geom, T_stall, omega_0, ...
    thermal_inputs, crit, test_points);


%% ========================================
%          OUTPUT: PASS/FAIL CHECKS
% ========================================

fprintf('\n\n========================================\n');
fprintf('   RESEARCH-USE CHECKS (pass/fail)\n');
fprintf('========================================\n');

pf = {'FAIL','PASS'};

fprintf('\n1) STATIC STRENGTH AT MOTOR STALL (VDI 2736-2 Sec. 3.3)\n');
fprintf('   Carrier torque %.2f N*m -> sun %.3f N*m, %.1f N per planet\n', ...
    static_results.T_c_peak, static_results.T_s_peak, static_results.F_t_sp);
fprintf('   %-32s %9s %9s %7s\n','member','stress','allow','margin');
for i = 1:numel(static_results.root.sigma)
    fprintf('   %-32s %6.1f MPa %6.1f MPa %6.2fx  %s\n', static_results.root.names{i}, ...
        static_results.root.sigma(i)/1e6, static_results.root.allow(i)/1e6, ...
        static_results.root.margin(i), pf{static_results.root.pass(i)+1});
end
for i = 1:numel(static_results.flank.sigma)
    fprintf('   %-32s %6.1f MPa %6.1f MPa %6.2fx  %s\n', static_results.flank.names{i}, ...
        static_results.flank.sigma(i)/1e6, static_results.flank.allow(i)/1e6, ...
        static_results.flank.margin(i), static_results.flank.status{i});
end
fprintf('   Root allow: PA12 2.0*sigma_S/S_Smin, steel sigma_y/S_Smin; S_Smin = %.1f\n', ...
    static_results.S_Smin);
fprintf(['   Flank allow: 1.67*sigma_S/S_Smin (project screen). MARGINAL = under first\n' ...
    '   yield (%.0f MPa) but inside the safety factor: may mark the flank, won''t break.\n'], ...
    static_results.flank.first_yield(1)/1e6);
fprintf('   Tooth deflection at stall: %.1f / %.1f um (VDI guide %.0f um, info only)\n', ...
    static_results.lambda(1)*1e6, static_results.lambda(2)*1e6, static_results.lambda_zul*1e6);
fprintf('   -> %s\n', static_results.status);

fprintf('\n2) PA12 TEMPERATURE DURING A TEST (gears running the whole test, ED = 1)\n');
for k = 1:numel(thermal_results.tests)
    tk = thermal_results.tests(k);
    fprintf('   %-26s %4.0f rpm %5.2f N*m  flank %5.1f C, body %5.1f C  %s\n', tk.name, ...
        tk.omega_c*60/(2*pi), tk.T_c, tk.T_max, tk.T_root, tk.status);
end
fprintf('   Limits: Tg %.0f C (CAUTION above), HDT %.0f C (FAIL above), melt %.0f C\n', ...
    thermal_results.T_soft, thermal_results.T_limit, thermal_results.T_melt);
fprintf(['   Graded on flank (surface, VDI Eq. 9); body = root temperature (Eq. 7).\n' ...
    '   VDI steady-state values, so a short test runs cooler than this.\n']);
fprintf('   -> %s\n', thermal_results.status);
fprintf(['   Warning, whole motor line: hottest flank %.0f C (body %.0f C)\n' ...
    '   at %.0f rpm / %.2f N*m (%s).\n'], ...
    thermal_results.env.T_max, thermal_results.env.T_root_at_max, ...
    thermal_results.env.carrier_rpm, thermal_results.env.T_c, thermal_results.env.status);
if ~isempty(thermal_results.env.over_HDT_rpm)
    fprintf(['   Running continuously between %.0f and %.0f carrier rpm on the motor line\n' ...
        '   (pushing near stall) would go over HDT. Keep those moments short.\n'], ...
        thermal_results.env.over_HDT_rpm(1), thermal_results.env.over_HDT_rpm(2));
end

overall_ok = static_results.pass && thermal_results.pass;
fprintf('\nOVERALL: %s', pf{overall_ok+1});
flags = {};
if strcmp(static_results.status,'MARGINAL'), flags{end+1} = 'flank marginal at stall'; end
if strcmp(thermal_results.status,'CAUTION'), flags{end+1} = 'PA12 above Tg during tests'; end
if ~isempty(flags), fprintf(' (%s)', strjoin(flags,'; ')); end
fprintf('\n');


%% ========================================
%          OUTPUT: REFERENCE ONLY
% ========================================

fprintf('\n\n========================================\n');
fprintf('   REFERENCE ONLY (not pass/fail)\n');
fprintf('========================================\n');

fprintf('\nNominal operating points (max steady speed on the motor line):\n');
fprintf('   %-30s %10s %10s\n','','closed','open');
fprintf('   %-30s %10.3f %10.3f\n','vehicle speed [m/s]',v_max_c,v_max_o);
fprintf('   %-30s %10.1f %10.1f\n','carrier [rpm]', ...
    omega_c_closed*60/(2*pi),omega_o_open*60/(2*pi));
fprintf('   %-30s %10.3f %10.3f\n','carrier torque [N*m]',T_c_closed,T_o_open);
fprintf('   %-30s %10.2f %10.2f\n','carrier power [W]',P_c_closed,P_o_open);
fprintf('   %-30s %10.1f %10.1f\n','sun [rpm]', ...
    abs(gear_results_c.omega_s)*60/(2*pi),abs(gear_results_o.omega_s)*60/(2*pi));
fprintf('   %-30s %10.3f %10.3f\n','mesh speed, carrier frame [m/s]', ...
    vdi_results_c.v_sp,vdi_results_o.v_sp);
fprintf('   %-30s %10.2f %10.2f\n','force per planet [N]', ...
    vdi_results_c.F_t_sp,vdi_results_o.F_t_sp);
fprintf('   %-30s %10.2f %10.2f\n','max root stress [MPa]', ...
    vdi_results_c.system.sigma_F_max/1e6,vdi_results_o.system.sigma_F_max/1e6);
fprintf('   %-30s %10.2f %10.2f\n','max flank stress [MPa]', ...
    vdi_results_c.system.sigma_H_max/1e6,vdi_results_o.system.sigma_H_max/1e6);
fprintf('   %-30s %10.1f %10.1f\n',sprintf('max temp at ED = %.2f [C]',ED), ...
    temp_results_c.T_max,temp_results_o.T_max);
fprintf('   Assumes K_A = %.2f, mu = %.2f, ambient %.0f C, open housing\n', ...
    gear.K_A, mu_gear, T_ambient);

fprintf('\nWear life (VDI Eq. 19/21):\n');
fprintf('   k_w = %.0f x 10^-6 mm^3/(N*m) (printed PA12 on steel, range ~50-500)\n', ...
    wear_life.k_w_1e6);
fprintf('   Duty: %.0f%% closed / %.0f%% open at the nominal points above\n', ...
    100*wear_life.duty.fraction_closed,100*wear_life.duty.fraction_open);
fprintf('   Running hours to 0.1*m / 0.2*m wear: %.0f / %.0f h (%s governs)\n', ...
    wear_life.governing_low_limit_hours,wear_life.governing_high_limit_hours, ...
    wear_life.governing_member_low_limit);
wear_member_names = {'sun','ring'};
for iWear = 1:numel(wear_member_names)
    wm = wear_life.members.(wear_member_names{iWear});
    fprintf('     %-5s %.3g load cycles/h, %.0f-%.0f h\n', wear_member_names{iWear}, ...
        wm.N_L_per_hour_mixed, wm.life_to_Wzul_low_hours, wm.life_to_Wzul_high_hours);
end
fprintf('   Life scales as 1/k_w and roughly 1/torque.\n');

fprintf('\nRoot fatigue (PA12, nominal points):\n');
fprintf('   %s\n', safety_results_o.root_fatigue_status);
fprintf('   Coupon runout %.0f MPa at %.0e cycles vs max PA12 root %.1f MPa\n', ...
    fatigue_data.runout_stress_Pa/1e6, fatigue_data.runout_cycles, ...
    max(vdi_results_o.sun_planet.root.sun.sigma_F, ...
        vdi_results_o.planet_ring.root.ring.sigma_F)/1e6);

fprintf('\n=== Dimensional tolerance / interference screen ===\n');
fprintf('Nominal backlash, sun-planet / planet-ring: %.4f / %.4f mm\n', ...
    interference_cases.nominal.sun_planet_backlash_mm, ...
    interference_cases.nominal.planet_ring_backlash_mm);
fprintf('%s\n',interference_cases.status);
fprintf('========================================\n');


%% WHEEL SPEED FROM CARRIER RPM

% Convert carrier angular velocity to RPM
carrier_rpm_c = omega_c_closed * 60 / (2*pi);
carrier_rpm_o = omega_o_open * 60 / (2*pi);

% Wheel angular velocity equals carrier angular velocity
wheel_rpm_c = carrier_rpm_c;
wheel_rpm_o = carrier_rpm_o;

% Linear wheel speed
wheel_speed_c_ms = omega_c_closed * r_wheel_c;
wheel_speed_o_ms = omega_o_open * r_wheel_o;

wheel_speed_c_kmh = 3.6 * wheel_speed_c_ms;
wheel_speed_o_kmh = 3.6 * wheel_speed_o_ms;

fprintf('\n===== WHEEL SPEED FROM CARRIER =====\n');
fprintf('CLOSED: Carrier = %.2f RPM | Wheel = %.2f RPM | Speed = %.3f m/s (%.2f km/h)\n', ...
    carrier_rpm_c, wheel_rpm_c, wheel_speed_c_ms, wheel_speed_c_kmh);

fprintf('OPEN:   Carrier = %.2f RPM | Wheel = %.2f RPM | Speed = %.3f m/s (%.2f km/h)\n', ...
    carrier_rpm_o, wheel_rpm_o, wheel_speed_o_ms, wheel_speed_o_kmh);
