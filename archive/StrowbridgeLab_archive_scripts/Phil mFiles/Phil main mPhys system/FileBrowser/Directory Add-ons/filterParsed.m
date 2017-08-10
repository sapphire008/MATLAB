function outText = filterParsed(varargin)
% to do
% get fileName, channelNames, startingValues onto the form for searching
% handle 'drugTime', 'cellTime', 'ampStep1Amplitude', 'episodeTime'
% filtering
if ~nargin
    outText = 'Filter Parsed...';
    return
end

% generate a figure if not present
if ~isappdata(0, 'filterSelector')
    % generate a choosing graphic
    figHandle = onScreen(protocolViewer('filterSelector'));
    loadProtocol('defaultProtocol', 'filterSelector');
    set(findobj(figHandle, 'style', 'check'), 'value', 0, 'enable', 'on', 'callback', @changeCheck);
    set(findobj(figHandle, 'style', 'popup', '-or', 'style', 'edit'), 'style', 'check', 'value', 0, 'string', '', 'backgroundcolor', get(0, 'defaultUicontrolBackgroundColor'), 'enable', 'on', 'callback', @changeCheck)
    for i = {'ampCellLocation', 'ttlType', 'ampType'}
        set(findobj(figHandle, 'tag', i{1}), 'tag', [i{1} 'Name']);
    end
    
    % add in experiment properties
    handles = guihandles(hgload('experiment.fig'));
    expHandles = copyobj(handles.experimentPanel, findobj(figHandle, 'tag', 'pnlImaging'));
    set(expHandles, 'position', get(expHandles, 'position') + [50 0 0 0]);
    delete(findobj(expHandles, 'tag', 'repeatInterval', '-or', 'tag', 'repeatNumber', '-or', 'tag', 'cellName'));
    set(findobj(expHandles, 'style', 'popup', '-or', 'style', 'edit'), 'style', 'check', 'value', 0, 'string', '', 'backgroundcolor', get(0, 'defaultUicontrolBackgroundColor'), 'enable', 'on', 'callback', @changeCheck);
    expTimes = copyobj([handles.drugTime handles.episodeTime handles.cellTime handles.lblDrugTime handles.lblEpisodeTime handles.lblCellTime], findobj(figHandle, 'tag', 'pnlImaging'));
    for i = expTimes'
        set(i, 'position', get(i, 'position') + [50 0 0 0]);
    end
    set(expTimes(1:3), 'style', 'check', 'value', 0, 'string', '', 'backgroundcolor', get(0, 'defaultUicontrolBackgroundColor'), 'callback', @changeCheck);
    delete(handles.experiment);
    uicontrol('style', 'check', 'String', 'Filter', 'parent', figHandle, 'position', [400 396 130 20], 'fontSize', 16, 'value', 1, 'callback', @filterParsed);
    uicontrol('style', 'pushbutton', 'String', 'Refilter', 'parent', figHandle, 'position', [500 396 130 20], 'fontSize', 16, 'value', 1, 'callback', @filterParsed);

    set(figHandle, 'closeRequestFcn', @closeMe);
    setappdata(0, 'filterSelector', figHandle);
    setappdata(figHandle, 'filterString', []);
end

searchText = getappdata(getappdata(0, 'filterSelector'), 'filterString');
if ~isempty(searchText)
    if get(findobj(getappdata(0, 'filterSelector'), 'String', 'Filter'), 'value')
    % run the filter command
        newText = '';
        for i = 1:numel(searchText)
            newText = [newText '#' searchText(i).text '# & '];
        end
        newText = newText(1:end - 2);
        newText = inputdlg('Prepare filter', 'Please edit &| as necessary', 1, {newText}, 'on');
        if isempty(newText)
            return
        end
        [acceptableHeaders acceptableHeaders acceptableHeaders] = searchExperiments('-appdata', newText{1});

        % run through headers and percolate up info about keeping
        episodeInfo = getappdata(getappdata(0, 'fileBrowser'), 'episodeInfo');
        filterSet = zeros(size(episodeInfo));
        whichEpi = {};
        for i = 1:length(filterSet)
            for j = 1:numel(episodeInfo(i).episodes)
                if any(acceptableHeaders == episodeInfo(i).episodes{j}.headerIndex)              
                    % add in episode info for highlighting
                    whichEpi{end + 1} = j;
                    for k = j + 1:numel(episodeInfo(i).episodes)
                        if any(acceptableHeaders == episodeInfo(i).episodes{k}.headerIndex)  
                            whichEpi{end}(end + 1) = k;
                        end
                    end
                    % filter upward
                    filterSet(i) = numel(whichEpi);
                    whichNode = i;
                    while ~isnan(episodeInfo(whichNode).parentNode) && ~filterSet(episodeInfo(whichNode).parentNode)
                        filterSet(episodeInfo(whichNode).parentNode) = 1;
                        whichNode = episodeInfo(whichNode).parentNode;
                    end
                    break
                end
            end
        end
        filterSet(1) = 0; % otherwise tries to redraw the already drawn root
        setappdata(getappdata(0, 'fileBrowser'), 'filterSet', filterSet);
        setappdata(getappdata(0, 'fileBrowser'), 'filterEpisodes', whichEpi);
    else
        if isappdata(getappdata(0, 'fileBrowser'), 'filterSet')
            rmappdata(getappdata(0, 'fileBrowser'), 'filterSet');
        end
        if isappdata(getappdata(0, 'fileBrowser'), 'filterEpisodes')        
            rmappdata(getappdata(0, 'fileBrowser'), 'filterEpisodes');  
        end
    end
    
    % regenerate nodes
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    parsedNode = getappdata(getappdata(0, 'fileBrowser'), 'parsedNode');     
    parsedNode.removeAllChildren;
    if ~addSubDirs(handles{1}.getModel, parsedNode)
        addSeqNodes(handles{1}.getModel, parsedNode);
    end    
    handles{1}.getModel.reload(parsedNode);
