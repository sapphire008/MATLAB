function fractionalConductance = gK(v, dt)
% Hodgkin and Huxley K+ channel
persistent n

% Initialize gate conductances
if isempty(n)
	n = 0.319246167222218; % K+ activation gate
end

% Determine the new states for the gates
	n = (n + dt * alphan) / (1 + dt * (alphan + betan));  % potassium gate
	
% Calculate the conductance
	fractionalConductance = (n^4);

% Activation gate
	function a = alphan
		theta = (v + 60) / 10;
		if theta == 0   % check for case that gives 0/0
			a = 0.1;  % in that case use L'Hospital's rule
		else
			a = 0.1 * theta / (1 - exp(-theta));
		end
	end

	function b = betan
		theta = (v + 70) / 80;
		b = 0.125 * exp(-theta);
	end
end