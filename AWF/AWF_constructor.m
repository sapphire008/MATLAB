function [waveform, duration, Steps]= AWF_constructor(Steps, savedir, boolplot)
HoldingCurrentBefore = [-50,-30:10:30]; %delta pA
HoldingCurrentMiddle = -50; % delta pA
HoldingCurrentAfter = [0, -40, -80, -120, -160]; %delta pA, staircase down
RinStep = [250, -400]; % input resistance test ms, mA
RinBetween = [250, 0]; % Duration in-between input resistance test, ms, mA
DepoStep = [1000,250];% Depolarizing step, ms, mA
HypStep = [12000,-200]; % Hyperpolarizing step, ms, mA
% baseline time (ms) before test, before step and after step, after testing
Baseline = [1000, 1000, 500, 2000];
Duration = 40000; % desired duration, for jitter protocol
numcycles = 69;
ts = 0.1; % ms
factor = 16; % ITC18 scaling factor 16
protocol = 'excitaiblity2';
if nargin<2, savedir = 'D:/AWF.dat'; end
if nargin<3, boolplot = true; end
if nargin<1
    % Protcol specification
    switch protocol
        case 'stop'
            Steps = Stop(HoldingCurrentBefore,HoldingCurrentAfter,RinStep,RinBetween,DepoStep,HypStep, Baseline);
        case 'excitability'
            Steps = Excitability(HoldingCurrentBefore,HoldingCurrentAfter,RinStep,RinBetween,DepoStep,Baseline);
        case 'baseline'
            RinStep = [500, -50]; % input resistance test ms, mA
            RinBetween = [500, 0]; % Duration in-between input resistance test, ms, mA
            Steps = GetBaseline(HoldingCurrentBefore,RinStep,RinBetween, Baseline);
        case 'back2rest'
            RinStep = [300,-50]; % input resistance test ms, mA
            RinBetween = [300, 0]; % Duration in-between input resistance test, ms, mA
            Steps = Back2Rrest(HoldingCurrentBefore,HoldingCurrentMiddle, RinStep, RinBetween, DepoStep,Baseline,numcycles); 
        case 'excitaiblity2'
            RinStep = [300, 100];
            RinBetween = [300, 0];
            Steps = Back2Rrest(HoldingCurrentBefore,HoldingCurrentMiddle, RinStep, RinBetween, DepoStep,Baseline,numcycles); 
            % add another baseline
            Steps = [{[1000, 0]}, Steps];
            Steps{10}(2) = 0;
        case 'jitter'
            HoldingCurrentMiddle = 0; % delta pA
            Steps = Jitter(HoldingCurrentBefore,HoldingCurrentMiddle, RinStep, RinBetween, DepoStep,Baseline,numcycles, Duration);
    end
end

% Construct the waveform
waveform = [];
% square waveform only
for n = 1:length(Steps)
    waveform = [waveform, factor * Steps{n}(2)*ones(1, length(0:ts:Steps{n}(1))-1)];
end
% for non-pure square wave protocols
if ~ismember(protocol, {'stop','excitability','baseline', 'back2rest','jitter'})
    overlaywave = 0;
    waveform = waveform + overlaywave;
end

% calculate duration
duration = length(waveform)*ts;

% Write protocol to binary file
fid = fopen(savedir,'w');
%fwrite(fid, waveform, 'float64');
fprintf(fid, '%.2f\r\n', waveform);
fclose(fid);
if boolplot
    close;
    t = (0:ts:duration)/1000;
    plot(t(1:end-1), waveform/factor);
    set(gcf, 'Position', [100,800,1500,300]);
end
end

function Steps = GetBaseline(HoldingCurrentBefore,RinStep,RinBetween, Baseline)
Steps = {};
Steps{1} = [Baseline(1), 0 + HoldingCurrentBefore(1)]; %ms baseline
% Input resistance test: n
m = 2;
for n = 1:length(HoldingCurrentBefore)
    Steps{m} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+1} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+2} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+3} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+4} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+5} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+6} = RinBetween + [0, HoldingCurrentBefore(n)];
    m = m+7;
end
% Back to baseline
Steps{m} = [Baseline(4), 0];
end

function Steps = Excitability(HoldingCurrentBefore,HoldingCurrentAfter,...
    RinStep,RinBetween,DepoStep,Baseline)
% Steps{n} = [duration, step]
Steps = {};
Steps{1} = [Baseline(1), 0 + HoldingCurrentBefore(1)]; %ms baseline
% Input resistance test: n
m = 2;
for n = 1:length(HoldingCurrentBefore)
    Steps{m} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+1} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+2} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+3} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+4} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+5} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+6} = RinBetween + [0, HoldingCurrentBefore(n)];
    m = m+7;
