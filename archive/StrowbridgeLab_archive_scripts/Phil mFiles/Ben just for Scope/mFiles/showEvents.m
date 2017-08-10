function showEvents(axisHandle)
    % show the events for a given axis along the top of the axis
    events = getappdata(axisHandle, 'events');
    ylims = get(axisHandle, 'ylim');
    colorScheme = lines(numel(events));

    kids = get(axisHandle, 'children');
    delete(kids(strcmp(get(kids, 'userData'), 'events')));

    handleList = get(ancestor(axisHandle, 'figure'), 'userData');
    markerType = get(findobj(get(axisHandle, 'parent'), 'Label', 'Event Marks...'), 'userData');
    
    locMen = uicontextmenu('parent', ancestor(axisHandle, 'figure'));
        uimenu(locMen, 'Label', '', 'foregroundColor', [0 0 1]);
        uimenu(locMen, 'Label', 'Remove Event','callback', {@removeEvent, 0});
        uimenu(locMen, 'Label', 'Remove Series','callback', {@removeSeries, 0});
        uimenu(locMen, 'Label', 'Remove Channel','callback', {@removeChannel, 0});
        uimenu(locMen, 'Label', 'Remove All Channels','callback', {@removeAllChannels, 0});
        
        % load detection functions
        installDir = which('newScope');
        installDir = installDir(1:find(installDir == filesep, 1, 'last'));        

        fileNames = dir([installDir 'Event Characterization']);
        beenSeparated = 0;
        for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
            try
                funHandle = str2func(iFiles{1}(1:end - 2));
                if ~beenSeparated
                    uimenu(locMen, 'Label', funHandle(), 'callback', {funHandle 0}, 'separator', 'on');
                    beenSeparated = 1;
                else
                    uimenu(locMen, 'Label', funHandle(), 'callback', {funHandle 0});
                end
            catch
                disp(['File ' iFiles{1} ' in Event Characterization folder is not a valid event characterizer']);
            end
        end

        uimenu(locMen, 'Label', 'Export Series to Workspace', 'callback', {@exportSeries, 0}, 'Separator', 'on');
        uimenu(locMen, 'Label', 'Export Channel to Workspace', 'callback', {@exportChannel, 0});

        uimenu(locMen, 'Label', 'Save Series...', 'callback', {@saveSeries, 0});
        uimenu(locMen, 'Label', 'Save Channel...', 'callback', {@saveChannel, 0});
        uimenu(locMen, 'Label', 'Save All Channels...', 'callback', {@saveAllChannels, 0});
        
    for i = 1:numel(events)
        switch markerType
            case 1
                lineHandle = line(events(i).data, ones(size(events(i).data)) * (ylims(2) - .1 * diff(ylims) * i/numel(events)), 'uicontextmenu', locMen, 'buttonDownFcn', {@setMenu, axisHandle, i, [events(i).type ', ' events(i).traceName], 0}, 'parent', axisHandle, 'linestyle', 'none', 'marker', '+', 'color', colorScheme(i,:));
            case 2
                lineHandle = line(events(i).data, ones(size(events(i).data)) * (ylims(2) - .1 * diff(ylims) * i/numel(events)), 'uicontextmenu', locMen, 'buttonDownFcn', {@setMenu, axisHandle, i, [events(i).type ', ' events(i).traceName], 0}, 'parent', axisHandle, 'linestyle', 'none', 'marker', 'v', 'color', colorScheme(i,:));
            case 3
                lineHandle = [];
                for j = 1:numel(events(i).data)
                    lineHandle(end + 1) = line([events(i).data(j) events(i).data(j)], [(ylims(2) - .1 * diff(ylims) * i/numel(events)) (ylims(2) - .1 * diff(ylims) * (i - 1)/numel(events))], 'uicontextmenu', locMen, 'buttonDownFcn', {@setMenu, axisHandle, i, [events(i).type ', ' events(i).traceName], 1}, 'parent', axisHandle, 'color', colorScheme(i,:), 'lineWidth', 2);
                end
            case 4
                lineHandle = [];
                for j = 1:numel(events(i).data)
                    lineHandle(end + 1) = line([events(i).data(j) events(i).data(j)], ylims, 'uicontextmenu', locMen, 'buttonDownFcn', {@setMenu, axisHandle, i, [events(i).type ', ' events(i).traceName], 1}, 'parent', axisHandle, 'color', colorScheme(i,:), 'lineWidth', 1);
                end
        end
        set(lineHandle, 'userData', 'events');

        if ~isempty(events(i).data) && ~isempty(events(i).traceName)
            for j = lineHandle
                set(j, 'displayName', events(i).traceName);
            end
        end
        if strcmp(get(handleList.displayEvents, 'checked'), 'off')
            set(lineHandle, 'visible', 'off');
        end
    end

