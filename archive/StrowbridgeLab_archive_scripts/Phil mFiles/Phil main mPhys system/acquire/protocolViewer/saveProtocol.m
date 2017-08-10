function saveProtocol(inData, fileName)

%   save the current protocol to a file or to appdata
%   saveProtocol(protocolStructure, fileName)
%   saveProtocol(protocolStructure)  generates a guiputfile
%   saveProtocol('-currentProtocol', fileName) saves the currently active protocol to disk
%   saveProtocol('-currentProtocol') saves the currently active protcol with a guiputfile
%   saveProtocol() saves a protocol that is in a protocol browser to be the currently active protocol

if nargin == 0
    if ~isappdata(0, 'runningProtocol')
		return
    end
    
    % get handles to the protocol viewer
        handles = get(getappdata(0, 'runningProtocol'), 'userData');
        fields = fieldnames(handles);

    % load data from the protocol viewer
        for fieldIndex = 1:numel(fields)
			if strcmp(get(handles.(fields{fieldIndex}), 'type'), 'uicontrol')
                switch get(handles.(fields{fieldIndex})(1), 'style')
                    case 'edit'
                        if ismember(fields{fieldIndex}, {'sweepWindow', 'timePerPoint', 'imageDuration'})
                            inData.(fields{fieldIndex}) = str2double(get(handles.(fields{fieldIndex}), 'string'));
                        elseif ismember(fields{fieldIndex}, {'ampTpSetPoint', 'ampTpMaxCurrent', 'ampTpMaxPer', 'ampSealTestStep', 'ampBridgeBalanceStep'})
                            inData.(fields{fieldIndex}) = str2double(get(handles.(fields{fieldIndex}), 'string'));                            
                            for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
                                tempData{instanceIndex, 1} = inData.(fields{fieldIndex})(instanceIndex);
                            end                            
                            inData.(fields{fieldIndex}) = tempData;
                        else
                            inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'string');
                            if ~iscell(inData.(fields{fieldIndex}))
                                inData.(fields{fieldIndex}) = {inData.(fields{fieldIndex})};
                            end
                        end
                    case 'checkbox'
                        inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'value');
						if ~iscell(inData.(fields{fieldIndex}))
                            inData.(fields{fieldIndex}) = {inData.(fields{fieldIndex})};
						end    
					case 'popupmenu'
                        if ~ismember(fields{fieldIndex}, {'ampType', 'ampCellLocation', 'ttlType', 'source'})
							inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'value');
							if ~iscell(inData.(fields{fieldIndex}))
								inData.(fields{fieldIndex}) = {inData.(fields{fieldIndex})};
							end  						
						else
							stringData = get(cell2mat(handles.(fields{fieldIndex})(1)), 'string');
							if ~iscell(stringData)
								stringData = {stringData};
							end
							inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'value');
							
							inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'value');							
							if ~iscell(inData.(fields{fieldIndex}))
								inData.(fields{fieldIndex}) = {inData.(fields{fieldIndex})};
							end							
							for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
								inData.([fields{fieldIndex} 'Name']){instanceIndex} = stringData{inData.(fields{fieldIndex}){instanceIndex}};
							end
                        end
                end
            else
                if strcmp(fields{fieldIndex}, 'imageScan')
                    inData.(fields{fieldIndex}) = get(get(handles.(fields{fieldIndex}), 'selectedObject'), 'tag');
                end                
			end
        end
        
    % determine all scale factors
        stimFactors = getpref('amplifiers', 'stimFactors');
		if isfield(inData, 'channelType')
            adScaleFactors = {};
            for i = 1:numel(inData.channelType)
                tempData = get(handles.channelType(i), 'userData');
                if ~isa(tempData{get(handles.channelType(i), 'value')}, 'function_handle')
                    adScaleFactors{i, 1} =  tempData{get(handles.channelType(i), 'value')};
                    tempData = get(handles.channelRange(i), 'userData');
                    adScaleFactors{i, 1} = adScaleFactors{i, 1} * tempData(get(handles.channelRange(i), 'value'));
                    tempData = get(handles.channelExtGain(i), 'userData');
                    adScaleFactors{i, 1} = adScaleFactors{i, 1} * tempData(get(handles.channelExtGain(i), 'value'));        
                else
                    % change the gain telegraph function to represent the
                    % extGain and adRange and add a second value pointing
                    % to the gain channel if it is enabled
                    inString = func2str(tempData{get(handles.channelType(i), 'value')});
                    [tempNumber numStart numEnd] = regexp(inString, '(?<=\()\d+(?=\,)', 'match', 'start', 'end');
                    adScaleFactors{i, 1} = str2double(tempNumber);
                    tempData = get(handles.channelRange(i), 'userData');
                    adScaleFactors{i, 1} = adScaleFactors{i, 1} * tempData(get(handles.channelRange(i), 'value'));
                    tempData = get(handles.channelExtGain(i), 'userData');
                    adScaleFactors{i, 1} = adScaleFactors{i, 1} * tempData(get(handles.channelExtGain(i), 'value'));     
                    
					if isfield(inData, 'ampCurrent')
						if sum(cell2mat(inData.ampCurrent) == i)
							whichTelegraph = inData.ampTelegraph{cell2mat(inData.ampCurrent) == i};
							if whichTelegraph < 9
								adScaleFactors{i, 1} = eval([inString(1:numStart - 1) num2str(adScaleFactors{i, 1}) inString(numEnd + 1:end)]);
								adScaleFactors{i, 2} = whichTelegraph;
							end
						end
					end
                end
            end
        else
            adScaleFactors = [];
		end
        
    % save the data to app data
        if isfield(inData, 'ampType')
            setappdata(0, 'daScaleFactors', stimFactors(cell2mat(inData.ampType))); % index by amp number
        end
        setappdata(0, 'adScaleFactors', adScaleFactors); % index by channel number
        setappdata(0, 'currentProtocol', inData);
        
    % request an update of the SIU
        updateSIU(inData);
        
    return
end

% if the current protocol is to be used then load it
if ischar(inData) && strcmp(inData, '-currentProtocol')
    if isappdata(0, 'currentProtocol')
        inData = getappdata(0, 'currentProtocol');
    else
        error('No protocol currently loaded')
    end
end

% offer a gui for the filename if none was given
if nargin < 2
    % if there exists an experiment gui then use the directory specified there
        if isappdata(0, 'experiment')
            handles = guihandles(getappdata(0, 'experiment'));
            cd(get(handles.mnuSaveProtocol, 'userData'));
        end    
    
    % ask where
        [file path] = uiputfile({'*.mat', 'Protocol Files'; '*.*', 'All Files'},'Please select a protocol');
        if ischar(file)
            if isappdata(0, 'experiment')
                set(handles.mnuSaveProtocol, 'userData', path);
            end
            fileName = [path file];
		else
			return
        end    
end

% save the file as requested
	protocol = inData;
    save(fileName, 'protocol');