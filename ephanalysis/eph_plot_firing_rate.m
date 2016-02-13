function h = eph_plot_firing_rate(Vs, ts, varargin)
% Generate a plot of firing rate evolution
%
% Inputs:
%   Vs: time series of voltages
%   ts: sampling rate in seconds
% Optional inputs: see eph_firing_rate
%
% Output:
%   h: handle of the figure

% zData = loadEpisodeFile('D:/Data/Traces/2015/06.June/Data 5 Jun 2015/Neocortex I.05Jun15.S1.E24.dat');
% Vs = zData.VoltA;
% ts = zData.protocol.msPerPoint/1000;
R = eph_firing_rate(Vs,ts, varargin{:});

h = figure();

t_vect = 0:ts:eph_ind2time(length(Vs), ts);
subplot(2,1,1);
plot(t_vect, Vs);
ylabel('Voltage (mV)');

subplot(2,1,2);
plot(t_vect, R);
ylabel('Firing Rate (Hz)');

xlabel('Time (sec)');

axs = findobj(gcf,'type','axes');
for n = 1:length(axs)
    set(axs(n), 'tickdir','out')
    set(axs(n), 'box','off')
    set(axs(n), 'fontname','Helvetica');
end
end