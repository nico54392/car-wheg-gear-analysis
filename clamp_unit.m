function y = clamp_unit(x)
%CLAMP_UNIT Limit floating-point arguments to the inverse-trig domain [-1,1].
% Compatibility helper for older/cached vdi2736 versions. The current
% vdi2736.m validates the geometry argument and clamps it inline.
y = max(-1, min(1, x));
end
