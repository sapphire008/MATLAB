function eph_estimate_R_series_Vclamp(Vs, ts, window)
% tau = C_m * R_series;
% I = C_m * (dV/dt)];
% R_series = tau / (I / (dV/dt));

zData = eph_load

tau = 2.159; % [ms],
dV = 10; % [mV]
dt = 0.7; % [ms]
I = 736.9; % [pA]

C_m = I / (dV/dt); %[pS]
R_series = tau / C_m * 1000; %[MOhm]


end
