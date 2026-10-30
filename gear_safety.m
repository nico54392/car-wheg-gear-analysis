
function safety_results = gear_safety(vdi_results, gear, T_operating, ...
    sigma_F_reference, sigma_H_reference, lambda_allow, fatigue_data)
%GEAR_SAFETY Material-specific preliminary static screens.
%
% Root members:
%   Sun    : PA12 flexural-strength reference
%   Planets: stainless-steel yield-strength reference
%   Ring   : PA12 flexural-strength reference
%
% Flank contact:
%   Reports Hertz stress but does not compare it against tensile strength.
%   A material-specific contact-yield/allowable criterion is required.
%
% Deformation:
%   Retains the VDI deformation-limit screen.
%
% Fatigue:
%   Optional PA12 coupon-runout comparison only. This is not a calibrated
%   gear-tooth S-N curve and does not predict failure life.
%
% Expected optional fields:
%   gear.sigma_F_s_PA12_Pa  : PA12 sun flexural reference (Pa)
%   gear.sigma_F_r_PA12_Pa  : PA12 ring flexural reference (Pa)
%   gear.sigma_y_p_Pa       : stainless planet yield strength (Pa)
%
% Backward compatibility:
%   sigma_F_reference is used as the PA12 reference if member-specific
%   PA12 references are not provided.
%   sigma_H_reference is retained as metadata only; it is not used as a
%   Hertz contact allowable.

if nargin < 4 || isempty(sigma_F_reference)
    sigma_F_reference = NaN;
end
if nargin < 5 || isempty(sigma_H_reference)
    sigma_H_reference = NaN;
end
if nargin < 6 || isempty(lambda_allow)
    lambda_allow = vdi_results.lambda_zul;
end
if nargin < 7 || isempty(fatigue_data)
    fatigue_data = struct();
end

%% Extract VDI results

root_sp = vdi_results.sun_planet.root;
root_rp = vdi_results.planet_ring.root;

sigma_F = [ ...
    root_sp.sun.sigma_F, ...
    root_sp.planet.sigma_F, ...
    root_rp.planet.sigma_F, ...
    root_rp.ring.sigma_F];

root_names = { ...
    'Sun root, sun-planet mesh', ...
    'Planet root, sun-planet mesh', ...
    'Planet root, planet-ring mesh', ...
    'Ring root, planet-ring mesh'};

root_materials = { ...
    'PA12', ...
    'Stainless steel', ...
    'Stainless steel', ...
    'PA12'};

sigma_H = [ ...
    vdi_results.sun_planet.sigma_H, ...
    vdi_results.planet_ring.sigma_H];

flank_names = { ...
    'Sun-planet flank', ...
    'Planet-ring flank'};

lambda = [ ...
    vdi_results.sun_planet.lambda, ...
    vdi_results.planet_ring.lambda];

%% Assign material-specific root references

% Defaults preserve compatibility with the old function signature.
sigma_F_s_PA12 = sigma_F_reference;
sigma_F_r_PA12 = sigma_F_reference;
sigma_y_p = NaN;

if isfield(gear, 'sigma_F_s_PA12_Pa') && ...
        isfinite(gear.sigma_F_s_PA12_Pa) && ...
        gear.sigma_F_s_PA12_Pa > 0
    sigma_F_s_PA12 = gear.sigma_F_s_PA12_Pa;
end

if isfield(gear, 'sigma_F_r_PA12_Pa') && ...
        isfinite(gear.sigma_F_r_PA12_Pa) && ...
        gear.sigma_F_r_PA12_Pa > 0
    sigma_F_r_PA12 = gear.sigma_F_r_PA12_Pa;
end

if isfield(gear, 'sigma_y_p_Pa') && ...
        isfinite(gear.sigma_y_p_Pa) && ...
        gear.sigma_y_p_Pa > 0
    sigma_y_p = gear.sigma_y_p_Pa;
end

root_reference = [ ...
    sigma_F_s_PA12, ...
    sigma_y_p, ...
    sigma_y_p, ...
    sigma_F_r_PA12];

root_reference_type = { ...
    'PA12 flexural-strength reference', ...
    'Stainless-steel yield-strength reference', ...
    'Stainless-steel yield-strength reference', ...
    'PA12 flexural-strength reference'};

root_utilization = NaN(size(sigma_F));
root_assessed = false(size(sigma_F));

for i = 1:numel(sigma_F)
    if isfinite(root_reference(i)) && root_reference(i) > 0 && ...
            isfinite(sigma_F(i)) && sigma_F(i) >= 0
        root_utilization(i) = 100 * sigma_F(i) / root_reference(i);
        root_assessed(i) = true;
    end
end

root_static_screen_pass = NaN;
if all(root_assessed)
    root_static_screen_pass = all(root_utilization <= 100);
end

%% Store root results

safety_results.T_operating = T_operating;
safety_results.N_p_planets = gear.N_p_planets;

safety_results.member_root_stress_Pa = sigma_F;
safety_results.member_root_names = root_names;
safety_results.member_root_materials = root_materials;
safety_results.member_root_reference_Pa = root_reference;
safety_results.member_root_reference_type = root_reference_type;
safety_results.root_utilization_percent = root_utilization;
safety_results.root_member_assessed = root_assessed;
safety_results.root_static_screen_pass = root_static_screen_pass;

safety_results.reference_root_strength_Pa = sigma_F_reference;

if all(root_assessed)
    safety_results.root_status = 'material_specific_preliminary_static_screen';
