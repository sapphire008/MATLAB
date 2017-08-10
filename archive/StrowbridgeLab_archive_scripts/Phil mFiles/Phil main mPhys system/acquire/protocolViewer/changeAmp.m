function changeAmp(ampNum, figHandle)

if nargin < 1
	figHandle = gcf;
end

% loads the types of current channels into the appropriate channel

% get amplifier output types
    protocolHandles = get(figHandle, 'userData');
    currentFactors = getpref('amplifiers', 'currentFactors');  

% determine which amp if none was passed
	if nargin < 1
        ampNum = find(protocolHandles.ampType == gcbo);
	end
    
if isnan(currentFactors{get(protocolHandles.ampType(ampNum), 'value'), 1})	
	if numel(protocolHandles.ampType) > 1 && any(isnan(cell2mat(currentFactors{cell2mat(get(protocolHandles.ampType([1:ampNum - 1 ampNum + 1:end]), 'value')), 1})))
		currentValue = get(protocolHandles.ampType(ampNum), 'value');
		if numel(get(protocolHandles.ampType(ampNum), 'string')) > currentValue
			set(protocolHandles.ampType(ampNum), 'value', currentValue + 1);
		else
			set(protocolHandles.ampType(ampNum), 'value', currentValue - 1);
		end
		error('Only one simulated amplifier allowed')
	end
	% this is a simulation channel
	warning off all
	set(protocolHandles.ampVoltage(ampNum), 'value', -2*ampNum);
	set(protocolHandles.ampCurrent(ampNum), 'value', -2*ampNum - 1);
	set(protocolHandles.ampTelegraph(ampNum), 'value', numel(get(protocolHandles.ampTelegraph(ampNum), 'string')), 'visible', 'off');
	set(protocolHandles.ampStimulus(ampNum), 'userData', get(protocolHandles.ampStimulus(ampNum), 'value'));
	set(protocolHandles.ampStimulus(ampNum), 'value', -ampNum);
	set(protocolHandles.ampSaveStim(ampNum), 'value', 0, 'visible', 'off');
	set(protocolHandles.ampCellLocation(ampNum), 'string', {'Tonic Spiking','Phasic Spiking','Tonic Bursting','Phasic Bursting','Mixed Mode','Spike Freq Adapt','Class 1 exc','Class 2 exc','Spike Latency','Subthreshold Osc','Resonator','Integrator','Rebound Spike','Rebound Burst','Thresh Variability','Bistability','DAP','Accomodation (?)','Inh Induced Spiking','Inh Induced Bursting','Hogkin Huxley'});
	set(protocolHandles.cmdSealTest(ampNum), 'visible', 'off');
else
	if get(protocolHandles.ampVoltage(ampNum), 'value') < 1
		set(protocolHandles.ampVoltage(ampNum), 'visible', 'on', 'value', get(protocolHandles.ampVoltage(ampNum), 'userData'), 'userData', nan);
		set(protocolHandles.ampCurrent(ampNum), 'visible', 'on', 'value', get(protocolHandles.ampCurrent(ampNum), 'userData'), 'userData', nan);
		set(protocolHandles.ampTelegraph(ampNum), 'visible', 'on', 'value', get(protocolHandles.ampTelegraph(ampNum), 'userData'), 'userData', nan);				
		set(protocolHandles.ampStimulus(ampNum), 'visible', 'on', 'value', get(protocolHandles.ampStimulus(ampNum), 'userData'));			
	end		
	set(protocolHandles.ampSaveStim(ampNum), 'visible', 'on');
	set(protocolHandles.ampCellLocation(ampNum), 'string', [getpref('experiment', 'cellTypes') 'Other']);
	set(protocolHandles.cmdSealTest(ampNum), 'visible', 'on');	
end

% set the channelPanel values
	changeCurrent(ampNum, figHandle);
	changeVoltage(ampNum, figHandle);
	changeTelegraph(ampNum, figHandle);

% uncheck membrane potential tracking
	set(protocolHandles.ampTpEnable(ampNum), 'value', 0);