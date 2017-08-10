function stim = eph_get_stim(Ss, ts)
% Serves as an example on how to extract the strongest and longest stimulus
% given the stimulus trace.
% Inputs:
%   Ss: time series of stimulus trace
%   ts: sampling rate [seconds]
% Returns [start, end, intensity]

% Get the strongest stimulus
stim = find(Ss == max(Ss));
consec_index = getconsecutiveindex(stim);
% Get the longest stimulus
[~,longest_row] = max(diff(consec_index,[],2));
stim = stim(consec_index(longest_row, :));
stim = round(eph_ind2time(stim, ts));
stim = [stim; max(Ss)]';
end