end

function changeCheck(varargin)
    % just remove info and leave if unchecking
    searchText = getappdata(getappdata(0, 'filterSelector'), 'filterString');    
    if ~get(varargin{1}, 'value')
        searchText = searchText(~strcmp({searchText.field}, get(varargin{1}, 'tag')));
        setappdata(getappdata(0, 'filterSelector'), 'filterString', searchText);
        set(varargin{1}, 'toolTipString', '');
        return
    end

    % change the value of a check box
    headers = getappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders');
    
    % determine what the data format is
    try
        dataVals = vertcat(headers.(get(varargin{1}, 'tag')));
    catch
        % slow way since matlab doesn't cat cells well
        dataVals = {};
        tagData = get(varargin{1}, 'tag');
        for i = 1:numel(headers)
            if size(headers(i).(tagData), 1) == 1
                dataVals = [dataVals headers(i).(tagData)];
            else
                dataVals = [dataVals headers(i).(tagData)'];
            end
        end
    end
    if iscell(dataVals) && ~ischar(dataVals{1})
        dataVals = cellfun(@(x) x, dataVals);
    end    
    novels = unique(dataVals);
    if isnumeric(novels(1))
        if numel(novels) == 2 && all(ismember(novels, [0 1]))
            % this is a value with only a binary choice
            outputVal = questdlg('Allow:', get(varargin{1}, 'tag'), 'Enabled', 'Disabled', 'Enabled');
            if isempty(outputVal)
                set(varargin{1}, 'value', 0);
            else
                searchText(end + 1).field = get(varargin{1}, 'tag');
                searchText(end).text = get(varargin{1}, 'tag');
                if strcmp(outputVal, 'Disabled')
                    searchText(end).text = ['~' searchText(end).text];
                end
            end
        else
            outputVal = inputdlg(['Enter a relational equation with ' get(varargin{1}, 'tag') ' such as: ' get(varargin{1}, 'tag') ' > 30.  Values range from ' num2str(novels(1)) ' to ' num2str(novels(end)) '.'], get(varargin{1}, 'tag'));
            if isempty(outputVal)
                set(varargin{1}, 'value', 0);
            else
                searchText(end + 1).field = get(varargin{1}, 'tag');                
                searchText(end).text = outputVal{1};
            end            
        end
    else
        % a bunch of strings
        outputVal = questdlg('Filter by:', get(varargin{1}, 'tag'), 'Selecting', 'Finding', 'Selecting');        
        if isempty(outputVal)
            set(varargin{1}, 'value', 0);
        elseif strcmp(outputVal, 'Selecting')
            [outputVal ok] = listdlg('ListString', novels, 'ListSize', [400 600], 'PromptString', 'Select acceptable values');
            if ~ok
                set(varargin{1}, 'value', 0);
            else
                searchText(end + 1).field = get(varargin{1}, 'tag');
                searchText(end).text = ['ismember(' get(varargin{1}, 'tag') ', {'];
                for i = outputVal
                    searchText(end).text = [searchText(end).text novels{i} ', '];
                end
                searchText(end).text = [searchText(end).text(1:end - 2) '});'];
            end
        else
            outputVal = inputdlg('Enter string to find', get(varargin{1}, 'tag'));
            if isempty(outputVal)
                set(varargin{1}, 'value', 0);
            else
                searchText(end + 1).field = get(varargin{1}, 'tag');                
                searchText(end).text = ['~isempty(strfind(' get(varargin{1}, 'tag') ', ' outputVal '))'];
            end
        end
    end
    if get(varargin{1}, 'value') == 1
        set(varargin{1}, 'toolTipString', searchText(end).text);
    end
    setappdata(getappdata(0, 'filterSelector'), 'filterString', searchText);

function closeMe(varargin)
    % regenerate the unfiltered nodes
    if get(findobj(getappdata(0, 'filterSelector'), 'String', 'Filter'), 'value')
        setappdata(getappdata(0, 'filterSelector'), 'filterString', '');
        filterParsed(1);
    end
    if isappdata(0, 'fileBrowser') && isappdata(getappdata(0, 'fileBrowser'), 'filterSet')
        rmappdata(getappdata(0, 'fileBrowser'), 'filterSet');
        rmappdata(getappdata(0, 'fileBrowser'), 'filterEpisodes');
    end
    rmappdata(0, 'filterSelector');
    delete(varargin{1});