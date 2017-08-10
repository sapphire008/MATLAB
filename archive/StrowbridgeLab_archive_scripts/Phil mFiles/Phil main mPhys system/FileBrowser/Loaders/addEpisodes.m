function numEpisodes = addEpisodes(nodeInfo, isParsed)
    if ~ismember(double(nodeInfo.getIcon), [1:7 13:17])
        return
    end
    match = char(nodeInfo.getPath);
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    
    path = match(1:find(match == filesep, 1, 'last'));
    if numel(path) >= 7 && strcmp(path(1:7), 'Desktop')
        if ispc
            path = fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), path);
        else
            path = fullfile(getenv('HOME'), path);
        end
    end
    
    if nargin < 2 && isappdata(getappdata(0, 'fileBrowser'), 'episodeInfo') && ~isempty(strfind(match, getappdata(getappdata(0, 'fileBrowser'), 'episodeDirectory')))
        episodeData = getappdata(getappdata(0, 'fileBrowser'), 'episodeInfo');
        if isappdata(getappdata(0, 'fileBrowser'), 'filterEpisodes');
            filterEpisodes = getappdata(getappdata(0, 'fileBrowser'), 'filterEpisodes');
            filterSet = getappdata(getappdata(0, 'fileBrowser'), 'filterSet');
        else
            filterEpisodes = [];
        end
        epiIndices = find(strcmp({episodeData.key}, match));
        if isempty(epiIndices)
            % directory may have been reparsed to add in data
            numEpisodes = addEpisodes(nodeInfo, 1);
            return
        end
        whichEpisodes = episodeData(epiIndices).episodes;
        if isempty(whichEpisodes)
            whichEpisodes = {};        
            chosenEpisodes = [];
            for seqIndex = episodeData(epiIndices(1)).loadWith;
                whichEpisodes = [whichEpisodes episodeData(seqIndex).episodes];
                chosenEpisodes(end + 1:numel(whichEpisodes)) = 0;
                if ~isempty(filterEpisodes) && filterSet(seqIndex)
                    chosenEpisodes(filterEpisodes{filterSet(seqIndex)} + (end - numel(episodeData(seqIndex).episodes))) = 1;
                end
            end
        else
            chosenEpisodes = zeros(size(whichEpisodes));
            if ~isempty(filterEpisodes) && filterSet(epiIndices)
                chosenEpisodes(filterEpisodes{filterSet(epiIndices)}) = 1;
            end
        end
        whichDirectory = regexp(episodeData(find(strcmp({episodeData.key}, match), 1, 'first')).key, ['^.+' filesep], 'match');
        whichDirectory = whichDirectory{1};
        imagesOnly = episodeData(find(strcmp({episodeData.key}, match), 1, 'first')).image > 13;
        if imagesOnly
            imgHeaders = getappdata(getappdata(0, 'fileBrowser'), 'imageHeaders');
            fileNames = {'mg'};
            fileNames(1:numel(whichEpisodes)) = fileNames;
        else
            headers = getappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders');
            fileNames = {'at'};
            fileNames(1:numel(whichEpisodes)) = fileNames;
            headerFields = fields(rmfield(whichEpisodes{1}, {'fileName', 'headerIndex'}));
        end
        isParsed = true;
    else
        isParsed = false;
        fileNames = dir(path);
        fileNames = {fileNames(~[fileNames.isdir]).name};

        imagesOnly = false;
        match = match(find(match == filesep, 1, 'last') + 1:end);	
        % determine which episodes are appropriate
        if strcmp(match(end - 3:end), '.img')
            imagesOnly = true;
            % find all images for a cell
            fileNames = fileNames(~cellfun('isempty', strfind(fileNames, match(1:end - 4))) & ~cellfun('isempty', strfind(fileNames, '.img')));
        elseif strcmp(match(end - 3:end), '.pic')
            imagesOnly = true;
            % find all PIC files for a cell
            fileNames = fileNames(~cellfun('isempty', strfind(fileNames, match(1:end - 4))) & ~cellfun('isempty', strfind(fileNames, '.pic')));
        elseif ~any(match == '.')
            % a whole cell is selected so bring up all episodes unless only
            % images are present
            tempFileNames = fileNames(~cellfun('isempty', strfind(fileNames, match)) & ~(cellfun('isempty', strfind(fileNames, '.mat')) & cellfun('isempty', strfind(fileNames, '.dat'))));
            if isempty(tempFileNames)
                imagesOnly = true;
                tempFileNames = fileNames(~cellfun('isempty', strfind(fileNames, match)) & ~cellfun('isempty', strfind(fileNames, '.img')));
                if isempty(tempFileNames)
                    fileNames = fileNames(~cellfun('isempty', strfind(fileNames, match)) & ~cellfun('isempty', strfind(fileNames, '.pic')));
                else
                    fileNames = tempFileNames;
                end
            else
                fileNames = tempFileNames;
            end
        else
            fileNames = fileNames(~cellfun('isempty', strfind(fileNames, [match '.'])));
            if ~sum(~cellfun('isempty', strfind(fileNames, match)) & ~(cellfun('isempty', strfind(fileNames, '.mat')) & cellfun('isempty', strfind(fileNames, '.dat'))))
                imagesOnly = true;
            end
        end
    end
    
	numEpisodes = 0;
	if ~imagesOnly
        feval(getappdata(getappdata(0, 'fileBrowser'), 'populateColumns'), handles{4}, 'epi');
        tableModel = handles{4}.getModel;
        set(handles{4},'visible','off');
        while tableModel.getRowCount
            tableModel.removeRow(0);
        end
        columnFunctions = getpref('fileBrowser', 'columnTags');
        columnIndices = getpref('fileBrowser', 'columnOrders');
        conversionFun = [];
        if ~exist('chosenEpisodes', 'var')
            chosenEpisodes = zeros(size(fileNames));
        end
        for i = 1:length(fileNames)
            if strcmp(fileNames{i}(end - 1:end), 'at')
                if isParsed
                    protocol = headers(whichEpisodes{i}.headerIndex);
                    protocol.fileName = [whichDirectory whichEpisodes{i}.fileName];
                    for fieldIndex = headerFields'
                        protocol.(fieldIndex{1}) = whichEpisodes{i}.(fieldIndex{1});
                    end
                else
                    protocol = readTrace([path fileNames{i}], 1);
                end
                if ~isempty(protocol)
                    newRow = javaArray('java.lang.Object', handles{4}.getColumnCount);
                    newRow(1) = java.lang.String(protocol.fileName);
                    newRow(2) = java.lang.Integer(chosenEpisodes(i));
                    for j = 1:handles{4}.getColumnCount - 2
                        try
                            tempText = eval(columnFunctions{columnIndices(j)});
                            if numel(conversionFun) < handles{4}.getColumnCount - 2
                                % all members of a column must be of the same data
                                % type so only determine type once
                                if ischar(tempText)
                                    conversionFun{j} = @(x) java.lang.String(x);
                                elseif isinteger(tempText)
                                    conversionFun{j} = @(x) java.lang.Integer(x);
                                elseif isfloat(tempText)
                                    conversionFun{j} = @(x) java.lang.Float(x);
                                else
                                    conversionFun{j} = @(x) java.lang.String('Unsupported');
                                end
                            end

                            newRow(j + 2) = conversionFun{j}(tempText);
                        catch
                            if numel(conversionFun) < j
                                conversionFun{j} = @(x) java.lang.String(x);
                            end
                            newRow(j + 2) = conversionFun{j}(nan);
                        end
                    end
                    tableModel.addRow(newRow);                    
                    numEpisodes = numEpisodes + 1;            
                end
            end
        end
        set(handles{4},'visible','on');
    else
        feval(getappdata(getappdata(0, 'fileBrowser'), 'populateColumns'), handles{4}, 'img');       
        tableModel = handles{4}.getModel;
        set(handles{4},'visible','off');
        while tableModel.getRowCount
            tableModel.removeRow(0);
        end
        columnFunctions = getpref('fileBrowser', 'columnTags');
        columnIndices = getpref('fileBrowser', 'columnOrders');
        conversionFun = [];
        for i = 1:length(fileNames)
            if isParsed
                info = imgHeaders(whichEpisodes{i}.headerIndex);
                info.fileName = [whichDirectory whichEpisodes{i}.fileName];
            else
                headerData = readImage([path fileNames{i}], 1);
                info = headerData.info;
            end
            if ~isempty(info)
                newRow = javaArray('java.lang.Object', handles{4}.getColumnCount);
                newRow(1) = java.lang.String(info.Filename);
                newRow(2) = java.lang.Integer(0);
                for j = 1:handles{4}.getColumnCount - 2
                    try
                        tempText = eval(columnFunctions{columnIndices(j)});
                        if numel(conversionFun) < handles{4}.getColumnCount - 1
                            % all members of a column must be of the same data
                            % type so only determine type once
                            if ischar(tempText)
                                conversionFun{j} = @(x) java.lang.String(x);
                            elseif isinteger(tempText)
                                conversionFun{j} = @(x) java.lang.Integer(x);
                            elseif isfloat(tempText)
                                conversionFun{j} = @(x) java.lang.Float(x);
                            else
                                conversionFun{j} = @(x) java.lang.String('Unsupported');
                            end
                        end

                        newRow(j + 2) = conversionFun{j}(tempText);
                    catch
                        if numel(conversionFun) < j
                            conversionFun{j} = @(x) java.lang.String(x);
                        end
                        newRow(j + 2) = conversionFun{j}(nan);
                    end
                end
                tableModel.addRow(newRow);                    
                numEpisodes = numEpisodes + 1;            
            end
        end
        set(handles{4},'visible','on');
	end