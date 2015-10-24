function SI_val = eph_SI_plot(Vs, Is, ts, varargin)
% Plot number of spikes vs. current level during a current injection (SI
% plot, where the slope is called S-I value that quantifies adaptation).
% 
% Inputs:
%   Vs: NxM matrix with N time points, and M trials of voltage time series
%   Is: same dimension as V, current time series
%   ts: sampling rate in seconds.
%
% Output:
%   SI_val: slope of the SI plot.
%
% Reference:
% Edi Barkai and Michale E. Hasselmo. Modulation of the Input/Output 
% Function of Rat Piriform Cortex Pyramidal Cells. Journal Of
% Neurophysiology. Vol. 72, No.2. August 194. Printed in U.S.A.
end