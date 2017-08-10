function V = HH(I, dt, Vo)
%numerical solution of the space-clamped Hodgkin-Huxley equations
% http://math.nyu.edu/faculty/peskin/ModSimPrograms/ch3/
% http://icwww.epfl.ch/~gerstner/SPNM/node12.html

% set up constants
%Units:
%   voltage is in millivolts (mV)
%   current is in picoamperes (pA)
%   time is in milliseconds (ms)
%   uF = uA * ms / mV

% Initialize the membrane parameters:
	Cm = 20;      % membrane capacitance (uF)
	gNaBar = 120; % max possible Na+ conductance (uA/mV)
	gKBar = 36;   % max possible K+ conductance (uA/mV)
	gABar = 2;
	gLeakBar = 0.3;  % leakage conductance (uA/mV)
	ENa = 45;   % Na+ equilibrium potential (mV)
	EK = -82;   % K+ equilibrium potential (mV)
	ELeak = -59;   % Leak channel reversal potential (mV)
    
    gSynBar = .1;
    Esyn = 10;
    synPot = alpha([3 3 1000 0], (1:length(I)).*dt);
	
% Initial the voltage
	V = zeros(size(I));
	mGateSaved = V;
	hGateSaved = V;
    if nargin < 3
    	V(1) = -69.8976728963679;
    else
        V(1) = Vo;
    end

% reset the gating variables
	clear gNa gK gA;
	
% solve these equations
for t = 2:numel(I)
	% calculate the current
	[conductanceA mGate hGate] = gA(V(t - 1), dt);
		iTotal = -I(t) +...
			gNaBar * gNa(V(t - 1), dt) * (V(t - 1) - ENa) +...
			gKBar * gK(V(t - 1), dt) * (V(t - 1) - EK) +...
			gABar * conductanceA * (V(t - 1) - EK)+...
			gLeakBar * (V(t - 1) - ELeak)+...
            gSynBar * synPot(t) * (V(t - 1) - Esyn);		

	% calculate the voltage
		V(t) = V(t - 1) - iTotal / Cm;	
		mGateSaved(t) = mGate;
		hGateSaved(t) = hGate;
end

if nargout < 1
	newScope({hGateSaved, mGateSaved, V}, (1:numel(V)) .* dt);
end