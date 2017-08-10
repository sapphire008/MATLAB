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

    for i = 1:length(fileData)
        if fileData(i).isdir && ~strcmpi(fileData(i).name, 'System Volume Information') && fileData(i).name(1) ~= '.'
            treeModel.insertNodeInto(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(fileData(i).name, java.lang.Integer(10), [nodePath fileData(i).name filesep], '0')), node, node.getChildCount());                        
        end
    end