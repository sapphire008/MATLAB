function [num_fAHPs, fAHP_time, fAHP_amp] = eph_count_fAHP(Vs, ts, varargin)
% Count the fast AHPs following each spikes. The function depens on spike
% detection. To improve spike detection, set optional parameters (See
% following documentation).
%
% [num_fAHPs, fAHP_time, fAHP_amp] = eph_count_fAHP(Vs, ts, option1, val1, ...)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
%
% Outputs:
%   num_fAHPs: number of fAHP for each trial
%   fAHP_time: indices of the fAHP, returned as one cell array of time
%           vectors per trial
%   fAHP_amp: voltage of the AHP [mV], returned as one cell array
%           of spike heights per trial
%   Optional criteria to select spikes, following arguments of FINDPEAKS 
%   function. Relevant options include the following: 
%           'MINPEAKDISTANCE, MPD: neighboring spikes need to be MPD apart.
%                            Note that this is in seconds, instead of
%                            number of indices for FINDPEAKS.
%           'MINPEAKDISTANCE, MPD: neighboring spikes need to be MPD apart.
%                            Note that this is in seconds, instead of
%                            number of indices for FINDPEAKS.
%           'THRESHOLD', TH: inds peaks that are at least greater than 
%                            their neighbors by the THRESHOLD TH.
%           'NPEAKS', NP: maximum number of peaks to find
%
%   Default: {'MINPEAKHEIGHT', -10}
%
% Depends on EPH_IND2TIME,EPH_TIME2IND, EPH_COUNT_SPIKES

numTrials = size(Vs,2);
fAHP_amp = cell(1,numTrials);
fAHP_time = cell(1,numTrials);
for m = 1:numTrials
    try
        [~, spk_time, ~] = eph_count_spikes(Vs, ts);%, varargin);
        ind = eph_time2ind(spk_time, ts);
    catch
        fAHP_amp{m} = NaN;
        fAHP_time{m} = NaN;
        continue;
    end
    fAHP_amp{m} = zeros(1,length(ind)-1);
    fAHP_time{m} = zeros(1,length(ind)-1);
    for k = 2:length(ind)
        [fAHP_amp{m}(k-1), fAHP_time{m}(k-1)] = min(Vs(ind(k-1):ind(k)));
        fAHP_time{m}(k-1) = fAHP_time{m}(k-1) + ind(k-1);
    end 
end
num_fAHPs = cellfun(@numel, fAHP_time);
fAHP_time = cellfun(@(x) eph_ind2time(x,ts), fAHP_time, 'un',0);
if numel(fAHP_time) == 1
    fAHP_time = fAHP_time{1}; 
    fAHP_amp = fAHP_amp{1};
end
end