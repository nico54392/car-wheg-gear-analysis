function Zepsilon = Zepsilon(epsilon_alpha, epsilon_beta)
%ZEPSILON Contact-ratio factor for flank/contact stress, VDI2 Eq. 16, p.16
% according to VDI 2736
%
% Inputs:
%   epsilon_alpha - transverse contact ratio [-]
%   epsilon_beta  - overlap contact ratio [-]
%
% Output:
%   Zepsilon      - contact-ratio factor [-]

if epsilon_alpha <= 0
    error('epsilon_alpha must be greater than zero.');
end

if epsilon_beta < 1
    Zepsilon = sqrt( ...
        ((4 - epsilon_alpha) / 3) * (1 - epsilon_beta) ...
        + epsilon_beta / epsilon_alpha ...
        );
else
    % Need the VDI expression for epsilon_beta >= 1
    error('VDI expression for epsilon_beta >= 1 has not been implemented yet.');
end

end