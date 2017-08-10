function addNewEpisode(rootNode, startingDir)
handles = get(getappdata(0, 'fileBrowser'), 'userData');
treeHandle = handles{1};
treeModel = treeHandle.getModel;
listHandle = handles{4};
rootPath = char(rootNode.getUserObject.getPath);
rootPath = rootPath(1:end - 1);
startingDir = [filesep startingDir];

try    
    % if no slash on the end then add one
    openEpisodes = 0;
    dirs = find(startingDir == filesep);
    if startingDir(end) ~= filesep
        [cellNameStart cellNameStop] = regexp(startingDir, '\.\d\d(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\d\d', 'ONCE');
        if ~isempty(cellNameStart)
            dirs(end + 1) = cellNameStart - 1;
            if cellNameStop == length(startingDir)
                % this is only cell-specific

            else
                openEpisodes = 1;
                if any(startingDir(cellNameStop:end) == 'E')
                    %this is episode specific
                    dirs(end + 1) = find(startingDir == 'E', 1, 'last') - 2;
                else
                    % this is only sequence-specific so do it like
                    % a cell-specific
                    dirs(end + 1) = length(startingDir);              
                end                        
            end
        elseif exist(startingDir, 'dir') == 7
            % is directory specific without a slash
            startingDir = [startingDir filesep];
            dirs(end + 1) = length(startingDir);
        else
            % is cell specific without the date
            dirs(end + 1) = length(startingDir);
        end
    end

    node = rootNode;
    bestNode = node;
    alreadyReset = 0;
    i = 2;
    currentTreeNode = treeHandle.getLastSelectedPathComponent;
    while i < length(dirs) + 1
        % expand the current node
        treeHandle.scrollPathToVisible(javax.swing.tree.TreePath(node.getPath));

        % determine which node matches our directory
        numKids = node.getChildCount();
        parentNode = node;
        if numKids > 0
            node = node.getFirstChild();
            for j = 1:numKids
                nodeInfo = node.getUserObject;                        
                if strcmpi(nodeInfo.getPath, [rootPath startingDir(1:dirs(i))])
                    bestNode = node;
                end
                if strcmp(char(nodeInfo.getParsed), '0')
                    try
                        if ~addSubDirs(treeModel, node)
                            addSeqNodes(treeModel, node);
                        end
                    catch
                        %some folders miss a parsed tag and end up here
                    end
                    nodeInfo.setParsed('1');
                end
                if j < numKids
                    node = node.getNextSibling;      
                end                        
            end
            node = bestNode;
        end

        nodeInfo = node.getUserObject;                                            
        if ~strcmpi(nodeInfo.getPath, [rootPath startingDir(1:dirs(i))])
            if alreadyReset
                error('Already reset');
            else
                % node not found so make sure is a directory
                if ~isempty(dir([rootPath startingDir(1:dirs(i))]))
                    % add a dir
                    node = javax.swing.tree.DefaultMutableTreeNode(NodeInfo(startingDir(dirs(i-1) + 1:dirs(i) - 1), java.lang.Integer(10), [rootPath startingDir(1:dirs(i))], '0'));
                    treeModel.insertNodeInto(node, parentNode, parentNode.getChildCount());
                    % and parse it
                    if ~addSubDirs(treeModel, node)
                        addSeqNodes(treeModel, node);
                    end
                    nodeInfo = node.getUserObject;                        
                    nodeInfo.setParsed('1');
                else
                    % is this a new cell or sequence?
                    if i > 1 && ~isempty(dir([rootPath startingDir(1:dirs(i - 1))]))
                        % this is a new cell
                        % remove old dir
                        parentNode.removeAllChildren;
                        % and parse it
                        nodeInfo.setParsed('0');
                        if ~addSubDirs(treeModel, node)
                            addSeqNodes(treeModel, node);
                        end
                        nodeInfo = node.getUserObject;                        
                        nodeInfo.setParsed('1');
                        i = i - 1;
                        treeModel.reload(parentNode);
                    elseif i > 2 && ~isempty(dir([rootPath startingDir(1:dirs(i - 2))]))
                        % this is a new sequence
                        % remove old dir
                        parentNode = node.getParent;
                        parentNode.removeAllChildren;
                        % and parse it
                        nodeInfo = parentNode.getUserObject;
                        nodeInfo.setParsed('0');
                        if ~addSubDirs(treeModel, parentNode)
                            addSeqNodes(treeModel, parentNode);
                        end
                        nodeInfo = parentNode.getUserObject;                        
                        nodeInfo.setParsed('1');
                        i = i - 2;
                        node = parentNode;
                        treeModel.reload(parentNode);
                    else
                        error('Input to fileBrowser must be a valid file name')
                    end
                end
                alreadyReset = 1;
            end  
        end
        i = i + 1;
    end
    treeHandle.scrollPathToVisible(javax.swing.tree.TreePath(node.getPath));
    treeHandle.expandPath(javax.swing.tree.TreePath(node.getPath));

    % we are at the bottom of the tree so if a sequence is selected
    % show it
    if openEpisodes
        if any(strfind(rootPath, 'Desktop') == 1)
            if ispc
                rootPath = [fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), 'Desktop', filesep) rootPath(9:end)];
            else
                rootPath = [fullfile(getenv('HOME'), 'Desktop', filesep) rootPath(9:end)];
            end
        end
        treeHandle.setSelectionPath(javax.swing.tree.TreePath(node.getPath));
        nodeText = char(nodeInfo.getName);
        notCurrentNode = true;
        if ~isempty(currentTreeNode)
            tempInfo = currentTreeNode.getUserObject;
            if strcmpi(tempInfo.getPath, nodeInfo.getPath)
                notCurrentNode = false;
            end
        end
        if notCurrentNode
            nodeInfo.setName([nodeText(1:find(nodeText == '(', 1, 'first')) strtrim(num2str(addEpisodes(nodeInfo))) ')']);
        end

        if numel(startingDir) > 7 && strcmp(startingDir(1:8), ['Desktop' filesep])
            startingDir = [desktopPath startingDir(9:end)];
        end

        foundMatch = false;
        listModel = listHandle.getModel;
        for i = 1:listHandle.getRowCount
            tempData = listModel.getValueAt(i - 1, 0);
            if strcmpi(tempData, [rootPath startingDir])
                % this episode is already on the list so select it                            
                foundMatch = true;
                listHandle.setRowSelectionInterval(i - 1, i - 1);
                break
            end
        end

        if ~foundMatch
            % this is so that the episodes aren't all reparsed when
            % a new one is added
            parenStart = find(nodeText == '(', 1, 'first');
            nodeInfo.setName([nodeText(1:parenStart) strtrim(num2str(str2double(nodeText(parenStart + 1:end - 1)) + 1)) ')']);                    
            protocol = readTrace([rootPath startingDir], 1);
            if ~isempty(protocol)
                newRow = javaArray('java.lang.Object', listHandle.getColumnCount);
                newRow(1) = java.lang.String(protocol.fileName);
                newRow(2) = java.lang.Integer(0);
                columnFunctions = getpref('fileBrowser', 'columnTags');
                columnIndices = getpref('fileBrowser', 'columnOrders');
                for j = 1:listHandle.getColumnCount - 2
                    try
                        tempText = eval(columnFunctions{columnIndices(j)});
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

                        newRow(j + 2) = conversionFun{j}(tempText);
                    catch
                        if numel(conversionFun) < j
                            conversionFun{j} = @(x) java.lang.String(x);
                        end
                        newRow(j + 2) = conversionFun{j}(nan);
                    end
                end
                listHandle.getModel.addRow(newRow);                    
            end
            if isappdata(0, 'experiment')
                experimentInfo = getappdata(0, 'currentExperiment');
                if ~isempty(experimentInfo.matlabCommand)
                    try
                        eval(experimentInfo.matlabCommand);
                    catch
                        warning('Error in post-processing command');
                    end
                end
            end
            listHandle.setRowSelectionInterval(listHandle.getRowCount - 1, listHandle.getRowCount - 1);
        end
        set(getappdata(0, 'fileBrowser'), 'name', char(nodeInfo.getPath));
        listHandle.scrollRectToVisible(listHandle.getCellRect(listHandle.getSelectedRow, 0, true));
        clickTable({[rootPath startingDir]});
    end        
catch
    error('First Arguement must be a valid directory, cell, sequence, or full path')
end