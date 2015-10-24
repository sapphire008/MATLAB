function ind = eph_time2ind(t, ts, start_time)
% Convert a time point to index of vector
%
% ind = eph_time2ind(t, ts, start_time)
%
% Inputs:
%   t: current time in seconds
%   ts: sampling rate in seconds
%   start_time: (optional) time in seconds the first index corresponds
%       to. Defualt is 0.
%
%   Note that as long as t, ts, and start_time has the same unit of time, 
%   be that second of millisecond, the program will work.
%
% Output:
%   ind: index

if nargin<3 || isempty(start_time), start_time = 0; end
ind = round((t - start_time)/ts+double((t-start_time)>=0));
end
