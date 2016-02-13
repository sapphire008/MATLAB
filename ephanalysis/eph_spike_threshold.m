function thresh = eph_spike_threshold(Vs, ts)
% Calculate action potential threshold, based on Neske et al., 2015.
% Contributions of Diverse Excitatory and Inhibitory Neurons to Recurrent
% Netowrk Activity in Cerebral Cortex
%
% """
% Spike threshold was calculated as the voltage at which dV/dt first 
% exceeded 5 V/s during spiking with near-threshold depo- larizing current
% steps.
% """
%
% Inputs:
%   Vs: voltage time series [mV]
%   ts: sampling rate [s]
%
% Output:
%   thresh: spike threshold [mV]


dV_dt = diff(Vs)/ 1000 / ts - 5;
dV_dt(dV_dt<=0) = NaN;
% Find the first index that dV_dt crossed 0.
[~, ind] = min(dV_dt);
thresh = Vs(ind);
end