function fractionalConductance = gNa(v, dt)
% Hodgkin and Huxley Na+ channel
persistent m
persistent h

% Initialize gate conductances
if isempty(m)
	m = 0.053574609232333; % Na+ activation gate
	h = 0.592537659006699;  % Na+ inactivation gate
end

% Determine new states for the gates
	m = (m + dt * alpham) / (1 + dt * (alpham + betam));  % sodium activation gate
	h = (h + dt * alphah) / (1 + dt * (alphah + betah));  % sodium inactivation gate

% Calculate the conductance
	fractionalConductance = (m^3) * h;  
	
% Activation gate
	function a = alpham
		theta = (v + 45) / 10;
		if theta == 0   %check for case that gives 0/0
			a = 1.0;  %in that case use L'Hospital's rule
		else
			a = 1.0 * theta / (1 - exp(-theta));
		end
	end
		
	function b = betam
		theta = (v + 70) / 18;
		b = 4.0 * exp(-theta);
	end

% Inactivation gate
	function a = alphah
		theta = (v + 70) / 20;
		a = 0.07 * exp(-theta);
	end

	function b = betah
		theta = (v + 40) / 10;
		b = 1.0 / (1 + exp(-theta));	
	end
end