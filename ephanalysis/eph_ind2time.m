function t = eph_ind2time(ind, ts, start_time)
% Convert an index of vector to temporal time point
%
% t = eph_ind2time(ind, ts, start_time)
%
% Inputs:
%   ind: current index of the vector
%   ts: sampling rate in seconds
%   start_time: (optional) what time in seconds does the first index 
%       correspond to? Defualt is 0
%
%   Note that as long as t, ts, and start_time has the same unit of time, 
%   be that second of millisecond, the program will work.
%
% Output:
%   t: current time in seconds

if nargin<3 || isempty(start_time), start_time = 0; end
t = (ind-1)*ts+start_time;
end