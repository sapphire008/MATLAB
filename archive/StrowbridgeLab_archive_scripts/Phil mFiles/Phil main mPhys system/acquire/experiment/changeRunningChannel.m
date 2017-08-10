function channelNames = changeRunningChannel(varargin)
    protocolHandles = get(getappdata(0, 'runningProtocol'), 'userData');
    if isempty(protocolHandles)
        return
    end
	experimentInfo = getappdata(0, 'currentExperiment');
	channelNames = {};
	numHits = 0;
	% add hardware channels
		for i = 1:numel(protocolHandles.channelType)
			tempString = get(protocolHandles.channelType(i), 'string');
			if ~iscell(tempString)
				tempString = {tempString};
			end
			if ~strcmp(tempString{get(protocolHandles.channelType(i), 'value')}, 'Disabled')
				sourceData = getappdata(protocolHandles.channelType(i), 'source');
				whereComma = find(sourceData == ',', 1, 'last');
				if ~isempty(whereComma) && (strcmp(sourceData(1:3), 'AD ') || experimentInfo.ampEnable{sourceData(whereComma - 1:whereComma - 1) - 64})				
					numHits = numHits + 1;
					indices(numHits) = i;
					channelNames{numHits} = [getappdata(protocolHandles.channelType(i), 'source') tempString{get(protocolHandles.channelType(i), 'value')}];
				end
			end
		end
		
	% add software channels
        if isfield(protocolHandles, 'ampType')
			currentFactors = getpref('amplifiers', 'currentFactors');
			for i = 1:numel(protocolHandles.ampType)
				if isnan(currentFactors{get(protocolHandles.ampType(i), 'value'), 1})
					numHits = numHits + 1;
					indices(numHits) = -2 * i;
					channelNames{numHits} = ['Amp ' char(64 + i) ' Voltage'];
					numHits = numHits + 1;
					indices(numHits) = -2 * i - 1;
					channelNames{numHits} = ['Amp ' char(64 + i) ' Current'];
				end
			end
        end
	
    if ~nargout
        if ~isappdata(0, 'runningScope')
            return
        end
        scopeHandles = get(getappdata(0, 'runningScope'), 'userData');
        % put the data in the popup
        if numel(channelNames)
            set([scopeHandles.channelControl.channel], 'string', channelNames,...
                'userData', indices);
        else
            close(getappdata(0, 'runningScope'));
            return
        end
    end
