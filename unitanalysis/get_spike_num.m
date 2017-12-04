function [spike_times, Vs] = get_spike_num(ep)
zData = eph_load(ep);
ts = zData.protocol.msPerPoint;
stim = eph_get_stim(zData.StimulusA, ts);
Vs = eph_window(zData.VoltA, ts, [0, 2000] + stim(1));
[~,spike_times, ~] = eph_count_spikes(Vs, ts, 'MinPeakHeight', 0);
end