function safety_results = gear_safety(vdi_results, gear, T_operating, ...
    sigma_F_reference, sigma_H_reference, lambda_allow, fatigue_data)
%GEAR_SAFETY Static screens plus a deliberately limited PA12 root runout screen.
% Root/static references are flexural strength; flank reference is a tensile
% proxy. The optional fatigue data is based on an SLS PA12 tensile (test temperature unspecified)
% coupon runout and is not a calibrated gear-tooth S-N curve.
if nargin < 4 || isempty(sigma_F_reference), sigma_F_reference = NaN; end
if nargin < 5 || isempty(sigma_H_reference), sigma_H_reference = NaN; end
if nargin < 6 || isempty(lambda_allow), lambda_allow = vdi_results.lambda_zul; end
if nargin < 7, fatigue_data = struct(); end
root = vdi_results.sun_planet.root;
ring = vdi_results.planet_ring.root;
sigma_F = [root.sun.sigma_F,root.planet.sigma_F, ...
    ring.planet.sigma_F,ring.ring.sigma_F];
root_names = {'Sun root, sun-planet mesh','Planet root, sun-planet mesh', ...
    'Planet root, planet-ring mesh','Ring root, planet-ring mesh'};
sigma_H = [vdi_results.sun_planet.sigma_H,vdi_results.planet_ring.sigma_H];
flank_names = {'Sun-planet flank','Planet-ring flank'};
lambda = [vdi_results.sun_planet.lambda,vdi_results.planet_ring.lambda];

safety_results.T_operating = T_operating;
safety_results.N_p_planets = gear.N_p_planets;
safety_results.member_root_stress_Pa = sigma_F;
safety_results.member_root_names = root_names;
safety_results.member_flank_stress_Pa = sigma_H;
safety_results.member_flank_names = flank_names;
safety_results.mesh_deformation_m = lambda;
safety_results.reference_root_strength_Pa = sigma_F_reference;
safety_results.reference_flank_strength_Pa = sigma_H_reference;
safety_results.root_utilization_percent = NaN(size(sigma_F));
safety_results.flank_utilization_percent = NaN(size(sigma_H));
safety_results.root_status = 'unassessed';
safety_results.flank_status = 'unassessed';
if isfinite(sigma_F_reference) && sigma_F_reference > 0
    safety_results.root_utilization_percent = 100*sigma_F/sigma_F_reference;
    safety_results.root_static_screen_pass = all(safety_results.root_utilization_percent <= 100);
    safety_results.root_status = 'static_reference_screen_only';
end
if isfinite(sigma_H_reference) && sigma_H_reference > 0
    safety_results.flank_utilization_percent = 100*sigma_H/sigma_H_reference;
    safety_results.flank_static_screen_pass = all(safety_results.flank_utilization_percent <= 100);
    safety_results.flank_status = 'static_reference_proxy_only';
end
if isfinite(lambda_allow) && lambda_allow > 0
    safety_results.deformation_utilization_percent = 100*lambda/lambda_allow;
    safety_results.deformation_screen_pass = all(safety_results.deformation_utilization_percent <= 100);
    safety_results.deformation_status = 'VDI_deformation_limit_screen';
else
    safety_results.deformation_utilization_percent = NaN(size(lambda));
    safety_results.deformation_screen_pass = NaN;
    safety_results.deformation_status = 'unassessed';
end

% TA Instruments EF037 SLS PA12 tensile coupons: all specimens ran out at
% 25 MPa through 1e7 cycles. Project an >=runout lower bound below that stress
% only under monotonic S-N behavior. This is not a gear-fatigue prediction;
% no temperature correction is available, and flank contact is not assessed.
safety_results.fatigue_source = 'TA Instruments EF037, Tensile and Fatigue Properties of Additively Manufactured Polyamides';
safety_results.fatigue_test_stress_Pa = NaN;
safety_results.fatigue_runout_cycles = NaN;
safety_results.root_cycles_to_failure_lower_bound = NaN(size(sigma_F));
safety_results.root_fatigue_status = 'unassessed_no_curve';
safety_results.flank_fatigue_status = 'unassessed_no_contact_fatigue_data';
safety_results.fatigue_temperature_correction = 'none_available';
if isfield(fatigue_data,'runout_stress_Pa') && isfield(fatigue_data,'runout_cycles')
    s_runout = fatigue_data.runout_stress_Pa;
    n_runout = fatigue_data.runout_cycles;
    if isscalar(s_runout) && isscalar(n_runout) && s_runout > 0 && n_runout > 0
        safety_results.fatigue_test_stress_Pa = s_runout;
        safety_results.fatigue_runout_cycles = n_runout;
        underRunout = sigma_F <= s_runout;
        safety_results.root_cycles_to_failure_lower_bound(underRunout) = n_runout;
        if any(underRunout)
            safety_results.root_fatigue_status = 'provisional_runout_projection_test_temperature_unspecified_not_failure_life';
        else
            safety_results.root_fatigue_status = 'stress_above_coupon_runout_reference_unassessed';
        end
    end
end
safety_results.fatigue_life_status = safety_results.root_fatigue_status;
safety_results.overall_status = 'static_screen_plus_provisional_runout_projection';

fprintf('\n=== Static stress screen at %.1f deg C ===\n',T_operating);
fprintf('Root stress / flexural-strength reference (not fatigue allowable):\n');
for i = 1:numel(sigma_F)
    fprintf('  %-38s %.2f MPa / %.2f%%\n',root_names{i}, ...
        sigma_F(i)/1e6,safety_results.root_utilization_percent(i));
end
fprintf('Flank contact / tensile-strength proxy:\n');
for i = 1:numel(sigma_H)
    fprintf('  %-38s %.2f MPa / %.2f%%\n',flank_names{i}, ...
        sigma_H(i)/1e6,safety_results.flank_utilization_percent(i));
end
fprintf('VDI deformation-limit utilization: %.2f%% / %.2f%%\n', ...
    safety_results.deformation_utilization_percent(1), ...
    safety_results.deformation_utilization_percent(2));
fprintf('Root fatigue screen from SLS PA12 coupon runout: %s\n', ...
    safety_results.root_fatigue_status);
for i = 1:numel(sigma_F)
    if isfinite(safety_results.root_cycles_to_failure_lower_bound(i))
        fprintf('  %-38s >= %.3g cycles (runout lower bound; not failure life)\n', ...
            root_names{i},safety_results.root_cycles_to_failure_lower_bound(i));
    end
end
fprintf('Flank fatigue life: not assessed (no contact-fatigue curve).\n');
fprintf('Source test temperature is unspecified; no temperature correction is available.\n');
end


