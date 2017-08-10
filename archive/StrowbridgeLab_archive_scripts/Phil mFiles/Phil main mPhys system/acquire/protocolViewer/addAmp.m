function addAmp(figHandle)

% adds an amp to the currently visible protocol

    % set gui
		if nargin < 1
			figHandle = gcf;
		end
        handles = get(figHandle, 'userData');
        info = getappdata(handles.pnlAmps, 'tabData');
		if isempty(info)
			info.numAmps = 0;
		end
        info.numAmps = info.numAmps + 1;
        setappdata(handles.pnlAmps, 'tabData', info);
        props.visible = 'off';    
        tempHandle = hgload('ampPanel.fig', props);
        copyobj(get(tempHandle, 'children'), handles.pnlAmps);   
        delete(tempHandle)
        tempMenu = uicontextmenu('parent', figHandle);
        uimenu(tempMenu, 'label', 'Add', 'callback', 'addAmp');
        uimenu(tempMenu, 'label', 'Remove', 'callback', @removeAmp, 'tag', 'removeButtons')   		
        swapHandles = get(handles.pnlAmps, 'children');
        set(handles.pnlAmps, 'children', swapHandles([4:end - 2 1:3 end - 1:end]));
        handles = guihandles(figHandle);
        set(handles.tabAmpName(end), 'position', [1.2 + 17.4 * (info.numAmps - 1) 28 17.6 1.692], 'string', ['Amp ' char(info.numAmps + 64)], 'callback', @tabChange);
        set(handles.hideAmpName(end), 'position', [1.4 + 17.4 * (info.numAmps - 1) 27.769 16.8 0.692], 'backgroundColor', get(0, 'defaultUicontrolBackgroundColor'));
        set(handles.pnlAmp(end), 'uicontextmenu', tempMenu);
		
	% add cell types
		set(handles.ampCellLocation(end), 'string', [getpref('experiment', 'cellTypes') 'Other']);		
		
	% add amp types
		set(handles.ampType(end), 'string', getpref('amplifiers', 'amplifiers'));				
    
    % add any command history
        pastCommands = loadMatlabText('D:\matlabProtocolCommands.txt');
        set(handles.ampMatlabCommand(end), 'userData', {size(pastCommands, 2) + 1, pastCommands}); 
        pastCommands = loadMatlabText('D:\matlabProtocolStim.txt');
        set(handles.ampMatlabStim(end), 'userData', {size(pastCommands, 2) + 1, pastCommands}); 		
            
    % set info for the callback
        info.tabButtons = handles.tabAmpName;
        info.lineHiders = handles.hideAmpName;
        info.panels = handles.pnlAmp;
		info.removeButtons = handles.removeButtons;
        setappdata(handles.pnlAmps, 'tabData', info);
        tabChange(info.tabButtons(end));
        
    % update the experiment panel if it is present
		if isappdata(0, 'runningProtocol') && figHandle == getappdata(0, 'runningProtocol')
			set(getappdata(0, 'runningProtocol'), 'userData', guihandles(figHandle));
			saveProtocol;
		end
		set(figHandle, 'userData', guihandles(figHandle));	
		if isappdata(0, 'experiment')
			updateExperiment;
		end
		
	% add the callback for the matlab command
		set(handles.ampMatlabCommand(end), 'keyPressFcn', @commandKeyPress);	
		set(handles.ampMatlabStim(end), 'keyPressFcn', @commandKeyPress);
		
	% set the amp info in channelPanel
		changeAmp(numel(handles.pnlAmp), figHandle);
        
function commandText = loadMatlabText(fileName)
    fid = fopen(fileName);
    whichCommand = 1;
    if fid > 0
        while 1
            tline = fgetl(fid);
            if ~ischar(tline)
                break
            end
            commandText{whichCommand} = tline;
            whichCommand = whichCommand + 1;
        end
        fclose(fid);
    else
        commandText = [];
    end
    
function addText(src)
    userData = get(src, 'userData');
    commandText = userData{2};
    newCommand = cell2mat(get(src, 'string'));
	if find(strcmp(commandText, newCommand))
        commandText(find(strcmp(commandText, newCommand)):length(commandText) - 1) = commandText(find(strcmp(commandText, newCommand)) + 1:length(commandText));
        commandText{length(commandText)} = newCommand;
        set(src, 'userData', {length(commandText), commandText});
        return
	end
    
	if numel(newCommand)
		commandText{end + 1} = newCommand;
		set(src, 'userData', {length(commandText), commandText});		
	end
    
function commandKeyPress(src, eventInfo)
    userData = get(src, 'userData');
    commandText = userData{2};
    whichCommand = userData{1};

	if whichCommand <= length(commandText) + 1 && strcmp(eventInfo.Key, 'downarrow')  % down arrow
		if whichCommand < length(commandText)
			whichCommand = whichCommand + 1;
			set(src, 'string', commandText(whichCommand));
		elseif whichCommand == length(commandText)
			whichCommand = whichCommand + 1;
			set(src, 'string', '');
		end
	end

	if strcmp(eventInfo.Key, 'uparrow') && whichCommand > 1 % up arrow
		whichCommand = whichCommand - 1;
		set(src, 'string', commandText(whichCommand));
	end
    
    set(src, 'userData', {whichCommand, commandText})
    
    if strcmp(eventInfo.Key, 'return')
		pause(.1)
        addText(src)
		if strcmp(get(src, 'tag'), 'ampMatlabCommand')
			try
    			eval(cell2mat(get(src, 'string')));
            catch
                error(['Error in evaluating ' get(src, 'tag')]);
            end
		end
    end                