function [isi, cv_isi, mean_isi, std_isi] = eph_isi(Vs, ts, varargin)
% Calculate inter-spike interval, assuming more than 1 spikes fired.
%
% [isi, cv_isi, mean_isi, std_isi] = eph_isi(Vs, ts)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
% Optionally inputs, see EPH_COUNT_SPIKES
%
%   
% Output: if only 1 spike or no spike detected, these values will be NaN
%   isi: inter-spike interval in seconds
%   cv_isi: coefficient of variance of isi
%   mean_isi: mean isi
%   std_isi: standard deviation of isi
%
% Depends on 'eph_count_spikes'

% Find spikes first
[~,spike_times,~] = eph_count_spikes(Vs, ts, varargin{:});
if isnumeric(spike_times), spike_times = {spike_times}; end
% Calculate ISI
isi = cellfun(@diff, spike_times, 'un',0);
% Calculate other outputs
mean_isi = cellfun(@mean, isi);
std_isi = cellfun(@std, isi);
cv_isi = mean_isi./std_isi;
if numel(isi) == 1, isi = isi{1}; end
end