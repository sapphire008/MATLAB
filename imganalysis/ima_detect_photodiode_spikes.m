function [num_p_spks, p_spks_time, p_spks_amp] = ...
    ima_detect_photodiode_spikes(Xs, ts, varargin)
% zData = eph_load('NeocortexPD C.22Nov16.S1.E15');
% Xs = zData.VoltD;
% Vs = zData.VoltA;
% ts = zData.protocol.msPerPoint;
% photo = [900,3800];

flag = parse_varargin(varargin, {'Vs', []}, {'SpikeTime', []}, {'window', []});
if ~isempty(flag.window)
    Xs = eph_window(Xs, ts, flag.window);
end
if isempty(flag.Vs) && isempty(flag.SpikeTime)
     error('Either specify a voltage trace or spike time to help detect photodiode spikes');
elseif ~isempty(flag.SpikeTime)
    num_p_spks = length(flag.SpikeTime);
    Ss = flag.SpikeTime;
elseif ~isempty(flag.Vs) && isempty(flag.SpikeTime)
    if ~isempty(flag.window)
        Vs = eph_window(flag.Vs, ts, flag.window);
    end
    [num_p_spks, Ss, ~] = eph_count_spikes(Vs,ts);
end
if length(Ss)>1
    Ss = [Ss; 2*Ss(end)-Ss(end-1)];
else
    Ss = [Ss; NaN];
end
%FIR = eph_dirac(ts,[0, diff(photo)],Ss,1,true);
p_spks_time = zeros(num_p_spks, 1);
p_spks_amp = zeros(num_p_spks,1);
for n = 1:num_p_spks% detect photo spikes in between volt spikess
    [p_spks_amp(n), peak_ind] = max(eph_window(Xs, ts, Ss(n:(n+1))));
    p_spks_time(n) = eph_ind2time(peak_ind, ts, Ss(n));
end

%plot(0:ts:((length(Xs)-1)*ts), Xs);
%hold on;
%plot(p_spks_time, p_spks_amp, 'o');
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