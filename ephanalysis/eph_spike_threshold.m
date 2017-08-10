function [thresh, ind] = eph_spike_threshold(Vs, ts, dAP_dt)
% Calculate action potential threshold, based on Neske et al., 2015
% Contributions of Diverse Excitatory and Inhibitory Neurons to Recurrent
% Netowrk Activity in Cerebral Cortex
%
% [thresh, ind] = eph_spike_threshold(Vs, ts, dAP_dt)
%
% """
% Spike threshold was calculated as the voltage at which dV/dt first
% exceeded 5 V/s during spiking with near-threshold depo- larizing current
% steps.
% """
%
% Inputs:
%   Vs: voltage time series [mV]. Make sure this is in mV.
%   ts: sampling rate [s]. Make sure this is in seconds.
%   dAP_dt: rate of change of voltage of action potential. Default is 5V/s
%
% Output:
%   thresh: spike threshold [mV]
%   ind: index where the threshold occurred
if isempty(Vs) || all(~isfinite(Vs))
    thresh = NaN;
    ind = NaN;
    return
end

if nargin<3 || isempty(dAP_dt)
    dAP_dt = 5;
end

dV_dt = diff(Vs)/ 1000 / ts;
if ~isnumeric(dAP_dt)
    dAP_dt = 0.05 * max(dV_dt);
end
dV_dt = dV_dt - dAP_dt;
dV_dt(dV_dt<=0) = NaN;
% Find the first index that dV_dt crossed 0.
[~, ind] = min(dV_dt);
thresh = Vs(ind);
end
