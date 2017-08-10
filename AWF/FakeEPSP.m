function epsp = FakeEPSP(interval, amp, tau1, tau2, ts)
% Return a single fake EPSP waveform
% tau1 > tau2, i.e. rising must be faster than falling for EPSPs
if nargin<1, interval = 400; end % duration
if nargin<2, amp = 150; end
if nargin<3, tau1 = 100; end % falling piece
if nargin<4, tau2 = 50; end % rising piece
if nargin<5, ts = 0.1; end % sampling rate [ms]

% make fake epsps
t = (ts:ts:interval)-ts;
epsp = amp*(exp(-t/tau1) - exp(-t/tau2));
end