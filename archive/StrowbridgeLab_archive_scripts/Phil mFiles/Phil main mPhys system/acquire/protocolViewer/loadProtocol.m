function loadProtocol(inData, browserName)

%   loads a protocol into the viewer
%   loadProtocol('-currentProtocol')
%   loadProtocol(dataStructure)
%   loadProtocol(fileName)
%   loadProtocol  generates a guigetfile

% if no protocol is passed then allow to look for one
	if nargin < 1
        % if an experiment gui is present then use the last directory opened
        if isappdata(0, 'experiment')
            handles = guihandles(getappdata(0, 'experiment'));
            cd(get(handles.mnuLoadProtocol, 'userData'));
        end
        [file path] = uigetfile({'*.mat', 'Protocol Files'; '*.*', 'All Files'},'Please select a protocol');
        
        % make sure the user didn't cancel
		if ischar(file)
            if isappdata(0, 'experiment')
                % save this directory for next call to this function
                set(handles.mnuLoadProtocol, 'userData', path);
            end
            inData = [path file];
        else
            return
		end
		pause(.1) % apparently there is a conflict between uigetfile and load, so without this pause the load command takes ~30 sec		
	end

% get handles to the current figure
    if nargin < 2
        if isappdata(0, 'fileBrowser') && getappdata(0, 'fileBrowser') == get(0, 'currentFigure') && ~isempty(gcbo)
            browserName = 'protocolViewer';
        else
            browserName = 'runningProtocol';
        end
    end
    
	if ~isappdata(0, browserName)
        protocolViewer(browserName);
    elseif strcmp(browserName, 'runningProtocol')
        figure(getappdata(0, browserName));
	end
    
	figHandle = getappdata(0, browserName);
    handles = get(figHandle, 'userData');

% if a mat file name was passed then open it
    if ischar(inData)
        if strcmp(inData, '-currentProtocol')
            if isappdata(0, 'currentProtocol')
                inData = getappdata(0, 'currentProtocol');
            else
                loadProtocol;
            end
        else
            try
                protocol = readTrace(inData, 1); % this file needs to contain a structure named 'inData' that is the protocol
				inData = makeProtocol(protocol);
            catch
                error('Invalid file location')
            end
        end
    end

% make sure we have the right number of amps and channels

	experimentClock = timerfind('name', 'experimentClock');
    if ~isempty(experimentClock)
		stop(experimentClock);
    end
	% setup the ttl panel
    if numel(handles.ttlType) ~= numel(inData.ttlType)
        delete(get(get(get(handles.ttlType(1), 'parent'), 'parent'), 'children'));
        createTTL(figHandle, numel(inData.ttlType) - 1);
    end
    
    % setup the channels pane
        set(handles.source, 'value', inData.source{1});
        changeAdBoard(figHandle);
    
    if isfield(handles, 'pnlAmp')
		% remove any extra amps
        if isfield(inData, 'ampType')
            startPoint = numel(inData.ampType) + 1;
        else
            startPoint = 1;
        end
        for i  = startPoint:numel(handles.removeButtons)
            removeAmp(handles.removeButtons(i));
        end
    end
    
    if isfield(inData, 'ampType')
		% add any necessary amps
		if isfield(handles, 'removeButtons')
			startValue = numel(handles.removeButtons);
		else
			startValue = 0;
		end
        for i = startValue + 1:numel(inData.ampType)
            addAmp(figHandle);
        end
    end

    fields = fieldnames(inData);
    handles = guihandles(figHandle);    

