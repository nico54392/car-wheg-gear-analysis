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

mu_gear = 0.28;                          % [-], VDI 2736 Blatt 2 Table 2 dry PA/PA assumption
mu_gear = 0.129;
k_theta_root = 900;                      % [K*(m/s)^0.75*mm^1.75], VDI Table 3 dry plastic/steel
k_theta_flank = 6300;                    % [K*(m/s)^0.75*mm^1.75], VDI Table 3 dry plastic/steel

ED = .3;                               % [-], assumed relative engagement/duty fraction

R_lambda_G = 0;                          % [K*m^2/W]

A_G = 1;                                 % [m^2]


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

gear.K_A = 1.0;
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
% Provisional midpoint k_w from microscopy-derived SLS PA12/PA12 dry-gear
% range 56-512 x 10^-6 mm^3/(N*m), measured at pv=9.2-11.03 MPa*m/s.
wear_inputs.k_w_1e6 = 284;
wear_inputs.k_w_provisional = true;
wear_inputs.k_w_source = ['Odrobina thesis: midpoint of microscopy-based PA12/PA12 ' ...
    'SLS dry-gear range (56-512 x 10^-6 mm^3/(N*m))'];
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
%          THERMAL CHECK
% ========================================

T_max_c = temp_results_c.T_max;
T_max_o = temp_results_o.T_max;

thermal_margin_c = ...
    T_HDT_1p82 - T_max_c;

thermal_margin_o = ...
    T_HDT_1p82 - T_max_o;


%% ========================================
%          FINAL OUTPUT
% ========================================

fprintf('\n========================================\n');
fprintf('          VEHICLE PERFORMANCE\n');
fprintf('========================================\n');

fprintf('\nWheel Closed:\n');
fprintf('  Maximum Speed:           %.3f m/s\n',v_max_c);
fprintf('  Maximum Speed:           %.3f km/h\n',v_max_c*3.6);
fprintf('  Gear Torque:             %.3f N*m\n',T_c_closed);
fprintf('  Gear Power:              %.3f W\n',P_c_closed);

fprintf('\nWheel Open:\n');
fprintf('  Maximum Speed:           %.3f m/s\n',v_max_o);
fprintf('  Maximum Speed:           %.3f km/h\n',v_max_o*3.6);
fprintf('  Gear Torque:             %.3f N*m\n',T_o_open);
fprintf('  Gear Power:              %.3f W\n',P_o_open);


fprintf('\n========================================\n');
fprintf('          THERMAL CHECK\n');
fprintf('========================================\n');

fprintf('\nWheel Closed:\n');
fprintf('  Sun-planet higher root/flank characteristic: %.2f deg C\n', ...
    temp_results_c.T_sp);

fprintf('  Planet-ring higher root/flank characteristic: %.2f deg C\n', ...
    temp_results_c.T_rp);

fprintf('  Highest characteristic temperature: %.2f deg C\n', ...
    T_max_c);
fprintf('  Root / flank characteristic maxima: %.2f / %.2f deg C\n', ...
    temp_results_c.T_root_max,temp_results_c.T_flank_max);

fprintf('\nWheel Open:\n');
fprintf('  Sun-planet higher root/flank characteristic: %.2f deg C\n', ...
    temp_results_o.T_sp);

fprintf('  Planet-ring higher root/flank characteristic: %.2f deg C\n', ...
    temp_results_o.T_rp);

fprintf('  Highest characteristic temperature: %.2f deg C\n', ...
    T_max_o);
fprintf('  Root / flank characteristic maxima: %.2f / %.2f deg C\n', ...
    temp_results_o.T_root_max,temp_results_o.T_flank_max);

fprintf('\nHP PA12 HDT Reference:      %.2f deg C\n', ...
    T_HDT_1p82);

fprintf('\nMargin to HDT reference (screening only):\n');
fprintf('  Closed:                   %.2f deg C\n', ...
    thermal_margin_c);

