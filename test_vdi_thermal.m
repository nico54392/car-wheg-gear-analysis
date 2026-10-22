
%% TEST_VDI_THERMAL
% Standalone unit/implementation check for the VDI 2736
% root and flank temperature helper functions.
%
% Scenario inspired by the published steel/POM gear example:
% 20/40 teeth, module 1 mm, face width 20 mm,
% pinion torque 0.4 N*m at 1000 rpm.
%
% IMPORTANT:
% This is NOT an exact reproduction of the published result.
% mu, H_V, and the thermal coefficients below are test inputs;
% verify them against the reference before comparing temperatures.

clear; clc;

%% Published example's mechanical inputs
T_ambient = 23;             % [deg C]
T_torque  = 0.4;            % [N*m]
n_rpm     = 1000;           % [rpm]
P         = T_torque * 2*pi*n_rpm/60; % [W]

b_mm = 20;                  % [mm]
b_m  = b_mm * 1e-3;         % [m], helper input
z    = 40;                  % [teeth on plastic gear]
v    = pi * 0.020 * n_rpm/60; % [m/s], 20 mm pinion pitch diameter
m_mm = 1;                   % [mm]

%% Thermal inputs (test values, NOT verified example values)

%% Axomek published example: steel pinion / POM wheel
T_ambient = 23;       % deg C
P = 0.4 * 2*pi*1000/60; % W
b_mm = 20;
b_m = b_mm/1000;
z = 40;
v = pi*0.020*1000/60; % m/s
m_mm = 1;

mu = 0.09;            % Published greased-pair value
H_V = 0.1616;         % INFERRED for approximate reproduction,
                      % not published by Axomek
k_theta_root = 900;
k_theta_flank = 6300;
R_lambda_G = 0;       % Open housing: simplified test
A_G = 1;
ED = 1;

T_root = vdi2736_root_temperature( ...
    T_ambient,mu,P,H_V,k_theta_root,...
    b_m,z,v,m_mm,R_lambda_G,A_G,ED);

T_flank = vdi2736_flank_temperature( ...
    T_ambient,mu,P,H_V,k_theta_flank,...
    b_m,z,v,m_mm,R_lambda_G,A_G,ED);

fprintf('Root temperature:  %.2f C\n',T_root);
fprintf('Flank temperature: %.2f C\n',T_flank);
fprintf('Published flank reference: 27.8 C\n');
%% Call your existing functions
T_root = vdi2736_root_temperature( ...
    T_ambient, mu, P, H_V, k_theta_root, ...
    b_m, z, v, m_mm, R_lambda_G, A_G, ED);

T_flank = vdi2736_flank_temperature( ...
    T_ambient, mu, P, H_V, k_theta_flank, ...
    b_m, z, v, m_mm, R_lambda_G, A_G, ED);

%% Independently calculate the same equations
% Convert face width from m to mm exactly once.
b_check_mm = b_m * 1e3;

T_root_manual = T_ambient + mu*P*H_V * ...
    (k_theta_root/(b_check_mm*z*(v*m_mm)^0.75) ...
    + R_lambda_G/A_G) * ED^0.64;

T_flank_manual = T_ambient + mu*P*H_V * ...
    (k_theta_flank/(b_check_mm*z*(v*m_mm)^0.75) ...
    + R_lambda_G/A_G) * ED^0.64;


%% Report
fprintf('\n===== VDI THERMAL HELPER TEST =====\n');
fprintf('Nominal power:             %.3f W\n', P);
fprintf('Pitch-line velocity:       %.4f m/s\n', v);
fprintf('Face width:                %.1f mm\n', b_check_mm);
fprintf('Root temperature (helper): %.3f deg C\n', T_root);
fprintf('Root temperature (manual): %.3f deg C\n', T_root_manual);
fprintf('Flank temp (helper):       %.3f deg C\n', T_flank);
fprintf('Flank temp (manual):       %.3f deg C\n', T_flank_manual);

assert(abs(T_root - T_root_manual) < 1e-10, ...
    'Root helper differs from manual equation.');
assert(abs(T_flank - T_flank_manual) < 1e-10, ...
    'Flank helper differs from manual equation.');

fprintf('\nPASS: helper functions match the manual equations.\n');
fprintf('NOTE: This validates implementation consistency only,\n');
fprintf('not the physical accuracy of the model or test inputs.\n');
