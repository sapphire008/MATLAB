% Lab 3: Build a Hodgkin-Huxley model neuron; stimulate to produce AP’s; plot V and 
% activation and inactivation variables m, h, and n; and calculate firing rate
clear all; %clear all variables
close all; %close any open matlab windows
%DEFINE PARAMETERS
dt = 0.1; %time step [ms]
t_end = 70; %total time of run [ms]
t_StimStart = 10; %time to start injecting current [ms]
t_StimEnd = 60; %time to end injecting current [ms]
c = 10; %capacitance per unit area [nF/mm^2]
gmax_L = 0.003e3; %leak maximal conductance per unit area [uS/mm^2]
E_L = -54.387; %leak conductance reversal potential [mV]
gmax_K = 0.36e3; %hodgkin-huxley maximal K conductance per unit area [uS/mm^2]
E_K = -77; %hodgkin-huxley K conductance reversal potential [mV]
gmax_Na = 1.2e3; %hodgkin-huxley maximal Na conductance per unit area [uS/mm^2]
E_Na = 50; %hodgkin-huxley Na conductance reversal potential [mV]
%SET UP VECTORS TO BE PLOTTED
t_vect = 0:dt:t_end; %will hold vector of times
V_vect = zeros(1,length(t_vect)); %initialize the voltage vector
m_vect = zeros(1,length(t_vect)); %initialize the HH Na activation variable vector
h_vect = zeros(1,length(t_vect)); %initialize the HH Na inactivation variable vector
n_vect = zeros(1,length(t_vect)); %initialize the HH K activation variable vector
%DEFINE THE STIMULUS
%vector below will hold values of I_e/A over time;
I_0 = 20; %magnitude of pulse of injected current [nA/mm^2]
I_e_vect = zeros(1,t_StimStart/dt); %portion of I_e/A vector from t=0 to t=t_StimStart
I_e_vect = [I_e_vect I_0*ones(1,1+((t_StimEnd-t_StimStart)/dt))]; %add portion from 
 % t=t_StimStart to t=t_StimEnd
I_e_vect = [I_e_vect zeros(1,(t_end-t_StimEnd)/dt)]; %add portion from 
 % t=t_StimEnd to t=t_end
%ASSIGN INITIAL VALUES OF VARIABLES
i = 1; %index denoting which element of V is being assigned
V_vect(i)= -65; %first element of V, i.e. value of V at t=0 [mV]
m_vect(i) = 0.0529; %initially set m = m_inf(-65)
h_vect(i) = 0.5961; %initially set h = h_inf(-65)
n_vect(i) = 0.3177; %initially set n = n_inf(-65)

%% Solve the V(t) equation
for t=dt:dt:t_end %loop through values of t in steps of dt ms
 %assign all of the alphas & betas
 alpha_m = .1*(V_vect(i)+40)/(1 - exp(-.1*(V_vect(i)+40)));
 beta_m = 4*exp(-.0556*(V_vect(i)+65));
 alpha_h = .07*exp(-.05*(V_vect(i)+65));
 beta_h = 1/(1 + exp(-.1*(V_vect(i)+35)));
 alpha_n = .01*(V_vect(i)+55)/(1 - exp(-.1*(V_vect(i)+55)));
 beta_n = 0.125*exp(-0.0125*(V_vect(i)+65));
 %from the alphas & betas above, assign the taus & x_inf's for m,h,nNPB/NSC 167/267 
 tau_m = 1/(alpha_m + beta_m);
 m_inf = alpha_m/(alpha_m + beta_m);
 tau_h = 1/(alpha_h + beta_h);
 h_inf = alpha_h/(alpha_h + beta_h);
 tau_n = 1/(alpha_n + beta_n);
 n_inf = alpha_n/(alpha_n + beta_n);
 %assign tau_V and V_inf
 V_denominator = gmax_L + gmax_K*(n_vect(i)^4) + gmax_Na*(m_vect(i)^3)*h_vect(i);
 tau_V = c/V_denominator;
 V_inf =(gmax_L*E_L + gmax_K*(n_vect(i)^4)*E_K + ... %... let's you continue on next line
 gmax_Na*(m_vect(i)^3)*h_vect(i)*E_Na + I_e_vect(i))/V_denominator;
 %assign next elements of m,h,and n vectors using update rule
 m_vect(i+1) = m_inf + (m_vect(i) - m_inf)*exp(-dt/tau_m);
 h_vect(i+1) = h_inf + (h_vect(i) - h_inf)*exp(-dt/tau_h);
 n_vect(i+1) = n_inf + (n_vect(i) - n_inf)*exp(-dt/tau_n);
 %assign next element of V vector using update rule
 V_vect(i+1) = V_inf + (V_vect(i) - V_inf)*exp(-dt/tau_V);
 %add 1 to index, corresponding to moving forward 1 time step
 i = i+1;
end

%% Plotting
figure(1)
subplot(4,1,1)
plot(t_vect,V_vect)
title('Hodgkin Huxley variables vs. time');
ylabel('Voltage in mV');
subplot(4,1,2)
plot(t_vect,m_vect)
ylabel('g_{Na} activation variable m');
subplot(4,1,3)
plot(t_vect,h_vect)
ylabel('g_{Na} inactivation variable h');
subplot(4,1,4)
plot(t_vect,n_vect)
xlabel('Time in ms');
ylabel('g_{K} activation variable n');
figure(2)
plot(t_vect,V_vect) %plot in blue
title('Hodgkin Huxley variables vs. time');
hold on
plot(t_vect,100*m_vect,'k') %plot in black
plot(t_vect,100*h_vect,'r') %plot in red
plot(t_vect,100*n_vect,'g') %plot in green
ylabel('V, m*100, h*100,or n*100');
xlabel('Time in ms');
legend('V', 'm*100', 'h*100','n*100') 
figure(3)
plot(t_vect,V_vect) %plot in blue
title('Hodgkin Huxley variables vs. time');
hold on
plot(t_vect,100*m_vect.^3,'k') %plot in black
plot(t_vect,100*h_vect,'r') %plot in red
plot(t_vect,100*n_vect.^4,'g') %plot in green

plot(t_vect,100*m_vect.^3.*h_vect,'m:') %plot in dotted magenta
ylabel('V, m^3*100, h*100,or n^4*100');
xlabel('Time in ms');
legend('V', 'm^3*100', 'h*100','n^4*100','m^3h*100')