function [AHP_mV, AHP_sec, TAU, AUC, DELATA] = eph_AHP(Vs, ts, step_timing, baseline_mV)
% find after hyperpolarization. 
%
% [AHP_mV, AHP_sec] = eph_AHP(Vs, ts, step_end_time)
%
% Inputs:
%   Vs: voltage time series column vector.
%   ts: sampling rate [seconds]
%   step_timing: [start,end] time of the current step [s]
%
% Outputs:
%   AHP_mV: AHP amplitude [mV]
%   AHP_sec: time of AHP relative to the start of the time series [sec]
%   TAU: time constant of the curve fitted to data within 0.5 seconds 
%        after AHP.
%   AUC: average area under the curve of the data within 0.5 seconds 
%        after AHP.
%   DELTA: estimated change of mV from baseline before current step to 
%        after AHP within 1.5 second. This is the rebound.
%   
%
%
% Depends on eph_time2ind, eph_ind2time, butter, filtfilt, and fit

baseline_window = 0.5; % seconds before the start of the current injection to use as baseline
AHP_window = 0.5; % seconds to consider since the end of the step
ADP_window = 1.5; % seconds to consider since the end of AHP

% check Vs dimension
if size(Vs,2)>1
    error('Specify only 1 trial at a time for processing');
end
% make sure Vs is column vector
Vs = Vs(:);
% First find baseline before onset of current
if nargin<4 || isempty(baseline_mV)
    baseline_mV = mean(Vs(eph_time2ind((step_timing(1)-baseline_window>0)*(...
        step_timing(1)-baseline_window),ts):(eph_time2ind(step_timing(1),ts)-1)));
end
if  (isempty(baseline_mV) || isnan(baseline_mV))
    warning('No baseline can be found! Assume -70mV. Otherwise, specify baseline into the function');
    baseline_mV = -70.0;
end
% truncate the time series
Vs = Vs(eph_time2ind(step_timing(2),ts):end);
% store original data properties
N = numel(Vs);
Vs_mean = mean(Vs);
% construct butterworth filter
[B,A] = butter(3,20/(1/ts/2),'low');
% zero pad the data
Vs = [Vs-Vs_mean;zeros(2^nextpow2(N)-N,1)];
% filter the data
Vs = filtfilt(B,A,Vs);
% truncate the filtered data to recover original time series
% invert the sign for peak detection, as AHP is downward
Vs = -Vs(1:N);
% find local minimum that is most proximal to the beginning of the
% truncated time series
[AHP_mV, IND] = findpeaks(Vs,'NPEAKS',1);
% recover peaks in mV
AHP_mV = -AHP_mV + Vs_mean-baseline_mV;
% recover peak location in seconds
AHP_sec = eph_ind2time(IND,ts) + step_timing(2);
% recover Vs time series
Vs = -Vs + Vs_mean;
% leave only the first 0.5 post AHP
AHP_window_end = min(IND+eph_time2ind(AHP_window,ts)-1, length(Vs));
Vs_fit = Vs((IND+1):AHP_window_end);
% Fit a single exponential to the time series after AHP.
X = eph_ind2time(1:length(Vs_fit),ts)';
FO = fit(X,Vs_fit,'exp2');
% use sum of two terms to estimate tau, although one term will usually be 
% very small comparing to the other [sec]
TAU = -1/(FO.b + FO.d);
% Find expected 
% get average area under the curve of the 0.5 seconds after AHP
AUC = sum(Vs_fit)/length(Vs_fit);
% leave only the first 1.5 post AHP
ADP_Window_end = min(IND +eph_time2ind(ADP_window,ts)-1, length(Vs));
Vs_fit = Vs((IND+1):ADP_Window_end);
% fit a second degree polynomial to data within 1 second of the data
% A*X^2 + B*X + C
X = eph_ind2time(1:length(Vs_fit),ts)';
FO = fit(X,Vs_fit,'poly2');
% find local maxima and point of inflection of the fitted cubic
DELATA = FO(-FO.p2/2/FO.p1) - baseline_mV;
end