function w = thermal_check(gear, geom, T_stall, omega_0, th, crit, test_points)
%THERMAL_CHECK PA12 temperature for short research tests.
%
% Source IDs: VDI2 Eq. 7/9; limits OD20 (Tg), HP-DS (HDT, melt); criteria PROJ.
% Pass/fail: each test operating point (carrier torque, speed) with the
% gears running the whole test (ED = 1). VDI Eq. (7)/(9) give the steady
% temperature, so a short test runs cooler: this is an upper bound.
%
% Envelope (warning, not pass/fail): the same calc swept along the whole
% motor line T_c = T_stall*(1 - w/w0). Heat goes as P/v^0.75 ~ T*w^0.25,
% so the hottest point is at low speed and high torque (about 0.2*w0),
% i.e. pushing against something near stall for a long time.
%
% Graded on the hottest PA12 value, which is always the flank: VDI Eq. (9)
% compares flank temperature to the permissible temperature. The root
% value (closer to the bulk tooth temperature, ~7x smaller rise) is
% returned alongside as T_root.
%
% Status against PA12 limits (crit):
%   PASS     T <  crit.T_soft   (Tg; PA12 near its 23 C properties)
%   CAUTION  T_soft..T_limit    (softer and weaker, but holding shape)
%   FAIL     T >  crit.T_limit  (HDT at 1.82 MPa)
% Only PA12 members (sun, ring) count; the steel planets don't soften here.
%
% th:          .T_ambient .mu .k_theta_root .k_theta_flank .R_lambda_G .A_G
% test_points: n x 2, [T_c (N*m), omega_c (rad/s)] per row
% Each row of test_points can carry a name via th.test_names (cellstr).

if isfield(th,'test_names'), names = th.test_names;
else, names = arrayfun(@(k) sprintf('point %d',k),1:size(test_points,1),'UniformOutput',false);
end

% Pass/fail at the test points
w.tests = struct('name',{},'T_c',{},'omega_c',{},'T_max',{},'T_root',{},'hot_part',{},'status',{});
for k = 1:size(test_points,1)
    [Tm, part, Tr] = pa12_temp(test_points(k,1), test_points(k,2), gear, geom, th);
    w.tests(k).name = names{k};
    w.tests(k).T_c = test_points(k,1);
    w.tests(k).omega_c = test_points(k,2);
    w.tests(k).T_max = Tm;
    w.tests(k).T_root = Tr;
    w.tests(k).hot_part = part;
    w.tests(k).status = grade(Tm, crit);
end
[w.T_max, kmax] = max([w.tests.T_max]);
w.status = w.tests(kmax).status;
w.pass = ~strcmp(w.status,'FAIL');

% Envelope along the motor line
x = linspace(0.02, 0.98, 49);
T_env = zeros(size(x));
T_env_root = zeros(size(x));
for i = 1:numel(x)
    [T_env(i), ~, T_env_root(i)] = pa12_temp(T_stall*(1 - x(i)), x(i)*omega_0, gear, geom, th);
end
[w.env.T_max, ke] = max(T_env);
w.env.x = x;
w.env.T = T_env;
w.env.T_root = T_env_root;
w.env.T_root_at_max = T_env_root(ke);
w.env.omega_c = x(ke)*omega_0;
w.env.carrier_rpm = w.env.omega_c*60/(2*pi);
w.env.T_c = T_stall*(1 - x(ke));
w.env.status = grade(w.env.T_max, crit);
% Carrier speed range where running continuously
% would go over HDT
over = x(T_env > crit.T_limit);
if isempty(over)
    w.env.over_HDT_rpm = [];
else
    w.env.over_HDT_rpm = [min(over) max(over)]*omega_0*60/(2*pi);
end

w.ED = 1.0;
w.T_soft = crit.T_soft;
w.T_limit = crit.T_limit;
w.T_melt = crit.T_melt;

end


function [Tm, part, Tr] = pa12_temp(T_c, omega_c, gear, geom, th)
% PA12 member temperature at one operating point, ED = 1.
% Local function (not nested) so evalc can create variables in MATLAB.
evalc('g = planetary_gear(0, 0, T_c, omega_c, gear, geom);');
evalc('v = vdi2736(g, gear, geom);');
evalc(['t = gear_temperature(v, gear, th.T_ambient, th.mu, th.k_theta_root, ' ...
    'th.R_lambda_G, th.A_G, 1.0, th.k_theta_flank);']);
parts = [t.sun_planet.sun.root, t.sun_planet.sun.flank, ...
    t.planet_ring.ring.root, t.planet_ring.ring.flank];
part_names = {'sun root','sun flank','ring root','ring flank'};
[Tm, kp] = max(parts);
part = part_names{kp};
Tr = max(parts([1 3]));   % sun root, ring root
end


function st = grade(T, crit)
if T < crit.T_soft
    st = 'PASS';
elseif T <= crit.T_limit
    st = 'CAUTION';
else
    st = 'FAIL';
end
end
