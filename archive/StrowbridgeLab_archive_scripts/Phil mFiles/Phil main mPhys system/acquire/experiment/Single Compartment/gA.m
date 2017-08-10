function [fractionalConductance mOut hOut] = gA(v, dt)
% An IA current
% gA(v, dt) returns the value of the conductance at a given voltage (with a time-dependent component).
% gA plots steady state current and gating variables vs. voltage
persistent m
persistent h

% Initialize gate conductances
if isempty(m)
	m = 0.2; % IA activation gate
	h = 0.9; % IA inactivation gate
end
% fractionalConductance = 0;
% return
% Lien CC, Martina M, Schultz JH, Ehmke H, Jonas P (2002) Gating,
% modulation and subunit composition of voltage-gated K(+) channels in dendritic inhibitory interneurones of rat hippocampus. J Physiol 538:405-19
	if ~exist('v', 'var')
		v = -100:.1:50;	
	end
	minf = (1 ./ (1 + exp(-(v + 70) ./ 5))).^4;
	mtau = (1 ./ ((1 + exp(-(v + 40) ./ 5)) + (1 + exp(-(-v) ./ 10)))).^4 + .1;
	hinf = 1 ./ (1 + exp((v + 68.5) ./ 10));
	htau = (7 ./ ((1 + exp(-(v + 100) ./ 15)) + (1 + exp(-(-v - 60) ./ 20)))).^4 + 5;
	
	if numel(v) > 1
		figure
		a(1) = subplot(3, 1, 1);
		plot(v, minf);
		hold on
		plot(v, hinf, 'color', 'red');
		plot(v, minf .* hinf, 'color', 'green');
		legend({'mInf', 'hInf', 'Total'});
		a(2) = subplot(3,1,2);
		plot(v, mtau);
		hold on
		plot(v, htau, 'color', 'red');
		legend({'mTau', 'hTau'});
		a(3) = subplot(3,1,3);
		plot(v, (v + 82) .* minf .* hinf, 'color', 'black')
		legend('Current');
		linkaxes(a, 'x');
		return
	end
	
	m = m + dt * (minf - m) / mtau;
	h = h + dt * (hinf - h) / htau;	
	if m < 0, m = 0; end
	if m > 1, m = 1; end
	if h < 0, h = 0; end
	if h > 1, h = 1; end
	mOut = m;
	hOut = h;
% 	alpham = mtau/minf;
% 	betam = (1-mtau)/minf;
% 	alphah = htau/hinf;
% 	betah = (1-htau)/hinf;
% 	
% % Determine new states for the gates
% 	m = (m + dt * alpham) / (1 + dt * (alpham + betam));  % IA activation gate
% 	h = (h + dt * alphah) / (1 + dt * (alphah + betah));  % IA inactivation gate

% Calculate the conductance
	fractionalConductance = m * h;  
	
% % Activation gate
% 	function a = alpham
% 		theta = (v + 45) / 10;
% 		if theta == 0   %check for case that gives 0/0
% 			a = 1.0;  %in that case use L'Hospital's rule
% 		else
% 			a = 1.0 * theta / (1 - exp(-theta));
% 		end
% 	end
% 
% 	function b = betam
% 		theta = (v + 70) / 18;
% 		b = .5 * exp(-theta);
% 	end
% 
% % Inactivation gate
% 	function a = alphah
% 		theta = (v + 70) / 20;
% 		a = 0.15 * exp(-theta);
% 	end
% 
% 	function b = betah
% 		theta = (v + 40) / 10;
% 		b = 1.0 / (1 + exp(-theta));	
% 	end
end