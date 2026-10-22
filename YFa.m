function YFa = YFa(h_Fa, s_Fn, alpha_Fan, alpha_n, m_n)
%YFA Tooth-form factor according to DIN 3990 Method C / VDI 2736
%
% Inputs:
%   h_Fa      - bending arm [m]
%   s_Fn      - tooth-root thickness at critical section [m]
%   alpha_Fan - normal pressure angle at load application point [rad]
%   alpha_n   - normal pressure angle [rad]
%   m_n       - normal module [m]
%
% Output:
%   YFa       - tooth-form factor [-]

if h_Fa <= 0
    error('h_Fa must be greater than zero.');
end

if s_Fn <= 0
    error('s_Fn must be greater than zero.');
end

if m_n <= 0
    error('m_n must be greater than zero.');
end

YFa = 6 * (h_Fa / m_n) ...
    * cos(alpha_Fan) ...
    / ((s_Fn / m_n)^2 * cos(alpha_n));

end