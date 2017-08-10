function [waveform, duration, Steps] = AWF_constructor_Nick(Steps, savedir, boolplot)
%   Steps: a cell array of steps in the format of [duration, amplitude]
%   savedir: save directory of resulted AWF.dat file
%   boolplot: [true|false]. Show a plot of AWF
% Outputs:
%   waveform: constructed waveform
%   duration: duration of the entire waveform
%   Steps: a list of steps used. 
%   index: relative index of each step on the waveform


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
end
end

function epsp = Fake_EPSP_snipet(tau1, tau2, interval, amp, ts)
% Return a single fake EPSP waveform
% tau1 > tau2, i.e. rising must be faster than falling for EPSPs
if nargin<1, tau1 = 100; end % falling piece
if nargin<2, tau2 = 50; end % rising piece
if nargin<3, interval = 400; end
if nargin<4, amp = 150; end
if nargin<5, ts = 0.1; end % sampling rate [ms]

% make fake epsps
t = 0:ts:interval;
epsp = amp*(exp(-t/tau1) - exp(-t/tau2));
end