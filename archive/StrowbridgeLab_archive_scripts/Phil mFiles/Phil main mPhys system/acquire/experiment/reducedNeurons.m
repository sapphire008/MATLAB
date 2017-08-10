function [VV II] =  reducedNeurons(cellType, I, tau, numPoints)
%   This MATLAB file generates cells as per Izhikevich E.M. (2004) 
% I is the current stimulus, tau, the time step, and numPoints the number
% of points desired as output if this number is less than length(I)
%
% Choices of cell type can be made by letter or short name, and are:
%  (A) tonic spiking
%  (B) phasic spiking              
%  (C) tonic bursting              
%  (D) phasic bursting             
%  (E) mixed mode                  
%  (F) spike frequency adaptation        
%  (G) Class 1 excitatory                 
%  (H) Class 2 excitatory               
%  (I) spike latency                
%  (J) subthreshold oscillations            
%  (K) resonator                    
%  (L) integrator                   
%  (M) rebound spike                
%  (N) rebound burst                
%  (O) threshold variability          
%  (P) bistability                  
%  (Q) DAP                          
%  (R) accomodation (may not work)  
%  (S) inhibition induced spiking   
%  (T) inhibition induced bursting  
%  (U) HH Cell Models
%  (Z) reset whatever cell model you are running to its initialized params

persistent V
persistent u
persistent lastCell
persistent readBufferV % so that this can better emulate hardware
persistent readBufferI

if isempty(readBufferV)
	readBufferI = [];
	readBufferV = [];
end

