function cases = gear_interference_cases(gear, tol)
%GEAR_INTERFERENCE_CASES Worst-case backlash/interference tolerance stack.
% Tolerance inputs are +/- half-widths in mm. Tooth-thickness deviations
% are circumferential deviations at the reference circle. Planet radial
% position is positive outward from the gearbox axis.
%
% This is a geometric screening calculation, not an elastic preload model.
% It reports possible negative backlash but does not add preload to VDI
% tooth stress, fatigue, or temperature calculations.

required = {'sun_tooth_thickness_mm','planet_tooth_thickness_mm', ...
    'ring_tooth_thickness_mm','planet_radial_position_mm'};
for k = 1:numel(required)
    name = required{k};
    if ~isfield(tol,name) || ~isscalar(tol.(name)) || ...
            ~isfinite(tol.(name)) || tol.(name) < 0
        error('gear_interference_cases:BadTolerance', ...
            'Tolerance %s must be a finite nonnegative +/- half-width in mm.',name);
    end
end

if ~isfield(gear,'alpha') || ~isscalar(gear.alpha) || ...
        ~isfinite(gear.alpha) || gear.alpha <= 0 || gear.alpha >= pi/2
    error('gear_interference_cases:BadPressureAngle', ...
        'gear.alpha must be a finite pressure angle in radians between 0 and pi/2.');
end

j0_sp = get_value(tol,'nominal_backlash_sp_mm',0);
j0_rp = get_value(tol,'nominal_backlash_rp_mm',0);
if any(~isfinite([j0_sp,j0_rp])) || any([j0_sp,j0_rp] < 0)
    error('gear_interference_cases:BadNominalBacklash', ...
        'Nominal backlash values must be finite and nonnegative in mm.');
end

ts = tol.sun_tooth_thickness_mm;
tp = tol.planet_tooth_thickness_mm;
tr = tol.ring_tooth_thickness_mm;
dr = tol.planet_radial_position_mm;
alpha = gear.alpha;

% Approximate involute backlash change: delta_j = 2*delta_a*tan(alpha)
% minus the combined increase in mating tooth thickness. An outward planet
% shift increases the sun/planet center distance but reduces the radial
% center-distance difference of the planet/ring mesh.
cases.nominal.sun_planet_backlash_mm = j0_sp;
cases.nominal.planet_ring_backlash_mm = j0_rp;

% Worst interference is evaluated independently for each mesh because a
% single planet cannot move inward and outward at the same time.
cases.max_interference.sun_planet_backlash_mm = ...
    j0_sp - 2*dr*tan(alpha) - (ts+tp);
cases.max_interference.planet_ring_backlash_mm = ...
    j0_rp - 2*dr*tan(alpha) - (tp+tr);
cases.min_interference.sun_planet_backlash_mm = ...
    j0_sp + 2*dr*tan(alpha) + (ts+tp);
cases.min_interference.planet_ring_backlash_mm = ...
    j0_rp + 2*dr*tan(alpha) + (tp+tr);

labels = {'nominal','max_interference','min_interference'};
for i = 1:numel(labels)
    label = labels{i};
    for mesh = {'sun_planet','planet_ring'}
        mesh_name = mesh{1};
        backlash_name = [mesh_name '_backlash_mm'];
        interference_name = [mesh_name '_interference_mm'];
        cases.(label).(interference_name) = max(0,-cases.(label).(backlash_name));
    end
end
cases.status = ['Geometric tolerance stack only. Negative backlash does not ' ...
    'feed elastic preload into VDI stress, fatigue, or temperature results.'];
end

function value = get_value(s,field,default_value)
if isfield(s,field)
    value = s.(field);
else
    value = default_value;
end
if ~isscalar(value)
    error('gear_interference_cases:BadValue', ...
        'Input %s must be a scalar.',field);
end
end
