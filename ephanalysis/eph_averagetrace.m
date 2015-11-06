function Vs = eph_averagetrace(Vs, dim, Window, ts, start_time)
% Find the average of a series of traces
%       Vs = eph_averagetrace(Vs, dim, Window, ts, start_time)
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   dim: dimension to averge the trace. 
%       * 0 average everything.
%       * 1 over time. (Default)
%       * 2 over trials.
%   Window: temporal window, in the format of [min_sec, max_sec]
%   ts: sampling rate [seconds]. Necessary when specified Window.
%   start_time: (optional) what time in seconds does the first index 
%       correspond to? Defualt is 0. 
%
if nargin<2, dim = 1; end
if nargin<3, Window = []; end
if ischar(Window), Window = str2num(Window);end
if nargin==3 && ~isempty(Window), error('Please specify sampling rate ts.'); end
if nargin<5, start_time = 0; end

% window the time series
if ~isempty(Window)
    Vs = eph_window(Vs, ts, Window, start_time);
end

% Take the average
if dim > 1
    Vs = mean(Vs, dim);
else % 0
    Vs = mean(Vs(:));
end
end