% load the fields of the viewer    
	for fieldIndex = 1:numel(fields)
        try
            if ~strcmp('Name', fields{fieldIndex}(end - 3:end)) && ~ismember(fields{fieldIndex}, {'fileName', 'channelNames', 'startingValues', 'imageScan'})
                switch get(handles.(fields{fieldIndex})(1), 'style')
                    case 'edit'
                        if ismember(fields{fieldIndex}, {'sweepWindow', 'timePerPoint', 'imageDuration'})
                            set(handles.(fields{fieldIndex}), 'string', num2str(inData.(fields{fieldIndex})));
                        elseif ismember(fields{fieldIndex}, {'ampTpSetPoint', 'ampTpMaxCurrent', 'ampTpMaxPer', 'ampSealTestStep', 'ampBridgeBalanceStep'})
                            for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
                                set(handles.(fields{fieldIndex})(instanceIndex), 'string', num2str(inData.(fields{fieldIndex}){instanceIndex}));
                            end             
                        else
                            for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
                                set(handles.(fields{fieldIndex})(instanceIndex), 'string', inData.(fields{fieldIndex}){instanceIndex});
                            end
                        end
                    case 'checkbox'
                        for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
                            set(handles.(fields{fieldIndex})(instanceIndex), 'value', inData.(fields{fieldIndex}){instanceIndex});
                        end
                    case 'popupmenu'
                        if ~ismember(fields{fieldIndex}, {'ampType', 'ampCellLocation', 'ttlType', 'source'})
                            for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
                                set(handles.(fields{fieldIndex})(instanceIndex), 'value', inData.(fields{fieldIndex}){instanceIndex});
                            end
                        elseif ismember(fields{fieldIndex}, {'ampTypeName', 'ampCellLocationName', 'ttlTypeName', 'sourceName'})
                            %skip
                        else				
                            stringData = get(handles.(fields{fieldIndex})(1), 'string');
                            for instanceIndex = 1:numel(inData.(fields{fieldIndex}))
                                whichInstance = find(strcmp(stringData, inData.([fields{fieldIndex} 'Name']){instanceIndex}));
%                                 if iscell(whichInstance)
%                                     whichInstance = find(~cellfun('isempty', whichInstance));
%                                 end
                                if isempty(whichInstance)
                                    if strcmp(fields{fieldIndex}, 'ttlType')
                                        changeTtlType(instanceIndex, inData.([fields{fieldIndex} 'Name']){instanceIndex}, figHandle);
                                        stringData = get(handles.(fields{fieldIndex})(1), 'string');
                                    elseif strcmp(fields{fieldIndex}, 'ampCellLocation')
                                        changeCell(instanceIndex, inData.([fields{fieldIndex} 'Name']){instanceIndex}, figHandle);							
                                        stringData = get(handles.(fields{fieldIndex})(1), 'string');
                                    else
                                        if strcmp(fields{fieldIndex}, 'source')
%                                             error(['No information for sources of type ''' inData.sourceName{instanceIndex} ''' in the present configuration.  This is bad.'])
                                        else
                                            error(['No information for amps of type ''' inData.ampTypeName{instanceIndex} ''' in the present configuration.  Please update the currentAmps.m.'])
                                        end
                                    end
                                else
                                    set(handles.(fields{fieldIndex})(instanceIndex), 'value', whichInstance);
                                end							
                            end
                        end                
                end
            else
                if strcmp(fields{fieldIndex}, 'imageScan')
                    if isfield(handles, 'runningProtocol')
                        set(handles.(fields{fieldIndex}), 'selectedObject', findobj(handles.runningProtocol, 'tag', inData.(fields{fieldIndex})));                        
                    else
                        set(handles.(fields{fieldIndex}), 'selectedObject', findobj(handles.protocolViewer, 'tag', inData.(fields{fieldIndex})));                        
                    end
                end    
            end
        catch
            % if user tried to load a file as a protocol there are extra
            % fields that will fall to here
        end
	end
    
    % save the information as root appdata
    saveProtocol;
	
	% load the channel menus
	if isfield(inData, 'ampType')
        for i = 1:numel(inData.ampType)
            changeVoltage(i, figHandle);
			changeCurrent(i, figHandle);
			changeTelegraph(i, figHandle);
        end
        adBoard = getappdata(0, 'adBoard');
        if isstruct(adBoard)
            for i = 1:numel(inData.channelType)
                if ~isempty(inData.channelType{i}) && inData.channelType{i} <= adBoard.numRead
                    set(handles.channelType(i), 'value', inData.channelType{i});
                end
            end
        end
	end
    
    % update the experiment panel if applicable
	if isappdata(0, 'experiment')
        updateExperiment;
	end    
	
    if ~isempty(experimentClock) && ~isempty(get(experimentClock, 'TimerFcn'))
		start(experimentClock);
    end
	saveProtocol;

	% if it is a static one then lock it
	if ~strcmp(browserName, 'runningProtocol')
		set(findobj(figHandle, '-property', 'enable', 'type', 'uimenu'), 'enable', 'off');
		set(findobj(figHandle, '-property', 'enable', 'type', 'uicontrol'), 'enable', 'inactive');		
		tabData = getappdata(figHandle, 'tabData');
		set(tabData.tabButtons, 'enable', 'on');
		tabData = getappdata(handles.pnlAmps, 'tabData');
		set(tabData.tabButtons, 'enable', 'on');
	end	