fprintf('  Open:                     %.2f deg C\n', ...
    thermal_margin_o);

fprintf('========================================\n');
fprintf('\nStrength assessment: %s\n%s\n',strength_assessment.status, ...
    strength_assessment.note);
fprintf('\n=== Average flank-wear life estimate ===\n');
fprintf('Coefficient: %.1f x 10^-6 mm^3/(N*m), provisional midpoint\n', ...
    wear_life.k_w_1e6);
fprintf('Operating profile: %.1f h/day, %.0f%% closed / %.0f%% open\n', ...
    wear_life.hours_per_day,100*wear_life.duty.fraction_closed,100*wear_life.duty.fraction_open);
fprintf('VDI allowable wear range: %.3f-%.3f mm\n', ...
    wear_life.permissible_mm(1),wear_life.permissible_mm(2));
fprintf('Governing life to 0.1*m_n: %.0f operating hours (%.1f calendar years), member=%s\n', ...
    wear_life.governing_low_limit_hours,wear_life.governing_low_limit_years, ...
    wear_life.governing_member_low_limit);
fprintf('Governing life to 0.2*m_n: %.0f operating hours (%.1f calendar years), member=%s\n', ...
    wear_life.governing_high_limit_hours,wear_life.governing_high_limit_years, ...
    wear_life.governing_member_high_limit);
fprintf('Cycles to the governing limits: %.3g-%.3g load cycles\n', ...
    wear_life.members.(wear_life.governing_member_low_limit).N_L_to_Wzul_low, ...
    wear_life.members.(wear_life.governing_member_high_limit).N_L_to_Wzul_high);
fprintf('At %.0f operating hours (5-year target): within lower limit=%d, within upper limit=%d\n', ...
    wear_life.design_hours,wear_life.within_5y_limit_low,wear_life.within_5y_limit_high);
wear_member_names = {'sun','planet_sp','planet_rp','ring'};
for iWear = 1:numel(wear_member_names)
    wear_member = wear_life.members.(wear_member_names{iWear});
    fprintf('  %-10s: %.3g cycles/h; life %.0f-%.0f h\n', ...
        wear_member_names{iWear},wear_member.N_L_per_hour_mixed, ...
        wear_member.life_to_Wzul_low_hours,wear_member.life_to_Wzul_high_hours);
end

fprintf('\n=== Dimensional tolerance / interference screen ===\n');
fprintf('Tolerance entries are +/- half-widths in mm.\n');
fprintf('Nominal backlash, sun-planet / planet-ring: %.4f / %.4f mm\n', ...
    interference_cases.nominal.sun_planet_backlash_mm, ...
    interference_cases.nominal.planet_ring_backlash_mm);
fprintf('Maximum-interference stack, sun-planet: backlash %.4f mm; interference %.4f mm\n', ...
    interference_cases.max_interference.sun_planet_backlash_mm, ...
    interference_cases.max_interference.sun_planet_interference_mm);
fprintf('Maximum-interference stack, planet-ring: backlash %.4f mm; interference %.4f mm\n', ...
    interference_cases.max_interference.planet_ring_backlash_mm, ...
    interference_cases.max_interference.planet_ring_interference_mm);
fprintf('Minimum-interference stack, sun-planet: backlash %.4f mm; interference %.4f mm\n', ...
    interference_cases.min_interference.sun_planet_backlash_mm, ...
    interference_cases.min_interference.sun_planet_interference_mm);
fprintf('Minimum-interference stack, planet-ring: backlash %.4f mm; interference %.4f mm\n', ...
    interference_cases.min_interference.planet_ring_backlash_mm, ...
    interference_cases.min_interference.planet_ring_interference_mm);
fprintf('%s\n',interference_cases.status);



%% ========================================
%          PERFORMANCE / FAILURE SUMMARY
% ========================================

fprintf('\n\n========================================\n');
fprintf('       PERFORMANCE / FAILURE SUMMARY\n');
fprintf('========================================\n');

