function changeVoltage(ampNum, figHandle)
% loads the types of current channels into the appropriate channel
if nargin < 2
	figHandle = getappdata(0, 'runningProtocol');
end

% get amplifier output types
    protocolHandles = get(figHandle, 'userData');
    voltageChannels = getpref('amplifiers', 'voltageChannels');
    voltageFactors = getpref('amplifiers', 'voltageFactors');
    otherChannels = getpref('amplifiers', 'otherChannels');
    otherFactors = getpref('amplifiers', 'otherChannelFactors');
    adBoard = getappdata(0, 'adBoard');

% determine which amp if none was passed
    if nargin < 1
        ampNum = find(protocolHandles.ampVoltage == gcbo);
    end
    
if isfield(protocolHandles, 'channelType')

	lastChannel = get(protocolHandles.ampVoltage(ampNum), 'userData');
%     callStack = dbstack;
% 	if lastChannel == get(protocolHandles.ampVoltage(ampNum), 'value') && ~strcmp(callStack(end).name, 'changeAmp')
% 		return
% 	end

	% is the value negative
	if get(protocolHandles.ampCurrent(ampNum), 'value') > 0	&& get(protocolHandles.ampVoltage(ampNum), 'value') < adBoard.numRead + 1 % not in hardware mode or channel disabled
    % check to make sure the channel isn't already in use
		% determine which amp is using this channel
		if any(cell2mat(get(protocolHandles.ampVoltage([1:ampNum - 1 ampNum + 1:end]), 'value')) == get(protocolHandles.ampVoltage(ampNum) ,'value')) 
			oldAmp = find(cell2mat(get(protocolHandles.ampVoltage([1:ampNum - 1 ampNum + 1:end]), 'value')) == get(protocolHandles.ampVoltage(ampNum) ,'value'));
			if oldAmp > ampNum
				oldAmp = oldAmp + 1;
			end
			if strcmp(questdlg(['Channel ' num2str(get(protocolHandles.ampVoltage(ampNum), 'value')) ' is currently being used for voltage channel of amp ' char(oldAmp + 64)  '.  Setting this channel to be the voltage channel for amp ' char(ampNum + 64) ' will set the voltage channel of amp ' char(oldAmp + 64) ' to none.'], '', 'Do it', 'Cancel', 'Do it'), 'Do it')
				% set the other channel to 'disabled'
				set(protocolHandles.ampVoltage(oldAmp), 'value', numel(get(protocolHandles.ampVoltage(oldAmp), 'string')));
				changeVoltage(oldAmp);
			else
				set(protocolHandles.ampVoltage(ampNum), 'value', lastChannel);
				return
			end
		elseif any(cell2mat(get(protocolHandles.ampCurrent, 'value')) == get(protocolHandles.ampVoltage(ampNum) ,'value')) 
			oldAmp = find(cell2mat(get(protocolHandles.ampCurrent, 'value')) == get(protocolHandles.ampVoltage(ampNum) ,'value'));
			if strcmp(questdlg(['Channel ' num2str(get(protocolHandles.ampVoltage(ampNum), 'value')) ' is currently being used for current channel of amp ' char(oldAmp + 64)  '.  Setting this channel to be the voltage channel for amp ' char(ampNum + 64) ' will set the current channel of amp ' char(oldAmp + 64) ' to none.'], '', 'Do it', 'Cancel', 'Do it'), 'Do it')
				% set the other channel to 'disabled'
				set(protocolHandles.ampCurrent(oldAmp), 'value', numel(get(protocolHandles.ampCurrent(oldAmp), 'string')));
				changeCurrent(oldAmp);
			else
				set(protocolHandles.ampVoltage(ampNum), 'value', lastChannel);
				return
			end		
		elseif any(cell2mat(get(protocolHandles.ampTelegraph, 'value')) == get(protocolHandles.ampVoltage(ampNum) ,'value')) 
			oldAmp = find(cell2mat(get(protocolHandles.ampTelegraph, 'value')) == get(protocolHandles.ampVoltage(ampNum) ,'value'));
			if strcmp(questdlg(['Channel ' num2str(get(protocolHandles.ampVoltage(ampNum), 'value')) ' is currently being used for telegraph channel of amp ' char(oldAmp + 64)  '.  Setting this channel to be the voltage channel for amp ' char(ampNum + 64) ' will set the telegraph channel of amp ' char(oldAmp + 64) ' to none.'], '', 'Do it', 'Cancel', 'Do it'), 'Do it')
				% set the other channel to 'disabled'
				set(protocolHandles.ampTelegraph(oldAmp), 'value', numel(get(protocolHandles.ampTelegraph(oldAmp), 'string')));
				changeTelegraph(oldAmp);
			else
				set(protocolHandles.ampVoltage(ampNum), 'value', lastChannel);
				return
			end		
		else
			% channel used to be a member of other
		end
        
    % set the choices 
        set(protocolHandles.channelType(get(protocolHandles.ampVoltage(ampNum), 'value')),...
            'string', voltageChannels(get(protocolHandles.ampType(ampNum), 'value'), :),...
            'userData', voltageFactors(get(protocolHandles.ampType(ampNum), 'value'), :));
        setappdata(protocolHandles.channelType(get(protocolHandles.ampVoltage(ampNum), 'value')), 'source', ['Amp ' char(64 + ampNum) ', ']);
            
		if lastChannel < adBoard.numRead + 1
			lastValue = get(protocolHandles.channelType(lastChannel), 'value');
			if numel(get(protocolHandles.ampCurrent(ampNum), 'string')) >= lastValue
				set(protocolHandles.channelType(get(protocolHandles.ampVoltage(ampNum), 'value')),...
					'value', lastValue);
			else
				set(protocolHandles.channelType(get(protocolHandles.ampVoltage(ampNum), 'value')),...
					'value', 1);
			end
		else
			set(protocolHandles.channelType(get(protocolHandles.ampVoltage(ampNum), 'value')),...
				'value', 1);
		end
	end
	
    % check to see if a choice was already made on the last channel selected    
	if ~strcmp(get(gcbo, 'tag'), 'ampType') || (strcmp(get(gcbo, 'tag'), 'ampType') && get(gcbo, 'value') == 1)  || get(protocolHandles.ampCurrent(ampNum), 'value') < 0	
        if lastChannel ~= get(protocolHandles.ampVoltage(ampNum), 'value') && lastChannel < adBoard.numRead + 1
            % free this channel for other uses
            set(protocolHandles.channelType(lastChannel),...
                'string', otherChannels,...
                'userData', otherFactors,...
                'value', 1);
            setappdata(protocolHandles.channelType(lastChannel), 'source', ['AD ' sprintf('%1.0f', lastChannel - 1) ', ']);
        end
    
		% save information about this time for next   
		if get(protocolHandles.ampCurrent(ampNum), 'value') > 0		
			set(protocolHandles.ampVoltage(ampNum), 'userData', get(protocolHandles.ampVoltage(ampNum), 'value'));
		end
	end
	changeRunningChannel;
end