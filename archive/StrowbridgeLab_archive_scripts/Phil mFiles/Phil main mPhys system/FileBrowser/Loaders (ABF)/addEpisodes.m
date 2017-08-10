function numEpisodes = addEpisodes(nodeInfo)
    path = char(nodeInfo.getPath);
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    
    if numel(path) >= 7 && strcmp(path(1:7), 'Desktop')
        if ispc
            path = fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), path);
        else
            path = fullfile(getenv('HOME'), path);
        end
    end
    
	numEpisodes = 0;

    fileNames = dir(path);
    fileNames = {fileNames(cellfun(@(x) numel(x) > 2 && strcmpi(x(end - 2:end), 'abf'), {fileNames.name}) & ~[fileNames.isdir]).name};    
    if exist(path, 'file') == 2
        path = path(1:find(path == filesep, 1, 'last'));
    end
    
    feval(getappdata(getappdata(0, 'fileBrowser'), 'populateColumns'), handles{4}, 'abf');
    tableModel = handles{4}.getModel;
    set(handles{4},'visible','off');
    while tableModel.getRowCount
        tableModel.removeRow(0);
    end
    columnFunctions = getpref('fileBrowser', 'columnTags');
    columnIndices = getpref('fileBrowser', 'columnOrders');

    i = 1;
    handles{4}.setName('Separate');
    isEpisodic = false;
    conversionFun = [];
    while i <= length(fileNames)
        header = readABF([path fileNames{i}], 1);
        if length(fileNames) == 1 && ismember(header.nOperationMode, [1 2 5])
            header = readABF([path fileNames{i}], 1);
            for k = 2:header.numEpisodes
                fileNames{k} = fileNames{1};
            end
            handles{4}.setName('Episodic');  
            isEpisodic = true;
            continue
        end
        if ~isempty(header)
            newRow = javaArray('java.lang.Object', handles{4}.getColumnCount);
            if ~isEpisodic
                newRow(1) = java.lang.String([path fileNames{i}]);
            else
                newRow(1) = java.lang.String([path fileNames{i} '.E' sprintf('%0.0f', i)]);            
            end
            newRow(2) = java.lang.Integer(0); % this is just here for highlighting rows (vestigial)
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
        i = i + 1;
    end
    set(handles{4},'visible','on');