function spk_sort(Vs, ts)
% A spike sorting routine.
%
% References:
% 1. Quiroga et al., 2004. Unsupervised Spike Detection and Sorting with
%       Wavelets and Superparamagnetic Clustering
% 2. Wang et al., 2006. A Robust Method for Spike Sorting With Automatic
%       Overlap Decomposition.
% 3. Dai and Luo, 2014. A Robust Method for Spike Sorting with Overlap
%       Decomposition.
%
% Clusetring using RosbustICA. Reason presented in Matic et al., 2009.
% Comparison of ICA Algorithms For ECG Artifact Revmoal From EEG Signals.
% Clustering using Mixture of Gaussian Model.
addmatlabpkg('generic');
addmatlabpkg('ephanalysis');
zData = loadEpisodeFile('D:/Data/Traces/2015/11.November/Data 18 Nov 2015/Cell B.18Nov15.S1.E14.dat');
ts = zData.protocol.msPerPoint;
% Preprocessing
Vs = eph_window(zData.CurA, ts, [3000, 10000]);
Vs0 = preproc_filter(Vs, ts, 50); % filter

% Step 1: Spike Detection. Use Quiroga et al., 2004
sigma_n = median(abs(Vs))/0.6745; %icdf('Normal',0.75, 0,1) = 0.6745
thresh = 4*sigma_n;
%
% Step 2: Feature Extraction
% Step 3: Spike Sorting

end

function Vs = preproc_filter(Vs, ts, Wp, Ws, Rp, Rs)
% Butterworth bandpass filter between 300Hz and 3000Hz
if nargin<6 % use default if no or incomplete specification of design
    Nq = (1/ts*1000/2);
    Wp = [300, 3000]/Nq;
    Ws = [50, 4000]/Nq;
    Rp = 3; % ripple of passband [dB]
    Rs = 40; % ripple of stopband [dB]
end
[N, Wn] = buttord(Wp, Ws, Rp, Rs);
[B,A] = butter(N, Wn);
% Subtract mean
Vs_mean = mean(Vs);
Vs = Vs - Vs_mean;
% Append zeros
l = length(Vs);
pad = 2^nextpow2(l);
if (pad - l) < (0.1*l)
    pad = 2^(nextpow2(l)+1);
end
pad = pad - l; % length of padding
Vs = [Vs; zeros(pad, 1)];
% Apply the filter
Vs = filtfilt(B,A, Vs);
% Recover original data
Vs = Vs(1:l) + Vs_mean;
end