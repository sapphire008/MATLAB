function parsedSeqs = addSubDirs(treeModel, node)
    parsedSeqs = false;
    nodeInfo = node.getUserObject;
    nodePath = char(nodeInfo.getPath);
    if numel(nodePath) >= 7 && strcmp(nodePath(1:7), 'Desktop')
        if ispc
            fileData = dir(fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), nodePath, filesep));
        else
            fileData = dir(fullfile(getenv('HOME'), nodePath, filesep));
        end
    elseif numel(nodePath) == 2
        % otherwise 'C:' returns the children of the working directory (if
        % it is on C)
        fileData = dir([nodePath filesep]);
        nodePath = [nodePath filesep];
    else
        fileData = dir(nodePath);
    end
    dirCount = 0;
    whichFiles = [];
    if any(strcmp({fileData.name}, 'preParse.mat'))
        if ~isappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders')
                % load the already in use version
            if numel(nodePath) >= 7 && strcmp(nodePath(1:7), 'Desktop')
                if ispc
                    load(fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), nodePath, filesep, 'preParse.mat')); 
                else
                    load(fullfile(getenv('HOME'), nodePath, filesep, 'preParse.mat')); 
                end
            else
                if exist(fullfile(tempdir, 'preParse.mat'), 'file')
                    tempData = dir(fullfile(tempdir, 'preParse.mat'));
                    currentData = dir([nodePath filesep 'preParse.mat']);

                    if isempty(tempData) || (tempData.datenum ~= currentData.datenum) || (tempData.bytes ~= currentData.bytes)
                        copyfile([nodePath filesep 'preParse.mat'], fullfile(tempdir, 'preParse.mat'));
                    end
                else
                    copyfile([nodePath filesep 'preParse.mat'], fullfile(tempdir, 'preParse.mat'));
                end
                load(fullfile(tempdir, 'preParse.mat'));
            end
        else
            % load from memory
            parseData = getappdata(getappdata(0, 'fileBrowser'), 'episodeInfo');
            directory = getappdata(getappdata(0, 'fileBrowser'), 'episodeDirectory');
            headers = getappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders');
            imgHeaders = getappdata(getappdata(0, 'fileBrowser'), 'imageHeaders');
        end

        if exist('parseData', 'var') && isstruct(parseData) && numel(fieldnames(parseData)) == 6 && all(strcmp(fieldnames(parseData), {'parentNode'; 'text'; 'key'; 'image'; 'episodes'; 'loadWith'}))
            node.getUserObject.setIcon(java.lang.Integer(12));
            parentNode(1) = node;
            parentNode(2:numel(parseData)) = parentNode(1);
            if isappdata(getappdata(0, 'fileBrowser'), 'filterSet')
                filterSet = find(getappdata(getappdata(0, 'fileBrowser'), 'filterSet'));
            else
                filterSet = 2:numel(parseData);
            end
            for i = filterSet
                treeModel.insertNodeInto(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(parseData(i).text, java.lang.Integer(parseData(i).image), parseData(i).key, '1')), parentNode(parseData(i).parentNode), parentNode(parseData(i).parentNode).getChildCount());                                        
                parentNode(i) =  parentNode(parseData(i).parentNode).getLastChild();                    
            end   
            setappdata(getappdata(0, 'fileBrowser'), 'episodeInfo', parseData);
            setappdata(getappdata(0, 'fileBrowser'), 'episodeDirectory', directory);
            setappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders', headers);
            setappdata(getappdata(0, 'fileBrowser'), 'imageHeaders', imgHeaders);
            setappdata(getappdata(0, 'fileBrowser'), 'parsedNode', parentNode(1));
            parsedSeqs = true;
        end
    else
        for i = 1:length(fileData)
            if fileData(i).isdir && ~strcmpi(fileData(i).name, 'System Volume Information') && fileData(i).name(1) ~= '.'
                dirCount = dirCount + 1;
                tempData{dirCount} = upper(fileData(i).name);
                whichFiles(dirCount) = i;
                for j = 1:12
                    if ~isempty(strfind(tempData{dirCount}, upper(datestr([2005 j 24 12 34 56], 'mmm')))) || ~isempty(strfind(tempData{dirCount}, datestr([2005 j 24 12 34 56], 'mmm')))
                        tempData{dirCount} = [char(j) tempData{dirCount}];
                        spaces = find(tempData{dirCount} == ' ');
                        if length(spaces) > 1 && spaces(2) - spaces(1) == 2
                            tempData{dirCount} = [tempData{dirCount}(1:spaces(1)) char(1) tempData{dirCount}(spaces(1) + 1:end)]; 
                        end
                    end
                end
            end
        end
        if exist('tempData', 'var')
            [junk indices] = sort(tempData);
            for i = 1:length(indices)
                treeModel.insertNodeInto(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(fileData(whichFiles(indices(i))).name, java.lang.Integer(10), [nodePath fileData(whichFiles(indices(i))).name filesep], '0')), node, node.getChildCount());                        
            end
        end
    end