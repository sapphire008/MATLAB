function [waveform, duration] = AWF_overlay(savedir, boolplot)
% Returns: 
%   waveform: time series of AWF
%   start_time: start time for [probe_before, rest, probe_after, hypo]
addmatlabpkg('ephanalysis');
if nargin<1, savedir = 'D:/Edward/AWF/AWF.dat'; end
if nargin<2, boolplot = true; end
Rest = [1000, 3000, 1000, 10000]; %[baseline before probe, rest/stim period, recovery period, after/hyperpolarizing period
% absolute start time [ms], then relative to the probe window: 
% time before start [ms], time in between probe onsets,  number of probes, time before end [ms] 
ProbeBefore = [1000, 0, 100, 10, 500];
ProbeAfter = [4500, 0, 100, 10, 500];
Depo = 0; % depolarization during probe period
Hypo = -50; % hyperpolarization post probe period
Alpha = [800,200,100]; %[interval, amp, tau], shape of probe waveform
ts = 0.1;
factor = 16;
Duration = 20000; % enforce duration of AWF [ms]

% make the probes
Alpha = num2cell([Alpha,ts]);
probes = FakeEPSP(Alpha{:});

waveform = [];
% baseline period
waveform = [waveform, factor * 0 * ones(1, length(0:ts:Rest(1))-1)];

% probe before
waveform = EnforceWaveDuration(ProbeBefore(1), waveform, ts);
%start
waveform = [waveform, factor * Depo*ones(1, length(0:ts:ProbeBefore(2))-1)]; 
% probes
probewave = ProbeWave(ProbeBefore(3:4), probes, ts);
waveform = [waveform, (probewave + Depo)*factor]; %probes
%end
waveform = [waveform, factor * Depo*ones(1, length(0:ts:ProbeBefore(5))-1)];

% Rest / stim period
waveform = [waveform, factor * 0 * ones(1, length(0:ts:Rest(2))-1)];

% probe after
waveform = EnforceWaveDuration(ProbeAfter(1), waveform, ts);
% start
waveform = [waveform, factor * Depo * ones(1, length(0:ts:ProbeAfter(2))-1)];
% probes
probewave = ProbeWave(ProbeAfter(3:4), probes, ts);
waveform = [waveform, (probewave+Depo) * factor];
%end
waveform = [waveform, factor * Depo*ones(1, length(0:ts:ProbeAfter(5))-1)];

% recovery period
waveform = [waveform, factor * 0 * ones(1, length(0:ts:Rest(3))-1)];

% hyperpolarizing period
waveform = [waveform, factor * Hypo * ones(1, length(0:ts:Rest(4)))];

% correct waveform duration to match desired
waveform = EnforceWaveDuration(Duration, waveform, ts);


% calculate duration
duration = (length(waveform)-1)*ts;
% Write protocol to binary file
fid = fopen(savedir,'w');
%fwrite(fid, waveform, 'float64');
fprintf(fid, '%.2f\r\n', waveform);
fclose(fid);
if boolplot
    close;
    t = (0:ts:duration)/1000;
    plot(t, waveform/factor);
    set(gcf, 'Position', [100,800,1500,300]);
    xlim([0, max(t)]);
    inc = max(diff(get(gca, 'ytick')));
    ylim(get(gca,'ylim') + [-1, 1] * inc);
    xlabel('Time (s)');
    ylabel('Current (pA)');
end
end


function probewave = ProbeWave(ProbeParam, probes, ts)
% ProbeParam = [100, 5]; % before, inbetween, times, after,
% probes
phi = (0:ProbeParam(2)-1) * ProbeParam(1); % timing of each probe
pdur = ProbeParam(2)* ProbeParam(1); % duration of this probe
delta_fun = eph_dirac(ts, [0, pdur], phi);
delta_fun = delta_fun(:)';
probewave = conv(delta_fun, probes);
end

%% Generic subroutines
function epsp = FakeEPSP(interval, amp, tau, ts)
% Return a single fake EPSP waveform
% tau1 > tau2, i.e. rising must be faster than falling for EPSPs
if nargin<1, interval = 400; end % duration
if nargin<2, amp = 150; end
if nargin<3, tau = 100; end % falling piece
if nargin<4, ts = 0.1; end % sampling rate [ms]

% make fake epsps
t = (ts:ts:interval)-ts;
t0 = 0;
% double exponential
%epsp = amp*(exp(-t/tau1) - exp(-t/tau2));
% Alpha function
epsp = amp * (t-t0)/tau .* exp(-(t-t0)/tau);
end

function waveform = EnforceWaveDuration(Duration, waveform, ts, pad)
% Inputs:
%   Duration: desired duration in ms
%   waveform: time series to be modified
%   ts: acquisition rate [ms]
%   pad: number to pad in case Duration > length of waveform. Default
%        to pad the last element of waveform. Otherwise, specify a single
%        number to pad
% Output:
%   waveform: corrected waveform
dur = (length(waveform)-1)*ts;
if Duration < dur
    ind = round(Duration/ts+double(Duration>=0));
    waveform = waveform(1:ind);
elseif Duration > dur
    l = round((Duration-dur)/ts);
    if nargin<4 || isempty(pad) || isnan(pad)
        pad = waveform(end);
    end
    waveform = [waveform, pad * ones(1, l)];
end
end