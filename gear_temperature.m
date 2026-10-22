function temp_results = gear_temperature(vdi_results, gear, ...
    T_ambient, mu_gear, k_theta_root, R_lambda_G, A_G, ED, k_theta_flank)
%GEAR_TEMPERATURE VDI characteristic root/flank temperatures, Eqs. (7) and (9).
% These are distinct rating quantities for root-bending and flank capacity;
% they are not two measurements of one uniform bulk gear temperature.
% k_theta_root and k_theta_flank use the VDI table units
% [K*(m/s)^0.75*mm^1.75]. VDI's single-pair model is applied per physical
% gear member: sun/ring see the sum over the three meshes; each planet sees
% one mesh's share. This member-level planetary mapping is an explicit model
% assumption and should be revisited if heat spreading is modeled in detail.
if nargin < 9 || isempty(k_theta_flank)
    error('Supply the separate VDI flank heat-transfer coefficient k_theta_flank.');
end
if ED < 0 || ED > 1
    error('ED must be a fraction in [0,1].');
end
m = gear.mod; % [mm]
nPlanet = gear.N_p_planets;
if nPlanet ~= vdi_results.N_p_planets || nPlanet < 1 || nPlanet ~= floor(nPlanet)
    error('gear_temperature: gear and VDI results must use the same positive integer planet count.');
end

% Sun-planet member temperatures. The sun participates in all meshes;
% each planet participates in one of the equal-share mesh pairs.
PspTotal = abs(vdi_results.P_sp_total);
PspPlanet = abs(vdi_results.P_sp_per_planet);
PspMember = [PspTotal,PspPlanet];
zspMember = [gear.N_s,gear.N_p];
bsp = vdi_results.b_sp;
v = vdi_results.v_sp;
H = vdi_results.H_V_sp;
temp_results.sun_planet.sun.root = vdi2736_root_temperature(T_ambient,...
    mu_gear,PspMember(1),H,k_theta_root,bsp,zspMember(1),v,m,R_lambda_G,A_G,ED);
temp_results.sun_planet.planet.root = vdi2736_root_temperature(T_ambient,...
    mu_gear,PspMember(2),H,k_theta_root,bsp,zspMember(2),v,m,R_lambda_G,A_G,ED);
temp_results.sun_planet.sun.flank = vdi2736_flank_temperature(T_ambient,...
    mu_gear,PspMember(1),H,k_theta_flank,bsp,zspMember(1),v,m,R_lambda_G,A_G,ED);
temp_results.sun_planet.planet.flank = vdi2736_flank_temperature(T_ambient,...
    mu_gear,PspMember(2),H,k_theta_flank,bsp,zspMember(2),v,m,R_lambda_G,A_G,ED);

% Planet-ring members; same planet temperature model with planet-ring mesh
% losses and ring total power distributed among the ring's circumference.
PrpTotal = abs(vdi_results.P_rp_total);
PrpPlanet = abs(vdi_results.P_rp_per_planet);
PrpMember = [PrpPlanet,PrpTotal];
zrpMember = [gear.N_p,gear.N_r1_i];
brp = vdi_results.b_rp;
v = vdi_results.v_rp;
H = vdi_results.H_V_rp;
temp_results.planet_ring.planet.root = vdi2736_root_temperature(T_ambient,...
    mu_gear,PrpMember(1),H,k_theta_root,brp,zrpMember(1),v,m,R_lambda_G,A_G,ED);
temp_results.planet_ring.ring.root = vdi2736_root_temperature(T_ambient,...
    mu_gear,PrpMember(2),H,k_theta_root,brp,zrpMember(2),v,m,R_lambda_G,A_G,ED);
temp_results.planet_ring.planet.flank = vdi2736_flank_temperature(T_ambient,...
    mu_gear,PrpMember(1),H,k_theta_flank,brp,zrpMember(1),v,m,R_lambda_G,A_G,ED);
temp_results.planet_ring.ring.flank = vdi2736_flank_temperature(T_ambient,...
    mu_gear,PrpMember(2),H,k_theta_flank,brp,zrpMember(2),v,m,R_lambda_G,A_G,ED);

allRoot = [temp_results.sun_planet.sun.root, ...
    temp_results.sun_planet.planet.root, ...
    temp_results.planet_ring.planet.root, ...
    temp_results.planet_ring.ring.root];
allFlank = [temp_results.sun_planet.sun.flank, ...
    temp_results.sun_planet.planet.flank, ...
    temp_results.planet_ring.planet.flank, ...
    temp_results.planet_ring.ring.flank];
temp_results.T_root_max = max(allRoot);
temp_results.T_flank_max = max(allFlank);
temp_results.T_characteristic_max = max([allRoot,allFlank]);
% Legacy alias: this is the greatest VDI characteristic temperature, not a
% measured or spatially uniform bulk temperature of the entire gear.
temp_results.T_max = temp_results.T_characteristic_max;
% Compatibility fields: greater root/flank characteristic value per mesh.
temp_results.T_sp = max([temp_results.sun_planet.sun.root, ...
    temp_results.sun_planet.planet.root,temp_results.sun_planet.sun.flank, ...
    temp_results.sun_planet.planet.flank]);
temp_results.T_rp = max([temp_results.planet_ring.planet.root, ...
    temp_results.planet_ring.ring.root,temp_results.planet_ring.planet.flank, ...
    temp_results.planet_ring.ring.flank]);
temp_results.model_note = ['VDI single-pair temperature equations applied to ' ...
    'member-level planetary powers; sun/ring total and planet per-mesh power.'];
temp_results.assumptions.planetary_heat_distribution = true;
temp_results.inputs.k_theta_root = k_theta_root;
temp_results.inputs.k_theta_flank = k_theta_flank;
temp_results.inputs.mu = mu_gear;
temp_results.inputs.ED = ED;

fprintf('\n=== Gear temperature (VDI 2736 Eqs. 7 and 9) ===\n');
fprintf('Sun-planet max member temperature: %.2f deg C\n',temp_results.T_sp);
fprintf('Planet-ring max member temperature: %.2f deg C\n',temp_results.T_rp);
fprintf('Root / flank maxima: %.2f / %.2f deg C\n', ...
    temp_results.T_root_max,temp_results.T_flank_max);
fprintf('Highest root/flank characteristic: %.2f deg C\n', ...
    temp_results.T_characteristic_max);
fprintf('Assumed duty fraction ED: %.3f\n',ED);
end