if nargin == 0
    % generate the figure from Izhikevich E.M. (2004) 
    figure('numberTitle', 'off', 'name', 'Izhikevich Cell Types');
    tau = 0.25;   
    
    subplot(5,4,1)
    tspan = (0:tau:100)'; 
    T1 = numel(tspan) / 10 * tau;
    plot(tspan,reducedNeurons('A', [zeros(T1 / tau, 1); 14 .* ones(numel(tspan) - T1 / tau + 1, 1)], tau),[0 T1 T1 max(tspan)],-90+[0 0 10 10]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(A) tonic spiking');
    
    subplot(5,4,2)
    tspan = (0:tau:200)'; 
    T1 = 20;
    plot(tspan,reducedNeurons('B', [zeros(T1/tau, 1); 0.5 .* ones(numel(tspan) - T1/tau, 1)], tau),[0 T1 T1 max(tspan)],-90+[0 0 10 10]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(B) phasic spiking');

    subplot(5,4,3)
    tspan = (0:tau:220)'; 
    T1 = 22;
    plot(tspan,reducedNeurons('C', [zeros(T1/tau, 1); 15 .* ones(numel(tspan) - T1/tau, 1)], tau),[0 T1 T1 max(tspan)],-90+[0 0 10 10]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(C) tonic bursting');
    
    subplot(5,4,4)
    tspan = (0:tau:200)'; 
    T1 = 20;
    plot(tspan,reducedNeurons('D', [zeros(T1/tau, 1); 0.6 .* ones(numel(tspan) - T1/tau, 1)], tau),[0 T1 T1 max(tspan)],-90+[0 0 10 10]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(D) phasic bursting');
    
    subplot(5,4,5)
    tspan = (0:tau:160)'; 
    T1 = numel(tspan) / 10 * tau;
    plot(tspan,reducedNeurons('E', [zeros(T1/tau, 1); 10 .* ones(numel(tspan) - T1/tau + 1, 1)], tau),[0 T1 T1 max(tspan)],-90+[0 0 10 10]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(E) mixed mode');
    
    subplot(5,4,6)
    tspan = (0:tau:85)'; 
    T1 = numel(tspan) / 10 * tau;
    plot(tspan,reducedNeurons('F', [zeros(T1/tau, 1); 30 .* ones(numel(tspan) - T1/tau + 1, 1)], tau),[0 T1 T1 max(tspan)],-90+[0 0 10 10]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(F) spike freq. adapt');
    
    subplot(5,4,7)
    tspan = (0:tau:300)'; 
    T1 = 30;
    plot(tspan,reducedNeurons('G', [zeros(T1/tau, 1); 0.075 .* (tspan(T1/tau + 1:end) - T1)], tau),[0 T1 max(tspan) max(tspan)],-90+[0 0 20 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(G) Class 1 excitable');
    
    subplot(5,4,8)
    tspan = (0:tau:300)'; 
    T1 = 30;
    plot(tspan,reducedNeurons('H', [zeros(T1/tau, 1); 0.5 + 0.015 .* (tspan(T1/tau + 1:end) - T1)], tau),[0 T1 max(tspan) max(tspan)],-90+[0 0 20 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(H) Class 2 excitable');

    subplot(5,4,9)
    tau = 0.2;
    tspan = (0:tau:100)'; 
    T1 = numel(tspan) / 10 * tau;
    plot(tspan,reducedNeurons('I', [zeros(T1/tau - 1, 1); 7.04 .* ones(3/tau, 1); zeros(numel(tspan) - (T1 + 3)/tau + 2, 1)], tau),[0 T1 T1 T1+3 T1+3 max(tspan)],-90+[0 0 10 10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(I) spike latency');
    
    subplot(5,4,10)
    tau = 0.25;
    tspan = (0:tau:200)'; 
    T1 = numel(tspan) / 10 * tau;
    plot(tspan,reducedNeurons('J', [zeros(T1/tau - 1, 1); 2 .* ones(5/tau, 1); zeros(numel(tspan) - (T1 + 5)/tau + 2, 1)], tau),[0 T1 T1 (T1+5) (T1+5) max(tspan)],-90+[0 0 10 10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(J) subthreshold osc.');
    
    subplot(5,4,11)
    tspan = (0:tau:400)'; 
    T1 = numel(tspan) / 10 * tau;
    T2 = T1 + 20;
    T3 = 0.7 * numel(tspan) * tau;
    T4 = T3 + 40;
    plot(tspan,reducedNeurons('K', [zeros(T1/tau - 1, 1); 0.65.*ones(4/tau, 1); zeros((T2-T1 - 4)/tau - 2, 1); 0.65.*ones(4/tau, 1); zeros((T3-T2-4)/tau - 2, 1); 0.65.*ones(4/tau, 1); zeros((T4-T3-4)/tau - 2, 1); 0.65.*ones(4/tau,1); zeros(numel(tspan) - (T4 - 4)/tau -24, 1)], tau),[0 T1 T1 (T1+8) (T1+8) T2 T2 (T2+8) (T2+8) T3 T3 (T3+8) (T3+8) T4 T4 (T4+8) (T4+8) max(tspan)],-90+[0 0 10 10 0 0 10 10 0 0 10 10 0 0 10 10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(K) resonator');    
    
    subplot(5,4,12)
    tspan = (0:tau:100)'; 
    T1 = numel(tspan) / 11 * tau;
    T2 = T1 + 5;
    T3 = 0.7 * numel(tspan) * tau;
    T4 = T3 + 10;
    plot(tspan,reducedNeurons('L', [zeros(T1/tau - 1, 1); 9.*ones(2/tau, 1); zeros((T2-T1-2)/tau - 2, 1); 9.*ones(2/tau, 1); zeros((T3-T2-2)/tau - 2, 1); 9.*ones(2/tau, 1); zeros((T4-T3-2)/tau - 2, 1); 9.*ones(2/tau, 1); zeros(numel(tspan) - T4/tau, 1)], tau),[0 T1 T1 (T1+2) (T1+2) T2 T2 (T2+2) (T2+2) T3 T3 (T3+2) (T3+2) T4 T4 (T4+2) (T4+2) max(tspan)],-90+[0 0 10 10 0 0 10 10 0 0 10 10 0 0 10 10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(L) integrator');        
    
    subplot(5,4,13)
    tau = 0.2;
    tspan = (0:tau:200)'; 
    T1 = 20;
    plot(tspan,reducedNeurons('M', [zeros(T1/tau - 1, 1); -15.*ones(5/tau, 1); zeros(numel(tspan) - (T1+5) / tau + 1, 1)], tau),[0 T1 T1 (T1+5) (T1+5) max(tspan)],-85+[0 0 -5 -5 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(M) rebound spike');            
    
    subplot(5,4,14)
    tspan = (0:tau:200)'; 
    T1 = 20;    
    plot(tspan,reducedNeurons('N', [zeros(T1/tau - 1, 1); -15.*ones(5/tau, 1); zeros(numel(tspan) - (T1+5) / tau + 1, 1)], tau),[0 T1 T1 (T1+5) (T1+5) max(tspan)],-85+[0 0 -5 -5 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(N) rebound burst');      
    
    subplot(5,4,15)
    tau = 0.25;
    tspan = (0:tau:100)'; 
    plot(tspan,reducedNeurons('O', [zeros(10/tau - 1, 1); ones(5/tau, 1); zeros(55/tau - 1, 1); -6.*ones(5/tau, 1); zeros(5/tau - 1, 1); ones(5/tau,1); zeros(numel(tspan) - 85/tau + 3, 1)], tau),[0 10 10 15 15 70 70 75 75 80 80 85 85 max(tspan)],-85+[0 0  5  5  0  0  -5 -5 0  0  5  5  0  0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(O) thresh. variability');          
    
    subplot(5,4,16)
    tspan = (0:tau:300)'; 
    T1 = numel(tspan) / 8 * tau;    
    T2 = 216;
    plot(tspan,reducedNeurons('P', [0.24.*ones(T1/tau - 1, 1); 1.24.*ones(5/tau, 1); 0.24.*ones((T2-T1 - 5)/tau - 2, 1); 1.24.*ones(5/tau, 1); 0.24.*ones(numel(tspan) - (T2 + 5)/tau + 4, 1)], tau),[0 T1 T1 (T1+5) (T1+5) T2 T2 (T2+5) (T2+5) max(tspan)],-90+[0 0 10 10 0 0 10 10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(P) bistability');      
    
    subplot(5,4,17)
    tau = 0.1;
    tspan = (0:tau:50)'; 
    T1 = 10;    
    plot(tspan,reducedNeurons('Q', [zeros(T1/tau - 1, 1); 20.*ones(2/tau - 1, 1); zeros(numel(tspan) - (T1 + 2)/ tau + 2, 1)], tau),[0 T1-1 T1-1 T1+1 T1+1 max(tspan)],-90+[0 0 10 10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(Q) DAP         ');     
    
    subplot(5,4,18)
    tau = 0.5;
    tspan = (0:tau:400)'; 
    [VV II] = reducedNeurons('R', [tspan(1:200/tau)./25; zeros(100/tau - 1, 1); (tspan(300/tau:312.5/tau) - 300)/12.5*4; zeros(numel(tspan) - 312.5 / tau, 1)], tau);
    plot(tspan,VV,tspan,II*1.5-90);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(R) accomodation');
    
    subplot(5,4,19)
    tspan = (0:tau:350)'; 
    plot(tspan,reducedNeurons('S', [80.*ones(50/tau, 1); 75.*ones(200/tau - 1, 1); 75.*ones(numel(tspan) - 250/tau + 1, 1)], tau),[0 50 50 250 250 max(tspan)],-80+[0 0 -10 -10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(S) inh. induced sp.');

    subplot(5,4,20)
    tspan = (0:tau:350)'; 
    plot(tspan,reducedNeurons('T', [80.*ones(50/tau, 1); 75.*ones(200/tau - 1, 1); 75.*ones(numel(tspan) - 250/tau + 1, 1)], tau),[0 50 50 250 250 max(tspan)],-80+[0 0 -10 -10 0 0]);
    axis([0 max(tspan) -90 30])
    axis off;
    title('(T) inh. induced brst.');
    
    clear VV II;
    
    % plot the parameters space
    figure('numbertitle', 'off', 'name', 'Parameters');
    cellParams = [.02 .02 .02 .02 .02 .01 .02 .2 .02 .05 .1 .02 .03 .03 .03 .1 1 .02 -.02 -.026;...
        .2 .25 .2 .25 .2 .2 -.1 .26 .2 .26 .26 -.1 .25 .25 .25 .26 .2 1 -1 -1;...
        -65 -65 -50 -55 -55 -65 -55 -65 -65 -60 -60 -55 -60 -52 -60 -60 -60 -55 -60 -45;...
        6 6 2 .05 4 8 6 0 6 0 -1 6 4 0 4 0 -21 4 8 -2];
    xAxis = [1 1 1 2 2 3];
    yAxis = [2 3 4 3 4 4];
    for i = 1:6
        subplot(2,3,i);
        set(gca, 'xlim', [min(cellParams(xAxis(i),:)) max(cellParams(xAxis(i),:))], 'ylim', [min(cellParams(yAxis(i),:)) max(cellParams(yAxis(i),:))]);
        for j = 1:20
            text(cellParams(xAxis(i), j), cellParams(yAxis(i), j), char(64 + j));
        end
        xlabel(char(96 + xAxis(i)));
        ylabel(char(96 + yAxis(i)));
    end
    return;
end

if nargin == 1 && ischar(cellType) && strcmp(cellType, 'clearStim')
	readBufferI = [];
	readBufferV = [];
	VV = [];
	II = [];
	return
end

if isempty(lastCell)
	lastCell = 'Z';
end

if nargin < 3
    tau = .2; %msec per sample
end

if nargin == 4 && numPoints > length(readBufferV)
	% create a null stim
	if size(readBufferV, 1) == 1
		I = zeros(1, numPoints - length(readBufferV));
	else
		I = zeros(numPoints - length(readBufferV), 1);
	end
end

VV = zeros(size(I));

% add noise to the stimulus trace
if ~isempty(I)
	I = I + randn(size(VV)) * 2;
end

switch cellType
    case 'A'
        %%%%%%%%%%%%%%% (A) tonic spiking %%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=0.2;  c=-65;  d=6;
		if lastCell ~= cellType
			V=-70;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'B'
        %%%%%%%%%%%%%%%%%% (B) phasic spiking %%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=0.25; c=-65;  d=6;
		if lastCell ~= cellType
			V=-64; u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'C'
        %%%%%%%%%%%%%% (C) tonic bursting %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=0.2;  c=-50;  d=2;
		if lastCell ~= cellType
			V=-70;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'D'
        %%%%%%%%%%%%%%% (D) phasic bursting %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=0.25; c=-55;  d=0.05;
		if lastCell ~= cellType
			V=-64.4139110926861;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'E'
        %%%%%%%%%%%%%%% (E) mixed mode %%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=0.2;  c=-55;  d=4;
		if lastCell ~= cellType
			V=-70;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'F'
        %%%%%%%%%%%%%%%% (F) spike freq. adapt %%%%%%%%%%%%%%%%%%%%%%%%
        a=0.01; b=0.2;  c=-65;  d=8;
		if lastCell ~= cellType
			V=-70;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'G'
        %%%%%%%%%%%%%%%%% (G) Class 1 exc. %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=-0.1; c=-55; d=6;
		if lastCell ~= cellType
			V=-60; u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+4.1*V+108-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'H'
        %%%%%%%%%%%%%%%%%% (H) Class 2 exc. %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.2;  b=0.26; c=-65;  d=0;
		if lastCell ~= cellType
			V=-64;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'I'
        %%%%%%%%%%%%%%%%% (I) spike latency %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=0.2;  c=-65;  d=6;
		if lastCell ~= cellType
			V=-70;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'J'
        %%%%%%%%%%%%%%%%% (J) subthresh. osc. %%%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.05; b=0.26; c=-60;  d=0;
		if lastCell ~= cellType
			V=-62;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'K'
        %%%%%%%%%%%%%%%%%% (K) resonator %%%%%%%%%%%%%%%%%%%%%%%%
        a=0.1;  b=0.26; c=-60;  d=-1;
		if lastCell ~= cellType
			V=-62;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'L'
        %%%%%%%%%%%%%%%% (L) integrator %%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02; b=-0.1; c=-55; d=6;
		if lastCell ~= cellType
			V=-60; u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+4.1*V+108-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'M'
        %%%%%%%%%%%%%%%%% (M) rebound spike %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.03; b=0.25; c=-60;  d=4;
		if lastCell ~= cellType
			V=-64;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'N'
        %%%%%%%%%%%%%%%%% (N) rebound burst %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.03; b=0.25; c=-52;  d=0;
		if lastCell ~= cellType
			V=-64;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'O'
    %%%%%%%%%%%%%%%%% (O) thresh. variability %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.03; b=0.25; c=-60;  d=4;
		if lastCell ~= cellType
			V=-64;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'P'
        %%%%%%%%%%%%%% (P) bistability %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.1;  b=0.26; c=-60;  d=0;
		if lastCell ~= cellType
			V=-61;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'Q'
        %%%%%%%%%%%%%% (Q) DAP %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=1;  b=0.2; c=-60;  d=-21;
		if lastCell ~= cellType
			V=-70;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'R'
        %%%%%%%%%%%%%% (R) accomodation %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=0.02;  b=1; c=-55;  d=4;
		if lastCell ~= cellType
			V=-65;  u=-16;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*(V+65));
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end
        
    case 'S'
    %%%%%%%%%%%%%% (S) inhibition induced spiking %%%%%%%%%%%%%%%%%%%%%%%%%%
        a=-0.02;  b=-1; c=-60;  d=8;
		if lastCell ~= cellType
			V=-63.8;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end

    case 'T'
        %%%%%%%%%%%%%% (T) inhibition induced bursting %%%%%%%%%%%%%%%%%%%%%
        a=-0.026;  b=-1; c=-45;  d=-2;
		if lastCell ~= cellType
			V=-63.8;  u=b*V;
		end
        for t=1:length(I)
            V = V + tau*(0.04*V^2+5*V+140-u+I(t));
            u = u + tau*a*(b*V-u);
            if V > 30
                VV(t)=30;
                V = c;
                u = u + d;
            else
                VV(t)=V;
            end
        end
    case 'U'
        %%%%%%%%%%%%%% (U) Hodgkin-Huxley Model %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if lastCell ~= cellType
            V=-69.8976728963679;
        end
        VV = HH(I, tau, V);
	case 'Z'
		% don't need to do anything since last cell will not equal the next
		% cell
end

% add noise to voltage trace
numAlpha = round(rand(1) * 3) + 1;
if ~isempty(VV)
% 	VV = VV + randn(size(VV)) / 10 + alpha([rand(numAlpha,1), rand(numAlpha,1) * 5, rand(numAlpha,1) * 20, zeros(numAlpha,1)], 1:length(VV))';
end
lastCell = cellType;

if nargin == 4
	% save the output for future calls
    if size(readBufferV, 1) == 1
		readBufferV = [readBufferV VV];
		readBufferI = [readBufferI I];
	else
		readBufferV = [readBufferV; VV];
		readBufferI = [readBufferI; I];
    end
elseif nargout == 2
    II = I;
end

if numel(readBufferV) > 0
	if nargin == 4
		VV = readBufferV(1:numPoints);
		readBufferV(1:numPoints) = [];
		
		II = readBufferI(1:numPoints);
		readBufferI(1:numPoints) = [];
	else
		VV = readBufferV;
		readBufferV = [];
		
		II = readBufferI;
		readBufferI = [];
	end
end

if isnan(V)
	dbstop
end