function fanofactor = eph_fanofactor(Vs, ts, varargin)
% Calculate fanofactor
%
% fanofactor = eph_fanofactor(Vs, ts, option1, val1, ...)
% 
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
%   
%   Optional criteria to select spikes, following arguments of FINDPEAKS 
%   function. See also eph_count_spikes.
%
% Output:
%   fanofactor: calculate Fano factor
%
% Depends on 'eph_count_spikes'

% count the number of spike within the window
numspikes = eph_count_spikes(Vs,ts,varargin{:});
% calculate fano factor
fanofactor = var(numspikes)/mean(numspikes);
end