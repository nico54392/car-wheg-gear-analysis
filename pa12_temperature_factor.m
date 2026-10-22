function [k_T, status] = pa12_temperature_factor(T, calibration)
%PA12_TEMPERATURE_FACTOR Interpolate a sourced PA12 strength-factor table.
% This is a data interface, not a VDI 2736 equation. No validated PA12
% temperature/life table is currently supplied by this project. Without
% calibration data it returns NaN and status='unassessed' rather than
% inventing a linear reduction between ambient temperature and HDT.
%
% calibration.temperature_C: strictly increasing measured temperatures [C]
% calibration.strength_factor: measured allowable/reference allowable [-]
% The calibration must match the PA12 grade, print process/orientation,
% conditioning, failure mode, and fatigue life used in the assessment.
k_T = NaN;
status = 'unassessed';
if nargin < 2 || isempty(calibration)
    return
end
required = {'temperature_C','strength_factor'};
for i = 1:numel(required)
    if ~isfield(calibration,required{i})
        error('Calibration data must include temperature_C and strength_factor.');
    end
end
temps = calibration.temperature_C(:);
factors = calibration.strength_factor(:);
if numel(temps) < 2 || numel(temps) ~= numel(factors) || ...
        any(~isfinite(temps)) || any(~isfinite(factors)) || ...
        any(diff(temps) <= 0) || any(factors <= 0)
    error('Calibration temperatures must increase; factors must be positive finite values.');
end
if ~isscalar(T) || ~isfinite(T) || T < temps(1) || T > temps(end)
    error('Requested temperature must lie within the supplied calibration range.');
end
k_T = interp1(temps,factors,T,'linear');
status = 'interpolated_from_user_calibration';
end
