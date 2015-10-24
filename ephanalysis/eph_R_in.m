function [R_input, TAU, VP, baseline_mV] = eph_R_in(Vs, I, ts, step_timing, baseline_mV, varargin)
% find after hyperpolarization. 
%
% [R_input, TAU_start, TAU_end] = eph_find_input_resistance(Vs, I, ts, step_timing, baseline_mV)
%
% Inputs:
%   Vs: voltage time series column vector, in mV.
%   I: injected current in pA
%   ts: sampling rate [seconds]
%   step_timing: [start, end] time of the current step [s]
%   baseline_mV: (optional) instead of letting the program to calculate a
%           basedline based on given trace, specify a baseline value [mV]
%
% Outputs:
%   R_input: presumed input resistance [MOm]
%   TAU: time constant of 4 phases of the step:
%        [onset, offset], in [sec]
%   VP: voltage / potential of the 4 phases of the step:
%        [instantaneous hyperpolarization, plateau, instantaneous
%        depolarization, resting]
%
% Depends on eph_time2ind, eph_ind2time, butter, filtfilt, and fit

% zData = eph_loadEpisodeFile('H:\StrowbridgeLab\Data\Traces\2015\01.January\Data 27 Jan 2015\Neocortex C.27Jan15.S1.E3.dat');
% ts = zData.protocol.msPerPoint/1000;
% Vs = zData.VoltA;
% step_timing = zData.protocol.dacData{1}([19,20])/1000;
% I = zData.protocol.dacData{1}(21);

% Parse varargin
flag = parse_varargin(varargin, {'check_fit',true});

% Define some constants
baseline_window = 0.5; % seconds before the start of the current injection to use as baseline
onset_window = 0.25; %time window to examine onset [s]
offset_window = 0.5; %offset window [s]
plateau_window = 0.25; % plateau window [s]
recovery_window = 0.5; % recovery window [s]

% check Vs dimension
if size(Vs,2)>1
    error('Specify only 1 trial at a time for processing');
end

% make sure Vs is column vector
Vs = Vs(:);

% Filter the data
Vs = eph_filter(Vs, ts, 'butter');

% First find baseline before onset of current
if nargin<5 || isempty(baseline_mV)
    baseline_mV = mean(Vs(eph_time2ind((step_timing(1)-baseline_window>0)*(...
        step_timing(1)-baseline_window),ts):(eph_time2ind(step_timing(1),ts)-1)));
end
if  isempty(baseline_mV) || isnan(baseline_mV)
    warning('No baseline can be found! Assume -70mV. Otherwise, specify baseline into the function');
    baseline_mV = -70.0;
end

% Duration of the episode
sweepWindow = eph_ind2time(length(Vs), ts);

% Initialize results
TAU = zeros(1,4);
VP = zeros(1,4);

% Fit double exponential to the change of voltage;
% Calcualtion depends on if the current injected is positive or negative
exp_fit = 'exp(-a*x+b)+c';
switch sign(I)
    case -1
        %% PART I: Onset of current injection
        % Set up data
        onset_window = min(onset_window, diff(step_timing)/2);
        time_interval = (1:eph_time2ind(onset_window, ts)) + eph_time2ind(step_timing(1), ts)-1;
        X = linspace(0,onset_window, numel(time_interval))';
        Vs_onset = Vs(time_interval);
        % detect the instantaneous minimum
        [inst_min, IND] = findpeaks(-Vs_onset,'NPEAKS',1);
        if isempty(inst_min), VP(1) = NaN; else VP(1) = inst_min;end
        if isempty(IND), IND = length(X); end
        VP(1) = -VP(1); % invert back for real instantneous hyperpolarization
        % fit exponential
        X = X(1:IND); Vs_onset = Vs_onset(1:IND);
        startpoint = [10, 5, min(Vs_onset)];
        FO_on = fit(X,Vs_onset,exp_fit, 'StartPoint',startpoint);
        TAU(1) = 1/FO_on.a;
        %% PART II: Plateau
        tmp = [0,0];
        tmp(1) = eph_time2ind(step_timing(1), ts) + IND + 1;
        tmp(2) = min(tmp(1) + eph_time2ind(plateau_window, ts), eph_time2ind(step_timing(2), ts));
        time_interval = tmp(1):tmp(2);
        Vs_plateau = Vs(time_interval);
        VP(2) = mean(Vs_plateau);
        %% PART III: Offset of current injection
        % Set up data
        offset_window = min(offset_window,sweepWindow-step_timing(2));
        time_interval = (1:eph_time2ind(offset_window, ts)) + eph_time2ind(step_timing(2), ts)-1;
        X = linspace(0, offset_window, numel(time_interval))';
        Vs_offset = Vs(time_interval);
        [inst_max, IND] = findpeaks(Vs_offset,'NPEAKS',1);
        if isempty(inst_max), VP(3) = NaN; else VP(3) = inst_max; end
        if isempty(IND), IND = length(X); end
        % fit exponential
        X = X(1:IND); Vs_offset = Vs_offset(1:IND);
        startpoint = [10, 5, min(-Vs_offset)];
        FO_off = fit(X,-Vs_offset, exp_fit, 'StartPoint',startpoint);
        TAU(3) = 1/FO_off.a;
        %% PART IV: Recovery
        tmp = [0,0];
        tmp(1) = eph_time2ind(step_timing(2), ts) + IND +1;
        tmp(2) = min(tmp(1) + eph_time2ind(recovery_window, ts), length(Vs));
        time_interval = tmp(1):tmp(2);
        X = linspace(0, recovery_window, numel(time_interval))';
        Vs_recovery = Vs(time_interval);
        startpoint = [10, 5, min(Vs_recovery)];
        % fit exponential
        FO_rec = fit(X, Vs_recovery, exp_fit, 'StartPoint', startpoint);
        TAU(4) = 1/FO_rec.a;
        VP(4) = FO_rec.c;
    case 1
        VP(3) = 0;
    otherwise
        fprintf('No current injected\n');
        R_input = 0;
        return;
end
% check fitting results
if flag.check_fit
    check_curve_fittng(FO_on, 0.05, ...
        'Onset fitting is not converged');
    %check_curve_fittng(FO_sag, 0.05, ...
        %'I_h fitting is not converged');
    check_curve_fittng(FO_off, 0.05, ...
        'Offset fitting is not converged');
    check_curve_fittng(FO_rec,[0.25,0.25, 0.05], ...
        'Recovery fitting is not converged');
end
    
% Calculate input resistance based on fitting
R_input = (VP(2) - baseline_mV) / I * 1E3;
end


function check_curve_fittng(F, confidence_level, warning_message)
coef_val = coeffvalues(F);
cofint_val = confint(F);
check_val = (coef_val - cofint_val(1,:)) ./ coef_val;
if any(abs(check_val)>confidence_level)
    warning(warning_message);
end
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