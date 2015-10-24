function eph_phase_frequency_change(Vs, Ss, ts)
% Find the phase and frequency change before and after a stimulation
%
% [freq_change, phase_change] = eph_count_spikes(Vs, ts, Ss, ...)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   Ss: stimulus onset and offset time [seconds]. Input as a matrix
%       where each row corresponds to one stimulus, in the format of
%       [onset1, offset1; onset2, offset2]. If input as a single column
%       vector, i.e. [onset1; onset2], the stimuli are treated as
%       instantaneous. If input as a single row vector, then onset and
%       offset will be applied to all M trials.
%   ts: sampling rate [seconds]

filepath='X:\Edward\Data\Traces\Data 10 Mar 2015\Neocortex D.10Mar15.S1.E119.dat';
zData = eph_loadEpisodeFile(filepath);

Vs = zData.VoltA;
Ss = [2.8,6.5];
ts = zData.protocol.msPerPoint/1000;


% Square stimulus: get frequency before and after stimulus
Vs_before = Vs(1:eph_time2ind(Ss(1), ts));
[isi_before, ~, mean_isi_before, ~] = eph_isi(Vs_before, ts);

Vs_after = Vs(eph_time2ind(Ss(2), ts):end);
[isi_after, ~, mean_isi_after, ~] = eph_isi(Vs_after, ts);


[H, P, CI] = ttest2(isi_before, isi_after);
end