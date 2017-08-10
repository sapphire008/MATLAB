% scratch
clear; clc;
excelsheet = 'D:/Edward/Documents/Assignments/Case Western Reserve/StrowbridgeLab/Projects/Neocortex Persistence/analysis/Slow Integration - 02022016/Slow Integration.xlsx';
sheet = 'STQuatification';
[~,~,RAW] = xlsread(excelsheet, sheet);

SUMMARY = aggregateR(RAW,{'Cell', 'Protocol'}, @mean, {'Rate_tau_s','R.sqr_exp'});
SUMMARY = sortrows(SUMMARY, 2);
%%
%n = 39;
for n = 9%2:size(RAW,1)
win_len = 5000;
zData = eph_load(RAW(n,1:2));
ts = zData.protocol.msPerPoint;
stim = [zData.protocol.dacData{1}(19:21); zData.protocol.dacData{1}(22:24)];
% make t_vect
protocol = RAW{n,3};
switch protocol
    case 'Spontaneous'
        Vs = zData.VoltA;
        %Vs = eph_window(zData.VoltA, ts/1000, [30, NaN]);
    case 'Triggered'
        Vs = eph_window(zData.VoltA, ts, [stim(2)+100,NaN]);
    case 'Terminate'
        Vs = eph_window(zData.VoltA, ts, [stim(5)+100,NaN]);
end

% Detect spikes
[~, spike_time, ~] = eph_count_spikes(Vs, ts);
first_spike_time = spike_time(1);

spike_time = spike_time - spike_time(1);
x = mean([spike_time(1:end-1), spike_time(2:end)], 2)/1000;
y = 1./diff(spike_time)*1000;
ind2 = find(x<win_len/1000, 1, 'last');
x = x(1:ind2);
y = y(1:ind2);
[F0, GOF] = fit(x, y, 'a*exp(-b*x)+c', 'Start', [0.5, 1, 0.5]);


% alternatively, find the rate and then fit
% R = eph_firing_rate(Vs, ts/1000, 'gaussian',0.5)';
% T = (1:length(R))*ts/1000;
% Rind1 = eph_time2ind(first_spike_time, ts);
% Rind2 = find(T<(first_spike_time/1000+win_len/1000), 1, 'last');
% T = T(Rind1:10:Rind2)';
% R = R(Rind1:10:Rind2)';
% [F0, GOF] = fit(T, R, 'a*exp(-b*x)+c', 'Start', [0.5, 1, 0.5]);
tau = 1/F0.b;
gof = GOF.adjrsquare;
RAW{n, 16} = tau;
RAW{n,17} = gof;
end