function setMenu(varargin)
    locMenu = get(varargin{1}, 'uicontextmenu');
    menuKids = get(locMenu, 'children');
    newLoc = hgconvertunits(gcf, [get(gcf, 'currentPoint') 0 0], get(gcf, 'units'), 'pixels', 0);
    
    set(menuKids(end), 'foregroundColor', get(varargin{1}, 'color'));

    switch get(gcf, 'selectionType')
        case 'alt' % show the menu
            set(menuKids(end), 'Label', varargin{5});
            for i = 1:numel(menuKids) - 1
                functionHandle = get(menuKids(i), 'callback');
                if ~isempty(strfind(func2str(functionHandle{1}), 'Setup'))
                    functionHandle{1}(menuKids(i), varargin{2}, 0, varargin{3}, varargin{4});
                elseif~isempty(functionHandle)
                    set(menuKids(i), 'callback', {functionHandle{1}, varargin{1}, varargin{3}, varargin{4}, varargin{6}});
                end
            end
            set(locMenu, 'position', newLoc(1:2));
            set(locMenu, 'visible', 'on');
        case 'open' % remove the point
            set(locMenu, 'position', newLoc(1:2));
            removeEvent(menuKids(3), 0, varargin{1}, varargin{3}, varargin{4}, varargin{6});
        case 'normal' % display the data value of the point
            handles = get(gcf, 'userData');
            events = getappdata(varargin{3}, 'events');            
            pointerLoc = hgconvertunits(gcf, newLoc, 'pixels', get(gcf, 'units'), 0);
            figureLoc = get(gcf, 'Position');    
            xCoord = round(((pointerLoc(1) - 7) / (figureLoc(3) - 55)  * diff(get(handles.axes(1),'Xlim')) + min(get(handles.axes(1),'Xlim'))) / handles.xStep) * handles.xStep;
            [junk whichPoint] = min(abs(events(varargin{4}).data - xCoord));
            set(get(gca, 'userData'), 'string', sprintf('%1.1f', events(varargin{4}).data(whichPoint)));
    end
    
function removeEvent(varargin)
    handles = get(gcf, 'userData');
    events = getappdata(varargin{4}, 'events');
    pointerLoc = hgconvertunits(gcf, [get(get(varargin{1}, 'parent'), 'position') 0 0], 'pixels', get(gcf, 'units'), 0);
    figureLoc = get(gcf, 'Position');    
    xCoord = round(((pointerLoc(1) - 7) / (figureLoc(3) - 55)  * diff(get(handles.axes(1),'Xlim')) + min(get(handles.axes(1),'Xlim'))) / handles.xStep) * handles.xStep;
    [junk whichPoint] = min(abs(events(varargin{5}).data - xCoord));
    
    if varargin{6} == 0
        % the events are all in one line so must remove one point
        xData = get(varargin{3}, 'xData');
        set(varargin{3}, 'xData', xData([1:whichPoint - 1 whichPoint + 1:end]));
        yData = get(varargin{3}, 'yData');
        set(varargin{3}, 'yData', yData([1:whichPoint - 1 whichPoint + 1:end]));
    else
        % the events are each a separate line so just delete the handle
        delete(varargin{3});
    end
    
    if numel(events(varargin{5}).data) > 1
        events(varargin{5}).data = events(varargin{5}).data([1:whichPoint - 1 whichPoint + 1:end]);
    else
        events(varargin{5})= [];
    end
    setappdata(varargin{4}, 'events', events);
    
function removeSeries(varargin)
    events = getappdata(varargin{4}, 'events');    
    setappdata(varargin{4}, 'events', events([1:varargin{5} - 1 varargin{5} + 1:end]));
    showEvents(varargin{4});

function removeChannel(varargin)
    rmappdata(varargin{4}, 'events');    
    showEvents(varargin{4});

