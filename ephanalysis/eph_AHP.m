function varargout = eph_AHP(Vs, ts, step_timing, baseline_mV, MODE, varargin)
% Find after-hyperpolarization and after-depolarization. 
%
% [AHP_mV, ADP_mV] = eph_AHP(Vs, ts, step_timing, baseline_mV, 'average')
% [AHP_mV, AHP_sec, TAU, AUC, DELTA] = eph_AHP(Vs, ts, step_timing, baseline_mV, 'model')
%
% Inputs:
%   Vs: voltage time series column vector.
%   ts: sampling rate [seconds]
%   step_timing: [start,end] time of the current step [s]
%   mode: 
%       'window_average': take an avergae with a specific window, relative
%           to the end of the step window. Specify the window with the
%           following flags, or use the default.
%           'AHP': AHP window. Default [0, 0.5]
%           'ADP': ADP window. Default [0.5, 1.5].
%       'model': fit exponential model for AHP and ADP.
%
% Outputs:
%   if 'average'
%       AHP_mV: AHP amplitude [mV]. Average of the AHP window.
%       ADP_mV: ADP amplitude [mV]. Average of ADP window.
%       baseline_mV: baseline [mV]
%   if 'model'
%       AHP_mV: AHP amplitude [mV]
%       AHP_sec: time of AHP relative to the start of the time series [sec]
%       TAU: time constant of the curve fitted to data within 0.5 seconds 
%           after AHP.
%       AUC: average area under the curve of the data within 0.5 seconds 
%           after AHP.
%       DELTA: estimated change of mV from baseline before current step to 
%           after AHP within 1.5 second. This is the rebound or ADP.
%       baseline_mV: baseline [mV]
%   
%
%
% Depends on eph_time2ind, eph_ind2time, butter, filtfilt, and fit

baseline_window = 0.5; % seconds before the start of the current injection to use as baseline
AHP_window = [0, 0.5]; % seconds to consider since the end of the step
ADP_window = [0.5, 1.5]; % seconds to consider since the end of AHP

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
if nargin<5 || isempty(MODE), MODE = 'average'; end   

% Evoke appropriate algorithm to clculate AHP/ADP
switch MODE
    case 'model'
        [AHP_mV, AHP_sec, TAU, AUC, DELTA] = AHP_mode(Vs, ts, step_timing, baseline_mV, AHP_window(2), ADP_window(2));
        varargout = {AHP_mV, AHP_sec, TAU, AUC, DELTA, baseline_mV};
    case 'average'
        flag = parse_varargin(varargin, {'AHP', AHP_window}, {'ADP',ADP_window});
        [AHP_mV, ADP_mV] = AHP_average(Vs, ts, step_timing, baseline_mV, flag.AHP, flag.ADP);
        varargout = {AHP_mV, ADP_mV, baseline_mV};
    otherwise
        error('Unrecognized mode %s', MODE);
end
end

function [AHP_mV, ADP_mV] = AHP_average(Vs, ts, step_timing, baseline_mV, AHP_window, ADP_window)
% average across a specified window
AHP_window = step_timing(end) + AHP_window;
AHP_mV = eph_averagetrace(Vs, ts, AHP_window, 0) - baseline_mV;
ADP_window = step_timing(end) + ADP_window;
ADP_mV = eph_averagetrace(Vs, ts, ADP_window, 0) - baseline_mV;
end


function [AHP_mV, AHP_sec, TAU, AUC, DELTA] = AHP_model(Vs, ts, step_timing, baseline_mV, AHP_window, ADP_window)
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
DELTA = FO(-FO.p2/2/FO.p1) - baseline_mV;
end

function flag = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1'}.
% return flag with fields 'opt1', 'opt2', ...

% for sanity check
IND = ~ismember(options(1:2:end),cellfun(@(x) x{1}, varargin, 'un',0));
if any(IND)
    EINPUTS = options(find(IND)*2-1);
    S = warning('QUERY','BACKTRACE'); % get the current state
    warning OFF BACKTRACE; % turn off backtrace
    warning(['Unrecognized optional flags:\n', ...
        repmat('%s\n',1,sum(IND))],EINPUTS{:});
    warning('These options are ignored');
    warning(S);
end
flag = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp) % if present, assign using input value
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
    else % if not present, assign default value
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end