end
% Wait a little bit before inject depolarizing current
Steps{m} = [Baseline(2), HoldingCurrentBefore(1)];
% Inject depolarizing current
Steps{m+1} = DepoStep + [0, HoldingCurrentBefore(1)];
% Wait long enough for ADP
Steps{m+2} = [Baseline(3), HoldingCurrentBefore(1)];
% Another round of input resistance testing
m = m+3;
for n = 1:length(HoldingCurrentAfter)
    if n > 1
        Steps{m} = RinBetween + [0, HoldingCurrentAfter(n)];
    else
        m = m -1;
    end
    Steps{m+1} = RinStep + [0, HoldingCurrentAfter(n)];
    Steps{m+2} = RinBetween + [0, HoldingCurrentAfter(n)];
    Steps{m+3} = RinStep + [0, HoldingCurrentAfter(n)];
    Steps{m+4} = RinBetween + [0, HoldingCurrentAfter(n)];
    Steps{m+5} = RinStep + [0, HoldingCurrentAfter(n)];
    Steps{m+6} = RinBetween + [0, HoldingCurrentAfter(n)];
    m = m+7;
end
% Back to baseline
Steps{m} = [Baseline(4), 0];
end

function Steps = Stop(HoldingCurrentBefore,HoldingCurrentAfter,...
    RinStep,RinBetween,DepoStep,HypStep, Baseline)
% before stim
Steps = {};
Steps{1} = [Baseline(1), 0 + HoldingCurrentBefore(1)]; %ms baseline
% Input resistance test: n
m = 2;
for n = 1%:length(HoldingCurrentBefore)
    Steps{m} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+1} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+2} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+3} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+4} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+5} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+6} = RinBetween + [0, HoldingCurrentBefore(n)];
    m = m+7;
end
Steps{m} = [Baseline(2), HoldingCurrentBefore(1)];
% Inject depolarizing current
Steps{m+1} = DepoStep + [0, HoldingCurrentBefore(1)];
% Wait long enough for ADP
Steps{m+2} = [Baseline(3), HoldingCurrentBefore(1)];
% Inject hyperpolaizing current
Steps{m+3} = HypStep+ [0, HoldingCurrentBefore(1)];
% Another round of input resistance testing
m = m+4;
for n = 1:8
    Steps{m} = RinBetween;
    Steps{m+1} = RinStep;
    Steps{m+2} = RinBetween;
    Steps{m+3} = RinStep;
    Steps{m+4} = RinBetween;
    Steps{m+5} = RinStep;
    Steps{m+6} = RinBetween;
    m = m+7;
end
% Back to baseline
Steps{m} = [Baseline(4), 0];
end

function Steps = Back2Rrest(HoldingCurrentBefore, HoldingCurrentMiddle, RinStep, RinBetween, DepoStep, Baseline,numcycles)
% before stim
Steps = {};
Steps{1} = [Baseline(1), 0 + HoldingCurrentBefore(1)]; %ms baseline
% Input resistance test: n
m = 2;
for n = 1%:length(HoldingCurrentBefore)
    Steps{m} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+1} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+2} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+3} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+4} = RinBetween + [0, HoldingCurrentBefore(n)];
    Steps{m+5} = RinStep + [0, HoldingCurrentBefore(n)];
    Steps{m+6} = RinBetween + [0, HoldingCurrentBefore(n)];
    m = m+7;
end
Steps{m} = [Baseline(2), HoldingCurrentBefore(1)];
% Inject depolarizing current
Steps{m+1} = DepoStep + [0, HoldingCurrentBefore(1)];
% Wait long enough for ADP
Steps{m+2} = [Baseline(3), HoldingCurrentBefore(1)];
m = m+3;
for n = 1:numcycles % 63
    if n == 1
        Steps{m} = RinBetween + [0, HoldingCurrentMiddle];
    else
        m = m -1;
    end
    Steps{m+1} = RinStep + [0, HoldingCurrentMiddle];
    Steps{m+2} = RinBetween + [0, HoldingCurrentMiddle];
    m = m+3;
end
% Back to baseline
Steps{m} = [Baseline(4), 0];
end

function Steps = Jitter(HoldingCurrentBefore, HoldingCurrentMiddle, RinStep, RinBetween, DepoStep, Baseline,numcycles, Duration)
% before stim
Steps = {};
Steps{1} = [Baseline(1), 0 + HoldingCurrentBefore(1)]; %ms baseline
% Input resistance test: n
m = 2;
Steps{m} = [Baseline(2), HoldingCurrentBefore(1)];
% Inject depolarizing current
Steps{m+1} = DepoStep + [0, HoldingCurrentBefore(1)];
% Wait long enough for ADP
Steps{m+2} = [Baseline(3), HoldingCurrentBefore(1)];
m = m+3;
for n = 1:numcycles % 63
    Steps{m} = RinStep + [0, HoldingCurrentMiddle];
    Steps{m+1} = RinBetween + [0, HoldingCurrentMiddle];
    m = m+2;
end
% Back to baseline
Steps{m} = [Baseline(4), 0];

% Calculate duration
if ~isnan(Duration)
    Steps = EnforceDuration(Steps, Duration);
end

end


%% Generic subroutines
function Steps = EnforceDuration(Steps, Duration)
dur = cellfun(@(x) x(1), Steps);
if sum(dur) < Duration
    Steps{end+1} = [Duration - sum(dur), 0];
elseif sum(dur) > Duration
    tmp = find((cumsum(dur) - Duration)<0,1, 'last');
    Steps = Steps(1:tmp);
    dur = cellfun(@(x) x(1), Steps);
    Steps{end+1} = [Duration - sum(dur), 0];
end
end

%copyfile('D:\AWF.dat','C:\AWF.dat','f')