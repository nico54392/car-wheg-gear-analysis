function T_flank = vdi2736_flank_temperature(T_ambient,mu,P,H_V,...
    k_theta_flank,b_m,z,v,m_mm,R_lambda_G,A_G,ED)
%VDI2736_FLANK_TEMPERATURE VDI 2736 Blatt 2 Eq. (9), flank temperature. (VDI2 p.10)
% b_m is face width [m]; module m_mm [mm]; v [m/s]; P [W];
% k_theta_flank [K*(m/s)^0.75*mm^1.75]; result [deg C].
validate_inputs(T_ambient,mu,P,H_V,k_theta_flank,b_m,z,v,m_mm,...
    R_lambda_G,A_G,ED);
if P == 0 || ED == 0
    T_flank = T_ambient;
    return
end
if v == 0
    error('Positive transmitted power requires positive mesh velocity.');
end
T_flank = T_ambient + mu*P*H_V*( ...
    k_theta_flank/(b_m*1e3*z*(v*m_mm)^0.75) + ...
    R_lambda_G/A_G)*ED^0.64;
end

function validate_inputs(Ta,mu,P,H,k,b,z,v,m,R,A,ED)
if any(~isfinite([Ta,mu,P,H,k,b,z,v,m,R,A,ED])) || ...
        mu < 0 || P < 0 || H < 0 || k < 0 || b <= 0 || z <= 0 || ...
        v < 0 || m <= 0 || R < 0 || A <= 0 || ED < 0 || ED > 1
    error('vdi2736_flank_temperature: invalid or out-of-range input.');
end
end
