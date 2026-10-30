function s = static_peak_check(vdi_ref, gear, T_c_peak, crit)
%STATIC_PEAK_CHECK Pass/fail tooth strength at the peak carrier torque.
%
% Research-use criterion: the gears must survive the largest torque the
% motor can put on the carrier (stall), once, without breaking or yielding.
%
% Root: VDI 2736-2 Section 3.3, Eq. (23)/(24)
%   sigma_F,s = YFa*YSa*Ybeta*Yeps * F_t,sp/(b*m)      (no K_F, peak used directly)
%   sigma_FP,s = 2.0*sigma_S/S_Smin                      (2.0 = local yielding, plastics)
%   Steel planets use sigma_y/S_Smin, without the plastic 2.0 factor.
%
% Flank: VDI has no static flank check. Project screen based on first
% subsurface yield for line contact, p0 = 1.67*sigma_S (Johnson, Contact
% Mechanics), checked on the PA12 side:
%   PASS      sigma_H <= 1.67*sigma_S/S_Smin
%   MARGINAL  below 1.67*sigma_S but inside the safety factor: a stall may
%             leave a small permanent mark on the flank, the tooth won't break
%   FAIL      sigma_H > 1.67*sigma_S
%
% Deformation at the peak is reported for information (VDI 0.07*m is a
% running-quality guide, not a strength limit).
%
% YFa, YSa, Yeps, Z factors don't depend on load, so they're reused from a
% normal vdi2736 run (vdi_ref). Only the force changes.
%
% Inputs
%   vdi_ref  - vdi2736 output from any operating point
%   gear     - gear struct from main.m
%   T_c_peak - peak carrier torque [N*m]
%   crit     - .sigma_S_PA12 [Pa], .sigma_y_steel [Pa], .S_Smin [-]

N = gear.N_p_planets;
m = gear.mod*1e-3;                       % [m]
r_s = gear.N_s*gear.mod/2*1e-3;          % [m]
r_r = gear.N_r1_i*gear.mod/2*1e-3;       % [m]
d_p = gear.N_p*gear.mod*1e-3;            % [m], smaller gear in both meshes

% Ring fixed: torque balance only, valid at zero speed too.
T_s = T_c_peak/(1 + gear.N_r1_i/gear.N_s);
T_r = T_c_peak - T_s;
F_sp = abs(T_s)/r_s/N;                   % per planet, reference circle (VDI Eq. 2)
F_rp = abs(T_r)/r_r/N;

sp = vdi_ref.sun_planet;
rp = vdi_ref.planet_ring;
b_sp = vdi_ref.b_sp;
b_rp = vdi_ref.b_rp;

% Root stress at peak, VDI Eq. (23)
sig_F = [ ...
    sp.sun.YFa   *sp.sun.YSa   *sp.Ybeta*sp.Yepsilon*F_sp/(b_sp*m), ...
    sp.planet.YFa*sp.planet.YSa*sp.Ybeta*sp.Yepsilon*F_sp/(b_sp*m), ...
    rp.planet.YFa*rp.planet.YSa*rp.Ybeta*rp.Yepsilon*F_rp/(b_rp*m), ...
    rp.ring.YFa  *rp.ring.YSa  *rp.Ybeta*rp.Yepsilon*F_rp/(b_rp*m)];
names_F = {'Sun root (PA12)','Planet root, sp (steel)', ...
    'Planet root, rp (steel)','Ring root (PA12)'};
allow_F = [ ...
    2.0*crit.sigma_S_PA12/crit.S_Smin, ...
    crit.sigma_y_steel/crit.S_Smin, ...
    crit.sigma_y_steel/crit.S_Smin, ...
    2.0*crit.sigma_S_PA12/crit.S_Smin];

% Flank Hertz pressure at peak (VDI Eq. 14 form, no K_H). Internal mesh uses (u-1).
sig_H = [ ...
    sp.ZE*sp.ZH*sp.Zepsilon*sp.Zbeta*sqrt(F_sp/(b_sp*d_p)*(sp.u+1)/sp.u), ...
    rp.ZE*rp.ZH*rp.Zepsilon*rp.Zbeta*sqrt(F_rp/(b_rp*d_p)*(rp.u-1)/rp.u)];
names_H = {'Sun-planet flank (PA12 side)','Planet-ring flank (PA12 side)'};
allow_H = 1.67*crit.sigma_S_PA12/crit.S_Smin*[1 1];

% Deformation at peak scales linearly with force (VDI Eq. 22).
lambda = [sp.lambda*F_sp/sp.F_t, rp.lambda*F_rp/rp.F_t];

s.T_c_peak = T_c_peak;
s.T_s_peak = T_s;
s.F_t_sp = F_sp;
s.F_t_rp = F_rp;
s.root.names = names_F;
s.root.sigma = sig_F;
s.root.allow = allow_F;
s.root.margin = allow_F./sig_F;           % >= 1 passes (S_Smin already inside allow)
s.root.pass = sig_F <= allow_F;
s.flank.names = names_H;
s.flank.sigma = sig_H;
s.flank.allow = allow_H;
s.flank.margin = allow_H./sig_H;
s.flank.first_yield = 1.67*crit.sigma_S_PA12*[1 1];
s.flank.status = repmat({'PASS'},1,2);
s.flank.status(sig_H > allow_H) = {'MARGINAL'};
s.flank.status(sig_H > s.flank.first_yield) = {'FAIL'};
s.flank.pass = ~strcmp(s.flank.status,'FAIL');
s.lambda = lambda;
s.lambda_zul = vdi_ref.lambda_zul;
s.S_Smin = crit.S_Smin;
s.pass = all(s.root.pass) && all(s.flank.pass);
if ~s.pass
    s.status = 'FAIL';
elseif any(strcmp(s.flank.status,'MARGINAL'))
    s.status = 'MARGINAL';
else
    s.status = 'PASS';
end
s.note = ['YFa/YSa are the shared placeholder values from vdi2736.m; ' ...
    'sigma_S for PA12 is the 23 C tensile strength (MJF PA12 has no distinct yield).'];
end