function removeAllChannels(varargin)
    handles = get(get(varargin{4}, 'parent'), 'userData');
    for hIndex = handles.axes
        if isappdata(hIndex, 'events')
            rmappdata(hIndex, 'events');    
            showEvents(hIndex);  
        end
    end
    
function exportSeries(varargin)
    events = getappdata(varargin{4}, 'events');    

    menuKids = get(get(varargin{1}, 'parent'), 'children');
    tempVarName = get(menuKids(end),'Label');
    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, {genvarname(tempVarName(1:find(tempVarName == ',', 1, 'first') - 1))});
 
    if ~isempty(varName)
        tempVarName = genvarname(varName, evalin('base', 'who'));
        if strcmp(varName, tempVarName)
            assignin('base', varName{1},  events(varargin{5}).data);
        else
            switch questdlg(strcat('''', varName, ''' is not a valid variable name in the base workspace.  Is ''', tempVarName, ''' ok?'), 'Uh oh');
                case 'Yes'
                    assignin('base', tempVarName{1},  events(varargin{5}).data);
                case 'No'
                    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, tempVarName);
                    assignin('base', genvarname(varName{1}),  events(varargin{5}).data);
                case 'Cancel'
                    % do nothing
            end
        end        
    end
    
function exportChannel(varargin)
    events = getappdata(varargin{4}, 'events');
    maxLength = 0;
    for i = 1:numel(events)
        if maxLength < length(events(i).data)
            maxLength = length(events(i).data);
        end
    end
    outData = nan(maxLength, numel(events));
    for i = 1:numel(events)
        outData(1:numel(events(i).data), i) = events(i).data;
    end

    menuKids = get(get(varargin{1}, 'parent'), 'children');
    tempVarName = get(menuKids(end),'Label');
    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, {genvarname(tempVarName(1:find(tempVarName == ',', 1, 'first') - 1))});
 
    if ~isempty(varName)
        tempVarName = genvarname(varName, evalin('base', 'who'));
        if strcmp(varName, tempVarName)
            assignin('base', varName{1},  outData);
        else
            switch questdlg(strcat('''', varName, ''' is not a valid variable name in the base workspace.  Is ''', tempVarName, ''' ok?'), 'Uh oh');
                case 'Yes'
                    assignin('base', tempVarName{1},  outData);
                case 'No'
                    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, tempVarName);
                    assignin('base', genvarname(varName{1}),  outData);
                case 'Cancel'
                    % do nothing
            end
        end        
    end        
    
function saveSeries(varargin)
    events = getappdata(gca, 'events');
    handleList = get(gcf, 'userData');

    [fileName pathName] = uiputfile({'*.mat', 'Matlab Event Files'}, 'Select Location to Save Events', 'myEvents.mat');

    if length(fileName) > 1
        events = events(varargin{5}).data;
        stringData = get(handleList.channelControl(1).channel, 'string');    
        events.source = stringData{cell2mat((get(handleList.channelControl(handleList.axes == varargin{4}).channel, 'value'))')};
        save([pathName fileName], 'events');
    end

function saveChannel(varargin)
    events = getappdata(gca, 'events');
    handleList = get(gcf, 'userData');    

    [fileName pathName] = uiputfile({'*.mat', 'Matlab Event Files'}, 'Select Location to Save Channel', 'myEvents.mat');

    if length(fileName) > 1
        stringData = get(handleList.channelControl(1).channel, 'string');    
        for i = 1:numel(events)
            events(i).source = stringData{cell2mat((get(handleList.channelControl(handleList.axes == varargin{4}).channel, 'value'))')};
        end
        save([pathName fileName], 'events');
    end

function saveAllChannels(varargin)
    events = [];
    handleList = get(gcf, 'userData');        

    [fileName pathName] = uiputfile({'*.mat', 'Matlab Event Files'}, 'Select Location to Save All Channels', 'myEvents.mat');

    if length(fileName) > 1
        stringData = get(handleList.channelControl(1).channel, 'string');      
        for j = handleList.axes
            tempEvents = getappdata(j, 'events');
            if ~isempty(tempEvents)
                for i = 1:numel(tempEvents)
                    tempEvents(i).source = stringData{cell2mat((get(handleList.channelControl(handleList.axes == j).channel, 'value'))')};
                end
                events = [events tempEvents];
            end
        end
        save([pathName fileName], 'events');
    end
