function addSeqNodes(treeModel, node)
    nodeInfo = node.getUserObject;
    nodePath = char(nodeInfo.getPath);
    if numel(nodePath) >= 7 && strcmp(nodePath(1:7), 'Desktop')
        if ispc
            fileList = dir(fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), nodePath));
        else
            fileList = dir(fullfile(getenv('HOME'), nodePath));
        end
    elseif numel(nodePath) == 2
        % otherwise 'C:' returns the children of the working directory (if
        % it is on C)
        fileList = dir([nodePath filesep]);        
    else
        fileList = dir(nodePath);
    end
    
    for i = 1:length(fileList)
        if ~fileList(i).isdir && numel(fileList(i).name) > 3 && strcmpi(fileList(i).name(end - 2:end), 'abf')
            if numel(nodePath) >= 7 && strcmp(nodePath(1:7), 'Desktop')
                if ispc
                    fileName = fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), nodePath, fileList(i).name);
                else
                    fileName = fullfile(getenv('HOME'), nodePath, fileList(i).name);
                end   
            else
                fileName = [nodePath fileList(i).name];
            end
            header = readABF(fileName, 1);
            if ismember(header.nOperationMode, [1 2 5])
                % this is an episodic file so let episodes be loaded
                % separately
                treeModel.insertNodeInto(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(fileList(i).name, java.lang.Integer(1), [nodePath fileList(i).name], '1')), node, node.getChildCount());                                
            end
        end
    end