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
    
    matList = {fileList(~cellfun('isempty', regexp({fileList.name}, '\.S\d*\.E\d*\.[dm]at'))).name};
    imgList = {fileList(~cellfun('isempty', strfind({fileList.name}, '.img'))).name}; 
    picList = {fileList(~cellfun('isempty', strfind({fileList.name}, '.pic'))).name}; 
	
	% find the unique cell names
    cellNames = cell(numel(matList) + numel(imgList) + numel(picList), 1);
	dots = nan(numel(matList) + numel(imgList) + numel(picList), 3);
	dotCount = 1;
    for i = [matList imgList picList]
        try
            dots(dotCount, :) = find(i{1} == '.', 3, 'first');
            cellNames{dotCount} = i{1}(1:dots(dotCount, 1) - 1);
            dotCount = dotCount + 1;
        catch
            cellNames(dotCount) = '';
        end
    end
    if length(cellNames) == 1 && isempty(cellNames{1})
        return
    end
	[cellNames whichCell whichCell] = unique(cellNames);	
	whichMat = whichCell(1:numel(matList));
	whichMatSeq = nan(numel(matList), 1);
    for i = 1:numel(matList)
		whichMatSeq(i) = str2double(matList{i}(dots(i, 2) + 2:dots(i, 3) - 1));
    end
    try
        whichImageStack = cell(numel(imgList), 1);	
        whichImg = whichCell(numel(matList) + (1:numel(imgList)));
        numMat = numel(matList);
        for i = 1:numel(imgList)
            whichImageStack{i} = imgList{i}(dots(numMat + i, 1) + 1:dots(numMat + i, 2) - 1);
        end
    catch
        whichImg = [];
    end
	whichPic = whichCell(numel(matList) + numel(imgList) + (1:numel(picList)));
	for cellIndex = 1:numel(cellNames)
		% determine what type of files exist for this cell
			whatPresent = 0;
			if any(whichMat == cellIndex)
				whatPresent = whatPresent + 2;
			end
			if any(whichImg == cellIndex)
				whatPresent = whatPresent + 1;
			end
			if any(whichPic == cellIndex)
				whatPresent = whatPresent + 4;
			end		
			
		% generate the cell node		
            if any(whichMat == cellIndex) || any(whichPic == cellIndex) || any(whichImg == cellIndex)
                cellPath = [nodePath cellNames{cellIndex}];
                cellNode = javax.swing.tree.DefaultMutableTreeNode(NodeInfo(cellNames{cellIndex}, java.lang.Integer(whatPresent), cellPath, '1'));
                treeModel.insertNodeInto(cellNode, node, node.getChildCount());
            end
		
		% generate any sequence nodes
			if any(whichMat == cellIndex)
				for seqIndex = unique(whichMatSeq(whichMat == cellIndex))'
                    cellNode.add(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(['S' sprintf('%0.0f', seqIndex) '  (' sprintf('%3.0f', sum(whichMatSeq(whichMat == cellIndex) == seqIndex)) ')'], java.lang.Integer(13), [cellPath matList{find(whichMat == cellIndex, 1)}(dots(find(whichMat == cellIndex, 1), 1):dots(find(whichMat == cellIndex, 1), 2)) 'S' sprintf('%0.0f', seqIndex)], '1')));                        
				end
			end
		
		% generate any pic nodes
			if any(whichPic == cellIndex)
                cellNode.add(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(['  (' sprintf('%3.0f', sum(whichPic == cellIndex)) ')'], java.lang.Integer(14), [cellPath '.pic'], '1')));                                        
			end
		
		% generate any img nodes
			if any(whichImg == cellIndex)
                imgNode = javax.swing.tree.DefaultMutableTreeNode(NodeInfo(['  (' sprintf('%3.0f', sum(whichImg == cellIndex)) ')'], java.lang.Integer(15), [cellPath '.img'], '1'));
                cellNode.add(imgNode);

				for imgIndex = unique(whichImageStack(whichImg == cellIndex))'
                	imgNode.add(javax.swing.tree.DefaultMutableTreeNode(NodeInfo([imgIndex{1} '  (' sprintf('%3.0f', numel(strmatch(imgIndex{1}, whichImageStack(whichImg == cellIndex), 'exact'))) ')'], java.lang.Integer(16), [cellPath '.' imgIndex{1}], '1')));                                                                            
				end
			end
	end % for cellIndex = 1:numel(cellNames)