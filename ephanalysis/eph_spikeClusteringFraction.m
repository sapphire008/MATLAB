function scf = eph_spikeClusteringFraction(Vs, ts, varargin)
% Find spike cluster fraction, according to Larimer and Strowbridge 2008.
% 
% scf = eph_spikeClusteringFraction(Vs, ts, varargin)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
%
%   Optional criteria to select spikes, following arguments of FINDPEAKS 
%   function. Options include the following: 
%           'MINPEAKHEIGHT', MPH: spikes need to be above MPH
%           'MINPEAKDISTANCE, MPD: neighboring spikes need to be MPD apart.
%                            Note that this is in seconds, instead of
%                            number of indices for FINDPEAKS.
%           'THRESHOLD', TH: inds peaks that are at least greater than 
%                            their neighbors by the THRESHOLD TH.
%           'NPEAKS', NP: maximum number of peaks to find
%
%   Default: {'MINPEAKHEIGHT', -10}

% Define some constants
% calculate the fraction of APs followed or preceded by another AP by 
% this APwindow
APwindow = 60/1000; % [s]
% Detect spikes
[num_spikes, spike_time, ~] = eph_count_spikes(Vs, ts, varargin{:});
if num_spikes < 2, scf = 0; return; end
% count
diff_spike_time = diff(spike_time);
count = numel(union(...
    find(diff_spike_time<APwindow)-1, ...
    find(diff_spike_time<APwindow)+1));

% count = 0;
% for n = 1:length(spike_time)
%     if n == 1 && (spike_time(n+1)-spike_time(n))<=APwindow
%         count = count + 1;
%     elseif n == 1
%     elseif n == length(spike_time) && (spike_time(n)-spike_time(n-1))<=APwindow
%         count = count +1;
%     elseif n == length(spike_time)
%     elseif (spike_time(n+1)-spike_time(n))<=APwindow || (spike_time(n)-spike_time(n-1))<=APwindow
%         count = count + 1;
%     end 
% end
% spike cluster fraction
scf = count / num_spikes;
end