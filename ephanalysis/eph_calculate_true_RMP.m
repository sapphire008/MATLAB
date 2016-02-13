function RMP = eph_calculate_true_RMP(Vs, ts, Is)
% Calculate resting membrane potential based on time series of voltage and
% current.
%
%  RMP = eph_calculate_true_RMP(Vs, ts, Is);
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
%   Is: current time series, N x M matrix with the same dimension as Vs,
%       in units of [pA].
%
% Output:
%   RMP: time series of the same dimension as Vs, containing calculated
%        resting membrane potential
end