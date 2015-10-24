function Vs = eph_window(Vs, ts, Window, start_time)
% Window the time series
% 
% Vs = eph_window(Vs, ts, Window, start_time)
% 
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
%   Window: temporal window, in the format of [min_sec, max_sec]
%   start_time: (optional) what time in seconds does the first index 
%       correspond to? Defualt is 0.
% 
%   Note that as long as ts, Window, and start_time has the same unit, 
%   be that second of millisecond, the program will work.
%
%
% Output:
%   Vs: windows Vs
%
% Depends on 'eph_time2ind'

if nargin<4 || isempty(start_time), start_time = 0;end
Vs = Vs(eph_time2ind(Window(1), ts, start_time): ...
    eph_time2ind(Window(2), ts, start_time));
end