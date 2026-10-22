function gear_results = planetary_gear(omega_q, T_q, T_c, omega_c, gear, geom)
%PLANETARY_GEAR Fixed-ring planetary kinematics and equal load sharing.
% Forces named *_total act across the complete planetary stage. Forces
% named *_planet are the load on one mesh and are used for gear stresses.

if nargin < 6
    geom = geometry_calc(gear);
end
N_s = gear.N_s;
N_r = gear.N_r1_i;
N_p = gear.N_p;
N_planets = gear.N_p_planets;
if N_planets < 1 || N_planets ~= floor(N_planets)
    error('gear.N_p_planets must be a positive integer.');
end
if ~geom.valid_planetary_geometry
    error('Planetary pitch geometry does not close.');
end

% Fixed ring and Willis relation.
omega_r = 0;
omega_s = omega_c + (N_r/N_s)*(omega_c - omega_r);
omega_p_rel = -(N_s/N_p)*(omega_s - omega_c);
omega_p_wld = omega_p_rel + omega_c;

if abs(omega_s) > eps
    T_s = -T_c*omega_c/omega_s;
else
    T_s = NaN;
end
T_r = -(T_s + T_c);

F_t_s_total = abs(T_s)/geom.r_sw_m;
F_t_r_total = abs(T_r)/geom.r_rw_m;
F_t_s_planet = F_t_s_total/N_planets;
F_t_r_planet = F_t_r_total/N_planets;

P_s = T_s*omega_s;
P_r = T_r*omega_r;
P_c = T_c*omega_c;

gear_results.omega_q = omega_q;
gear_results.T_q = T_q;
gear_results.omega_s = omega_s;
gear_results.T_s = T_s;
gear_results.omega_r1 = omega_r;
gear_results.T_r1 = T_r;
gear_results.omega_p1_rel = omega_p_rel;
gear_results.omega_p1_wld = omega_p_wld;
gear_results.omega_o_1 = omega_c;
gear_results.omega_o_2 = omega_c;
gear_results.T_o_2 = -T_c;
gear_results.omega_rel = 0;
gear_results.T_c = T_c;
gear_results.P_s = P_s;
gear_results.P_r1 = P_r;
gear_results.P_c = P_c;
gear_results.P_error = P_s + P_r + P_c;
gear_results.N_p_planets = N_planets;
gear_results.a_sp_working_m = geom.a_sp_m;
gear_results.a_rp_working_m = geom.a_rp_m;
gear_results.alpha_w_sp = geom.alpha_w_sp;
gear_results.alpha_w_rp = geom.alpha_w_rp;
gear_results.r_s_working_m = geom.r_sw_m;
gear_results.r_p_working_sp_m = geom.r_pw_sp_m;
gear_results.r_p_working_rp_m = geom.r_pw_rp_m;
gear_results.r_r_working_m = geom.r_rw_m;
gear_results.F_t_s_p = F_t_s_planet; % compatibility: force on one planet
gear_results.F_t_r_p = F_t_r_planet;
gear_results.F_t_s_planet = F_t_s_planet;
gear_results.F_t_r_planet = F_t_r_planet;
gear_results.F_t_s_total = F_t_s_total;
gear_results.F_t_r_total = F_t_r_total;
gear_results.F_t_c_p = F_t_s_planet + F_t_r_planet;

fprintf('\n=== Fixed ring planetary gear (%d planets, equal sharing) ===\n',N_planets);
fprintf('Carrier torque/speed: %.4f N*m, %.4f rad/s\n',T_c,omega_c);
fprintf('Sun torque/speed:     %.4f N*m, %.4f rad/s\n',T_s,omega_s);
fprintf('Sun mesh force:       %.4f N total, %.4f N/planet\n',F_t_s_total,F_t_s_planet);
fprintf('Ring mesh force:      %.4f N total, %.4f N/planet\n',F_t_r_total,F_t_r_planet);
fprintf('Power balance error:  %.4e W\n',gear_results.P_error);
end