% Summarize both operating configurations.
config_names = {'CLOSED','OPEN'};
config_speeds = [v_max_c, v_max_o];
config_temps = [T_max_c, T_max_o];
config_thermal_margins = [thermal_margin_c, thermal_margin_o];
config_safety = {safety_results_c, safety_results_o};
config_vdi = {vdi_results_c, vdi_results_o};
config_gear = {gear_results_c, gear_results_o};
config_temp = {temp_results_c, temp_results_o};

for iConfig = 1:2

    fprintf('\n--- WHEEL %s ---\n',config_names{iConfig});

    fprintf('Vehicle speed:              %.3f m/s (%.2f km/h)\n', ...
        config_speeds(iConfig),3.6*config_speeds(iConfig));

    fprintf('Peak modeled gear temp:     %.2f deg C\n', ...
        config_temps(iConfig));

    fprintf('Margin to 95 C HDT screen:  %+.2f deg C\n', ...
        config_thermal_margins(iConfig));

    % Identify the hottest mesh and characteristic.
    tr = config_temp{iConfig};

    if tr.T_rp >= tr.T_sp
        hot_mesh = 'planet-ring';
        hot_mesh_temp = tr.T_rp;
    else
        hot_mesh = 'sun-planet';
        hot_mesh_temp = tr.T_sp;
    end

    fprintf('Hottest mesh:               %s (%.2f deg C)\n', ...
        hot_mesh,hot_mesh_temp);

    % Report the minimum static safety factors, if provided by gear_safety.
    sr = config_safety{iConfig};

    fprintf('Strength/fatigue assessment: %s\n', ...
        strength_assessment.status);

    % Show available numeric safety-factor fields without assuming
    % specific field names in gear_safety's output structure.
    sf_names = fieldnames(sr);
    found_sf = false;

    for iField = 1:numel(sf_names)
        field_name = sf_names{iField};
        field_value = sr.(field_name);

        if isnumeric(field_value) && isscalar(field_value) && ...
                isfinite(field_value) && ...
                contains(lower(field_name),'safety') && ...
                contains(lower(field_name),'factor')

            fprintf('  %-28s %.3f\n',field_name,field_value);
            found_sf = true;
        end
    end

    if ~found_sf
        fprintf(['  No field named with both "safety" and "factor" ' ...
            'was found in gear_safety output.\n']);
    end

    % Report provisional root-fatigue and flank-fatigue status.
    if iConfig == 1
        fprintf('Root fatigue status:        %s\n', ...
            safety_results_c.root_fatigue_status);
    else
        fprintf('Root fatigue status:        %s\n', ...
            safety_results_o.root_fatigue_status);
    end

    fprintf('Flank fatigue status:       %s\n', ...
        strength_assessment.flank_fatigue_status);

end

%% Overall screening result
fprintf('\n--- OVERALL LIMITING CONDITION ---\n');

[worst_temp,idx_worst] = max(config_temps);
worst_margin = config_thermal_margins(idx_worst);

fprintf('Thermally hottest configuration: %s\n', ...
    config_names{idx_worst});
fprintf('Predicted peak temperature:       %.2f deg C\n',worst_temp);
fprintf('Margin to 95 C HDT reference:     %+.2f deg C\n',worst_margin);

if worst_margin < 0
    fprintf(['Thermal screen: ABOVE the 95 C HDT reference by ' ...
        '%.2f deg C.\n'],abs(worst_margin));
else
    fprintf(['Thermal screen: BELOW the 95 C HDT reference by ' ...
        '%.2f deg C.\n'],worst_margin);
end

fprintf(['Note: HDT is a screening reference, not a validated ' ...
    'continuous-use temperature limit.\n']);
fprintf(['Root fatigue uses provisional coupon runout data; ' ...
    'flank fatigue life is unassessed.\n']);
fprintf(['The first physical failure mode cannot be established ' ...
    'unless all relevant limits and allowables are defined.\n']);
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
