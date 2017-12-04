function Zs = eph_moving_apply_func(Vs, ts, window, func, skip)
% Apply a function to a moving window on Vs
% Zs = eph_moving_apply_func(Vs, ts, window, func, skip)
%
% Inputs:
%   Vs: voltage time series, N x 1 matrix with N time points in units 
%       of [mV].
%   ts: sampling rate [seconds]
%   window: moving temporal window size [seconds]
%   func: function to apply unto each moving window
%   skip: time point [seconds] to skip between moving windows. Use 0 for
%            non-overlapping window, or NaN for continuous. Accepts 
%            negative numbers for points to overlap, and positive numbers 
%            for points to skip.

% Estimate the number of windows
if isnan(skip)
    num_windows = length(Vs)-1;
    inc = ts;
elseif skip<window
    num_windows = eph_ind2time(length(Vs), ts); % convert to appropriate time
    num_windows = ceil(num_windows / (window - skip) );
    inc = window - skip;
end
Zs = zeros(num_windows,1);
for n = 1:num_windows
    tmp_win = [0, window] + inc * n;
    Zs(n) = func(eph_window(Vs, ts, tmp_win));
end
end