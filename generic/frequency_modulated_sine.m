function [t, Y] = frequency_modulated_sine(f0, f, duration, ts, phase)
% Return the frequency modulated sinosoidal wave
%    f0: starting frequency [Hz]
%    f: ending frequency [Hz]
%    duration: duration of the wave [Sec]
%    ts: sampling rate of wave [sec]
%    phase: phase at the start of the wave, between [0, pi]
if nargin<5 || isempty(phase), phase = 0; end
nu = linspace(f0, f, duration / ts+ 1);
t = 0:ts:duration;
Y = sin(2 * pi .* nu .* t + phase);
end
