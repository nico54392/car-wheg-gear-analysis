%% Simply supported steel shaft and PLA bearing holes: static point load
% Edit the inputs below. SI units: m, N, Pa, rpm.
% Assumes the shaft rotates under a stationary transverse load, giving fully
% reversed surface bending stress. Fatigue life uses an estimated S-N curve.

clear; clc;

%% Inputs
d        = 0.003;       % shaft diameter [m]
L_gap    = 0.0102;      % gap between bearing supports [m]
L_shaft  = 0.016;       % overall shaft length [m]
l_a      = 0.003;       % distance from shaft end to start of load region [m]
l_b      = 0.010;       % length of load region [m]
l_s1     = 0.0036;      % axial length of bearing support 1 [m]
l_s2     = (L_shaft-L_gap)-l_s1; % axial length of bearing support 2 [m]
xi       = l_a + 0.5*l_b - 0.5*l_s1; % load center from support 1 center [m]
x2       = L_shaft - (l_a + 0.5*l_b) - 0.5*l_s2; % load to support 2 center [m]
F        = 218.6;       % downward point force [N]
rpm      = 0;           % speed [rev/min]; set 0 if not rotating

E        = 210e9;       % Young's modulus [Pa]
Sut      = 600e6;       % ultimate tensile strength [Pa]
Sy       = 350e6;       % yield strength [Pa]
SePrime  = 0.5*Sut;     % unmodified endurance limit estimate [Pa]
Sy_PLA   = 45e6;        % PLA compressive yield strength [Pa]; replace with tested value

% Marin factors; adjust for actual material, finish, size, and service.
k_surface     = 0.85;
k_size        = 0.90;
k_load        = 1.00;
k_temperature = 1.00;
k_reliability = 0.868;  % approximately 95% reliability
k_misc        = 1.00;

%% Geometry and section properties
L_span = xi + x2;       % bearing-center span [m], distinct from overall shaft length
if d <= 0 || xi <= 0 || x2 <= 0 || l_s1 <= 0 || l_s2 <= 0 || F < 0
    error('Require positive diameter, distances, and bearing lengths; F must be >= 0.');
end
a = xi;
b = x2;
I = pi*d^4/64;          % second moment of area [m^4]
c = d/2;

%% Reactions, bending stress, and static yield factor
RA = F*b/L_span;        % upward reaction at support 1 [N]
RB = F*a/L_span;        % upward reaction at support 2 [N]
Mmax = F*a*b/L_span;    % maximum bending moment at the force [N*m]
sigmaB = Mmax*c/I;      % maximum nominal bending stress [Pa]
n_yield = Sy/sigmaB;

%% Average bearing pressure on the PLA hole walls
% Projected bearing area = shaft diameter x axial support length. This assumes
% each reaction is spread uniformly over that projected area.
A_b1 = d*l_s1;
A_b2 = d*l_s2;
p_b1 = RA/A_b1;
p_b2 = RB/A_b2;
n_bearing1 = Sy_PLA/p_b1;
n_bearing2 = Sy_PLA/p_b2;

%% Deflection profile (downward positive)
x = linspace(0,L_span,1001);
y = zeros(size(x));
left = x <= a;
y(left) = F*b.*x(left)./(6*L_span*E*I) .* (L_span^2 - b^2 - x(left).^2);
z = L_span - x(~left);
y(~left) = F*a.*z./(6*L_span*E*I) .* (L_span^2 - a^2 - z.^2);
[ymax, imax] = max(y);
x_ymax = x(imax);

%% Fatigue life estimate (rotating, fully reversed bending)
Se = SePrime*k_surface*k_size*k_load*k_temperature*k_reliability*k_misc;
sigma_a = sigmaB;
N1 = 1e3; N2 = 1e6;
S1 = 0.9*Sut;
if sigma_a <= Se
    life_cycles = Inf;  % idealized endurance-limit prediction
elseif sigma_a >= S1
    life_cycles = NaN;  % model does not estimate below 1e3 cycles
else
    basquin_b = log10(Se/S1)/log10(N2/N1);
    basquin_A = S1/(N1^basquin_b);
    life_cycles = (sigma_a/basquin_A)^(1/basquin_b);
end
if rpm > 0 && isfinite(life_cycles)
    life_hours = life_cycles/(rpm*60);
elseif isinf(life_cycles)
    life_hours = Inf;
else
    life_hours = NaN;
end

%% Results
fprintf('\n--- Simply supported shaft results ---\n');
fprintf('Overall shaft length:         %.4f m\n', L_shaft);
fprintf('Bearing-center span:          %.4f m\n', L_span);
fprintf('Reaction at support 1:        %.2f N upward\n', RA);
fprintf('Reaction at support 2:        %.2f N upward\n', RB);
fprintf('\n--- PLA bearing-hole static check (average projected pressure) ---\n');
fprintf('Support 1: length %.2f mm, pressure %.2f MPa, yield factor %.2f\n', ...
    l_s1*1e3, p_b1/1e6, n_bearing1);
fprintf('Support 2: length %.2f mm, pressure %.2f MPa, yield factor %.2f\n', ...
    l_s2*1e3, p_b2/1e6, n_bearing2);
fprintf('PLA compressive yield input:  %.2f MPa\n', Sy_PLA/1e6);
fprintf('Maximum bending moment:       %.3f N*m\n', Mmax);
fprintf('Maximum nominal bend stress:  %.2f MPa\n', sigmaB/1e6);
fprintf('Nominal yield safety factor:  %.2f\n', n_yield);
fprintf('Maximum downward deflection:  %.4f mm at x = %.4f m\n', ...
    ymax*1e3, x_ymax);
fprintf('Corrected endurance limit:    %.2f MPa\n', Se/1e6);
if isnan(life_cycles)
    fprintf('Fatigue life:                 below 1e3 cycles by this model\n');
elseif isinf(life_cycles)
    fprintf('Fatigue life:                 infinite by the endurance-limit model\n');
else
    fprintf('Estimated fatigue life:       %.3g cycles\n', life_cycles);
    if rpm > 0
        fprintf('Estimated operating life:     %.3g hours at %.0f rpm\n', ...
            life_hours, rpm);
    end
end

%% Deflection plot
figure('Color','w');
plot(x, y*1e3, 'LineWidth', 1.8);
hold on;
plot([0 L_span], [0 0], 'ko', 'MarkerFaceColor','k');
plot(a, 0, 'rv', 'MarkerFaceColor','r');
grid on;
xlabel('Position along shaft, x [m]');
ylabel('Downward deflection [mm]');
title('Shaft deflection under a point load');
legend('Deflection','Supports','Force location','Location','best');
