function  [waveform, duration] = AWF_ERG_VoltClamp_08012017(savedir, boolplot)
% Makes AWF resulting the protocol: Neg - Leak - Leak - Test
protocol = 'V1/2'; % V1/2, activation_tau, deactivation_tau
iterator = '0'; % helps sipmly the process of iteating through different values of each protocol

ts = 0.1; % sampling rate [ms]
factor = 160; % ITC 18 scaling factor 16 * Voltage (10x Vm)
offset_factor = 0; % Make a correction if Initial Amp under Step Control on Edit Protocol is not zero
Duration = 30000; % force duration

if nargin<1, savedir = 'D:/Edward/AWF/ERG_Deac80mV_AWF.dat'; end
if nargin<2, boolplot = true; end

RestingVolt = -80; % RMP (mV);
RestingDuration = 200; % time of rest period before anything starts
NegVolt = -90; % Initial Negative pulse voltage [mV]
NegDuration = 800; % Initial Negative pulse duration [mV]

ActivationDuration = [4000, 3000]; % [duration of depolarizing step, duration of ramp (optional)]
ActivationVolt = 0; % Voltage to depolarize to

DeactivationDuration = 2000; % Duration of tail current step before returning to RMP
%% #######################################################################
DeactivationVolt = -120; % Voltage to hyperpolarize to (mV)
%% #######################################################################

LeakProtocolScale = 4; % ratio of current measuring protocol vs. leak subtraction protocol
TimeBetweenLeakTest = 1500; % time between the pulses (between periods of Neg - Leak - Leak - Test) [ms]

%% Making the protocol
% Initialize
Steps = []; % N x M matrix, [Amp; Duration]
% Make the initial rest and negative pulse part
Steps(1:2,1) = [RestingVolt; RestingDuration];
Steps(:,  2)  = [NegVolt; NegDuration];

% Make the AWF based on protocol used
switch protocol
    case 'V1/2'
        % Replace some default values
        ActivationVolt = [-70, -60, -50, -40, -30, -20, -10, 0]; % A range of activation level
        if isnumeric(iterator)
            ActivationVolt = ActivationVolt(iterator); % Get the value for a specific iteration
        elseif ischar(iterator)
            ActivationVolt = str2num(iterator);
        end
        
        % First make the test protocol
        Step_A = [];
        Step_A(1:2, 1) = [RestingVolt;      TimeBetweenLeakTest];
        Step_A(:, 2) =   [ActivationVolt;   ActivationDuration(1)];
        Step_A(:, 3) =   [DeactivationVolt; DeactivationDuration];
        Step_A(:, 4) =   [RestingVolt;      TimeBetweenLeakTest];

        % Make the leak protocol
        Step_L = [];
        Step_L(1:2, 1) =  [RestingVolt;     TimeBetweenLeakTest];
        Leak_Step = (RestingVolt - ActivationVolt) / LeakProtocolScale + RestingVolt;
        Step_L(:,   2) =  [Leak_Step; ActivationDuration(1)];
        Leak_Tail =  Leak_Step + (ActivationVolt - DeactivationVolt) / LeakProtocolScale;
        Step_L(:,   3) =  [Leak_Tail;       DeactivationDuration];
    case 'activation_tau'
        % Replace some default values
        ActivationDuration = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000]; %A range of activation duration level
        maxActivationDuration = max(ActivationDuration);
        if isnumeric(iterator)
            ActivationDuration = ActivationDuration(iterator); % Get the value for a specific iteration
        elseif ischar(iterator)
            ActivationDuration = str2num(iterator);
        end
        
        % First make the test protocol
        Step_A = [];
        Step_A(1:2, 1) = [RestingVolt;   TimeBetweenLeakTest];
        Step_A(:,   2) = [ActivationVolt;   ActivationDuration];
        Step_A(:,   3) = [DeactivationVolt; DeactivationDuration];
        Step_A(:,   4) = [RestingVolt;      TimeBetweenLeakTest + maxActivationDuration - ActivationDuration];
        
        % Make the leak protocol
        Step_L = [];
        Step_L(1:2, 1) = [RestingVolt;      TimeBetweenLeakTest];
        Leak_Step = (RestingVolt - ActivationVolt) / LeakProtocolScale + RestingVolt;
        Step_L(:,   2) = [Leak_Step; ActivationDuration];
        Leak_Tail = Leak_Step + (ActivationVolt - DeactivationVolt) / LeakProtocolScale;
        Step_L(:,   3) =  [Leak_Tail;       DeactivationDuration];
        Step_L(:,   4) =  [RestingVolt;     maxActivationDuration - ActivationDuration]; % append to align the activation time in the trace
    otherwise
        error('Check protocol Spelling');
end


% Concatenate
Steps = {Steps, Step_L, Step_L, Step_A};
% Convert Steps into traces
waveform = [];
for n = 1: length(Steps)
    for m = 1:size(Steps{n},2)
        if n > 1 && m ==2 && length(ActivationDuration) > 1
            InitialVolt = Steps{n}(1,m-1);
            EndVolt = Steps{n}(1,m);
            Ramp = factor * linspace(InitialVolt, EndVolt, ActivationDuration(2)/ts);
            Plateau = factor * Steps{n}(1,m)* ones(1,length(0:ts:Steps{n}(2,m))-1-length(Ramp));
            waveform = [waveform, Ramp, Plateau];
            
        else
            waveform = [waveform, factor * Steps{n}(1,m)*ones(1, length(0:ts:Steps{n}(2,m))-1)];
        end
    end
end
waveform = waveform - offset_factor * factor;
duration = length(waveform)*ts;
if ~isnan(Duration)
    if duration > Duration
        waveform = waveform(1:(Duration/ts));
    elseif duration < Duration
        waveform = [waveform, waveform(end) * ones(1, (Duration-duration)/ts)];
    end
    duration = length(waveform) * ts;
end

disp(duration);

% Write protocol to binary file
fid = fopen(savedir,'w');
%fwrite(fid, waveform, 'float64');
fprintf(fid, '%.2f\r\n', waveform);
fclose(fid);
if boolplot
    close;
    t = (0:ts:duration)/1000;
    plot(t(1:end-1), waveform/factor + offset_factor);
    set(gcf, 'Position', [100,800,1500,300]);
    switch protocol
        case 'V1/2'
            title(sprintf('V_{1/2 max} protocol at %d mV', ActivationVolt));
        case 'activation_tau'
            title(sprintf('tau_{act} protocol at %d ms', ActivationDuration));
    end
end
end