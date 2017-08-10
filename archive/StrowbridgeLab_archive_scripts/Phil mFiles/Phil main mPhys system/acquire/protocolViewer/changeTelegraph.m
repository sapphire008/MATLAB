function changeTelegraph(ampNum, figHandle)
% loads the types of current channels into the appropriate channel
if nargin < 2
	figHandle = getappdata(0, 'runningProtocol');
end

% get amplifier output types
    protocolHandles = get(figHandle, 'userData');
    otherChannels = getpref('amplifiers', 'otherChannels');
    otherFactors = getpref('amplifiers', 'otherChannelFactors');
    adBoard = getappdata(0, 'adBoard');
	
% determine which amp if none was passed
    if nargin < 1
        ampNum = find(protocolHandles.ampTelegraph == gcbo);
    end
    
if isfield(protocolHandles, 'channelType')

	lastChannel = get(protocolHandles.ampTelegraph(ampNum), 'userData');
% 	if lastChannel == get(protocolHandles.ampTelegraph(ampNum), 'value');
% 		return
% 	end	

	% is the value negative
	if get(protocolHandles.ampCurrent(ampNum), 'value') > 0	 && get(protocolHandles.ampTelegraph(ampNum), 'value') < adBoard.numRead + 1 % not in hardware mode or channel disabled
    % check to make sure the channel isn't already in use
		% determine which amp is using this channel
		if any(cell2mat(get(protocolHandles.ampVoltage, 'value')) == get(protocolHandles.ampTelegraph(ampNum) ,'value')) 
			oldAmp = find(cell2mat(get(protocolHandles.ampVoltage, 'value')) == get(protocolHandles.ampTelegraph(ampNum) ,'value'));
			if strcmp(questdlg(['Channel ' num2str(get(protocolHandles.ampTelegraph(ampNum), 'value')) ' is currently being used for voltage channel of amp ' char(oldAmp + 64)  '.  Setting this channel to be the voltage channel for amp ' char(ampNum + 64) ' will set the voltage channel of amp ' char(oldAmp + 64) ' to none.'], '', 'Do it', 'Cancel', 'Do it'), 'Do it')
				% set the other channel to 'disabled'
				set(protocolHandles.ampVoltage(oldAmp), 'value', numel(get(protocolHandles.ampVoltage(oldAmp), 'string')));
				changeVoltage(oldAmp);
			else
				set(protocolHandles.ampTelegraph(ampNum), 'value', lastChannel);
				return
			end
		elseif any(cell2mat(get(protocolHandles.ampCurrent, 'value')) == get(protocolHandles.ampTelegraph(ampNum) ,'value')) 
			oldAmp = find(cell2mat(get(protocolHandles.ampCurrent, 'value')) == get(protocolHandles.ampTelegraph(ampNum) ,'value'));
			if strcmp(questdlg(['Channel ' num2str(get(protocolHandles.ampTelegraph(ampNum), 'value')) ' is currently being used for current channel of amp ' char(oldAmp + 64)  '.  Setting this channel to be the voltage channel for amp ' char(ampNum + 64) ' will set the current channel of amp ' char(oldAmp + 64) ' to none.'], '', 'Do it', 'Cancel', 'Do it'), 'Do it')
				% set the other channel to 'disabled'
				set(protocolHandles.ampCurrent(oldAmp), 'value', numel(get(protocolHandles.ampCurrent(oldAmp), 'string')));
				changeCurrent(oldAmp);
			else
				set(protocolHandles.ampTelegraph(ampNum), 'value', lastChannel);
				return
			end		
		elseif any(cell2mat(get(protocolHandles.ampTelegraph([1:ampNum - 1 ampNum + 1:end]), 'value')) == get(protocolHandles.ampTelegraph(ampNum) ,'value')) 
			oldAmp = find(cell2mat(get(protocolHandles.ampTelegraph([1:ampNum - 1 ampNum + 1:end]), 'value')) == get(protocolHandles.ampTelegraph(ampNum) ,'value'));
			if oldAmp > ampNum
				oldAmp = oldAmp + 1;
			end			
			if strcmp(questdlg(['Channel ' num2str(get(protocolHandles.ampTelegraph(ampNum), 'value')) ' is currently being used for telegraph channel of amp ' char(oldAmp + 64)  '.  Setting this channel to be the voltage channel for amp ' char(ampNum + 64) ' will set the telegraph channel of amp ' char(oldAmp + 64) ' to none.'], '', 'Do it', 'Cancel', 'Do it'), 'Do it')
				% set the other channel to 'disabled'
				set(protocolHandles.ampTelegraph(oldAmp), 'value', numel(get(protocolHandles.ampTelegraph(oldAmp), 'string')));
				changeTelegraph(oldAmp);
			else
				set(protocolHandles.ampTelegraph(ampNum), 'value', lastChannel);
				return
			end		
		else
			% channel was a member of other
		end
		
    % set the choices 
        set(protocolHandles.channelType(get(protocolHandles.ampTelegraph(ampNum), 'value')),...
            'string', 'Gain Telegraph',...
            'userData', {1});
        setappdata(protocolHandles.channelType(get(protocolHandles.ampTelegraph(ampNum), 'value')), 'source', ['Amp ' char(64 + ampNum) ', ']);        
            
		if lastChannel < adBoard.numRead + 1
			lastValue = get(protocolHandles.channelType(lastChannel), 'value');
			if numel(get(protocolHandles.ampCurrent(ampNum), 'string')) >= lastValue
				set(protocolHandles.channelType(get(protocolHandles.ampTelegraph(ampNum), 'value')),...
					'value', lastValue);
			else
				set(protocolHandles.channelType(get(protocolHandles.ampTelegraph(ampNum), 'value')),...
					'value', 1);
			end
		else
			set(protocolHandles.channelType(get(protocolHandles.ampTelegraph(ampNum), 'value')),...
				'value', 1);			
		end
	end
	
    % check to see if a choice was already made on the last channel selected    
	if ~strcmp(get(gcbo, 'tag'), 'ampType') || (strcmp(get(gcbo, 'tag'), 'ampType') && get(gcbo, 'value') == 1)  || get(protocolHandles.ampCurrent(ampNum), 'value') < 0	
        if lastChannel ~= get(protocolHandles.ampTelegraph(ampNum), 'value') && lastChannel < adBoard.numRead + 1
            % free this channel for other uses
            set(protocolHandles.channelType(lastChannel),...
                'string', otherChannels,...
                'userData', otherFactors,...
                'value', 1);
            setappdata(protocolHandles.channelType(lastChannel), 'source', ['AD ' sprintf('%1.0f', lastChannel - 1) ', ']);            
        end
    
		% save information about this time for next    
		if get(protocolHandles.ampCurrent(ampNum), 'value') > 0		
			set(protocolHandles.ampTelegraph(ampNum), 'userData', get(protocolHandles.ampTelegraph(ampNum), 'value'));
		end
    end
    
    changeCurrent(ampNum, figHandle);
	
	changeRunningChannel;
end