else
    safety_results.root_status = ...
        'partially_unassessed_missing_material_strength_reference';
end

%% Flank contact stress
%
% Hertz stress is not directly comparable to tensile strength. Keep the
% calculated stresses visible, but do not issue an unsupported pass/fail.

safety_results.member_flank_stress_Pa = sigma_H;
safety_results.member_flank_names = flank_names;

% Preserve the legacy argument for traceability only.
safety_results.reference_flank_strength_Pa = sigma_H_reference;
safety_results.flank_utilization_percent = NaN(size(sigma_H));
safety_results.flank_static_screen_pass = NaN;
safety_results.flank_status = ...
    'unassessed_requires_material_specific_contact_yield_criterion';

%% Deformation screen

safety_results.mesh_deformation_m = lambda;

if isfinite(lambda_allow) && lambda_allow > 0
    safety_results.deformation_utilization_percent = ...
        100 * lambda / lambda_allow;

    safety_results.deformation_screen_pass = ...
        all(safety_results.deformation_utilization_percent <= 100);

    safety_results.deformation_status = ...
        'VDI_deformation_limit_screen';
else
    safety_results.deformation_utilization_percent = NaN(size(lambda));
    safety_results.deformation_screen_pass = NaN;
    safety_results.deformation_status = 'unassessed';
end

%% Optional PA12 coupon runout screen
%
% This applies only as a provisional stress comparison. It does not
% establish gear fatigue life, and it must not be applied to steel planets.

safety_results.fatigue_source = ...
    ['TA Instruments EF037, Tensile and Fatigue Properties of ' ...
     'Additively Manufactured Polyamides'];

safety_results.fatigue_test_stress_Pa = NaN;
safety_results.fatigue_runout_cycles = NaN;
safety_results.root_cycles_to_failure_lower_bound = NaN(size(sigma_F));
safety_results.root_fatigue_status = 'unassessed_no_curve';
safety_results.flank_fatigue_status = ...
    'unassessed_no_contact_fatigue_data';
safety_results.fatigue_temperature_correction = 'none_available';

if isfield(fatigue_data, 'runout_stress_Pa') && ...
        isfield(fatigue_data, 'runout_cycles')

    s_runout = fatigue_data.runout_stress_Pa;
    n_runout = fatigue_data.runout_cycles;

    if isscalar(s_runout) && isscalar(n_runout) && ...
            isfinite(s_runout) && isfinite(n_runout) && ...
            s_runout > 0 && n_runout > 0

        safety_results.fatigue_test_stress_Pa = s_runout;
        safety_results.fatigue_runout_cycles = n_runout;

        % Only PA12 roots are eligible for this comparison.
        is_PA12_root = [true, false, false, true];
        under_runout = is_PA12_root & (sigma_F <= s_runout);

        safety_results.root_cycles_to_failure_lower_bound(under_runout) = ...
            n_runout;

        if any(under_runout)
            safety_results.root_fatigue_status = ...
                ['provisional_PA12_coupon_runout_comparison_' ...
                 'not_predicted_failure_life'];
        else
            safety_results.root_fatigue_status = ...
                'no_PA12_root_below_coupon_runout_reference';
        end
    end
end

safety_results.fatigue_life_status = safety_results.root_fatigue_status;
safety_results.overall_status = ...
    'preliminary_static_screens_contact_strength_unassessed';

%% Report

fprintf('\n=== Preliminary gear safety screen at %.1f deg C ===\n', ...
    T_operating);

fprintf('\nRoot bending stress:\n');

for i = 1:numel(sigma_F)
    if root_assessed(i)
        fprintf('  %-34s %8.2f MPa / %7.2f%% of %s\n', ...
            root_names{i}, sigma_F(i)/1e6, root_utilization(i), ...
            root_reference_type{i});
    else
        fprintf('  %-34s %8.2f MPa / NOT ASSESSED (%s reference missing)\n', ...
            root_names{i}, sigma_F(i)/1e6, root_materials{i});
    end
end

if all(root_assessed)
    if root_static_screen_pass
        fprintf('Root static screen: PASS (preliminary references only)\n');
    else
        fprintf('Root static screen: EXCEEDS at least one reference\n');
    end
else
    fprintf('Root static screen: INCOMPLETE (missing material reference)\n');
end

fprintf('\nHertz flank contact stress (no pass/fail assigned):\n');
for i = 1:numel(sigma_H)
    fprintf('  %-34s %8.2f MPa\n', ...
        flank_names{i}, sigma_H(i)/1e6);
end
fprintf('Flank status: %s\n', safety_results.flank_status);

fprintf('\nVDI deformation-limit utilization:\n');
for i = 1:numel(lambda)
    fprintf('  Mesh %d: %.2f%%\n', ...
        i, safety_results.deformation_utilization_percent(i));
end
fprintf('Deformation status: %s\n', safety_results.deformation_status);

fprintf('\nPA12 root fatigue screen: %s\n', ...
    safety_results.root_fatigue_status);
for i = [1, 4]
    if isfinite(safety_results.root_cycles_to_failure_lower_bound(i))
        fprintf('  %-34s >= %.3g coupon runout cycles; not a failure-life prediction\n', ...
            root_names{i}, ...
            safety_results.root_cycles_to_failure_lower_bound(i));
    end
end
fprintf('Flank fatigue: not assessed (no contact-fatigue curve).\n');
fprintf('Fatigue source temperature is unspecified; no temperature correction applied.\n');

end
