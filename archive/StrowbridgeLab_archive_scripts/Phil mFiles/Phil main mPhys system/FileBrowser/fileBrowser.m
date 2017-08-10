function figHandle = fileBrowser(startingDir)
% browse data files or a given data file
% fileBrowser(starting_directory);
% fileBrowser(starting_cell);
% fileBrowser(starting_episode);
% handle = fileBrowser;
% version = fileBrowser('$version');
% fileBrowser('$write filename'); % write the current columns to a file
% fileBrowser('$filename'); % load the columns from the given file
% to do:
%   when reading from a database, allow filtering which cells shown by drug, etc.

versionNumber = 4.00;
if nargin == 1 && ischar(startingDir) && strcmp(startingDir, '$version')
    figHandle = versionNumber;
    return
end

% create a browser if none exists
	if ~isappdata(0, 'fileBrowser')
        whereAt = mfilename('fullpath');
        whereAt = whereAt(1:find(whereAt == filesep, 1, 'last') - 1);
        javaaddpath([whereAt filesep 'fileBrowser.jar']);

        import javax.swing.*;
        import javax.swing.table.*;
        import javax.swing.tree.*;
        
        if ~ispref('locations', 'fileBrowser')
			setpref('locations', 'fileBrowser', [0 30 1200 300 .25]);
        end
        
        installDir = which('fileBrowser');
        installDir = installDir(1:find(installDir == filesep, 1, 'last'));        
		
        % create the figure 
            location = getpref('locations', 'fileBrowser');        
            figHandle = figure('closerequestfcn', @closeBrowser, 'menu', 'none', 'name', ['Loading fileBrowser v' sprintf('%1.2f', versionNumber)], 'numbertitle', 'off', 'visible', 'on', 'position', location(1:4), 'resizefcn', @resizeMe);
            setappdata(figHandle, 'ratio', location(5));

        % create the tree view
            desktopNode = javax.swing.tree.DefaultMutableTreeNode(NodeInfo('Desktop', java.lang.Integer(0), ['Desktop' filesep], '1'));
            treeModel = javax.swing.tree.DefaultTreeModel(desktopNode);
            treeHandle = javax.swing.JTree(treeModel);
            treeHandle.addTreeSelectionListener(TreeCallback(treeHandle));

            treeScroller = JScrollPane(treeHandle);
            treeScroller.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED);
            treeScroller.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);              
            [treeScroller treeScroller] = javacomponent(treeScroller, [0 0 location(3) * location(5) location(4)], figHandle);
            set(treeHandle, 'TreeWillExpandCallback', @treeExpand);
            set(treeHandle, 'MouseReleasedCallback', @treeMouseUp);
            iconDir = [whereAt filesep 'Icons' filesep];
            iconDir(iconDir == filesep) = '/';
            treeHandle.setCellRenderer(FileTreeRenderer(iconDir));
            
        % create a ui context menu for right clicks on the tree view
            f = uicontextmenu;
                uimenu(f,'label','Reparse Directory', 'callback', @reparseDir);
                fileNames = dir([installDir 'Directory Add-ons']);
                beenSeparated = 0;
                for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
                    try
                        funHandle = str2func(iFiles{1}(1:end - 2));
                        if ~beenSeparated
                            uimenu(f, 'Label', funHandle(), 'callback', @characterizeDirectory, 'userData', funHandle, 'separator', 'on');
                            beenSeparated = 1;
                        else
                            uimenu(f, 'Label', funHandle(), 'callback', @characterizeDirectory, 'userData', funHandle);
                        end
                    catch
                        disp(['File ' iFiles{1} ' in Directory Characterization folder is not a valid directory characterizer']);
                    end
                end               
            setappdata(treeHandle, 'uiContextMenu', f);            
            
        % create the list view for traces
            listHandle = javax.swing.JTable;
            
            sorter = TableSorter(TableRemovable, listHandle);
            listHandle.setModel(sorter);
            listHandle.setAutoCreateColumnsFromModel(0);
            traceScroller = JScrollPane(listHandle);
            traceScroller.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED);
            traceScroller.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);           
            set(traceScroller, 'Background', [1 1 1]);
            
            % class stolen from Yair Altman with modifications:
            % http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=14225&objectType=file
            sorter.setTableHeader(listHandle.getTableHeader());
          
            [traceScroller traceScroller] = javacomponent(traceScroller, [location(3) * location(5) 0 location(3) * (1 - location(5)) location(4)], figHandle);
            set(listHandle, 'MouseReleasedCallback', @loadEpisode);
            set(listHandle, 'KeyReleasedCallback', @loadEpisode);
            set(listHandle, 'ShowHorizontalLines', 'off');
            set(listHandle, 'ShowVerticalLines', 'off');        
            set(listHandle.getColumnModel, 'ColumnMovedCallback', @moveColumn);

        % create a ui context menu for right clicks on the list view column headers
            columnHeadersMenu = uicontextmenu;
                g = uimenu(columnHeadersMenu,'Label','Add Column');  
                    uimenu(g,'Label','New...','Callback', @addColumn,'separator', 'on');
				uimenu(columnHeadersMenu,'Label','Edit Columns...','Callback',@editColumns);
                uimenu(columnHeadersMenu,'Label','Remove Column','Callback', @removeColumn); 
                uimenu(columnHeadersMenu,'Label','Plot vs');             
                uimenu(columnHeadersMenu,'Label','Copy Column','Callback', @copyColumn);   
                uimenu(columnHeadersMenu,'Label','Copy all Columns','Callback', @copyAllColumns); 
                uimenu(columnHeadersMenu,'Label','Export Column to Workspace','Callback', @exportColumn);
            setappdata(listHandle, 'columnContextMenu', columnHeadersMenu);    
            
        % create a ui context menu for right clicks on the list view            
            f = uicontextmenu('tag', 'traceList');
                uimenu(f,'Label','Copy Rows', 'callback', @copyRows, 'separator', 'on');            
            setappdata(listHandle, 'uiContextMenu', f);                 
            
        % set app data
            setappdata(0, 'fileBrowser', figHandle);
            
        % add desktop information            
            if ~addSubDirs(treeModel, desktopNode)
                addSeqNodes(treeModel, desktopNode);
            end

        % add drives and root
            rootNode = javax.swing.tree.DefaultMutableTreeNode(NodeInfo('My Computer', java.lang.Integer(8), '', '1'));        
            treeModel.insertNodeInto(rootNode, desktopNode, desktopNode.getChildCount());
            fileRoots = java.io.File.listRoots();
            for i = 1:numel(fileRoots)
                tempPath = get(fileRoots(i), 'absolutepath');
                treeModel.insertNodeInto(javax.swing.tree.DefaultMutableTreeNode(NodeInfo(tempPath(1:end - 1), java.lang.Integer(9), tempPath, '0')), rootNode, rootNode.getChildCount());        
            end
            treeHandle.expandPath(javax.swing.tree.TreePath(rootNode.getPath));

		% save the handles in the figure's userData
            set(figHandle, 'userData', {treeHandle, rootNode, desktopNode, listHandle, treeScroller, traceScroller});            
			
		% move to screen if necessary
            onScreen(figHandle);
            
        set(figHandle, 'name', ['FileBrowser v' sprintf('%1.2f', versionNumber)]);
        setappdata(figHandle, 'fixedColumns', 0);
        setappdata(figHandle, 'populateColumns', @populateColumns);
	else
		figHandle = figure(getappdata(0, 'fileBrowser'));
	end

% if an initial directory is passed then load to it   
    if nargin > 0
        figureHandle = getappdata(0, 'fileBrowser');
        handles = get(figureHandle, 'userData');
        treeHandle = handles{1};
        rootNode = handles{2};         
        treeModel = treeHandle.getModel;
        listHandle = handles{4};
        
        if strcmp(startingDir(1), '$')
            if strcmp(startingDir(1:7), '$write ')
                % write the current columns to the file given
                fid = fopen(startingDir(8:end), 'w');
                    fprintf(fid, '[%s]\n', num2str(getpref('fileBrowser', 'columnOrders')));
                    columnNames = getpref('fileBrowser','columnNames');
                    columnWidths = getpref('fileBrowser','columnWidths');
                    columnTags = getpref('fileBrowser','columnTags');
                    for i = 1:numel(columnNames)
                        fprintf(fid, '"%s"\t%1.0f\t"%s"\n', columnNames{i}, columnWidths(i), columnTags{i});
                    end
                fclose(fid);
                return
            else
                % assume that the path of a text file was passed and load it as
                % columns
                % add preknown channels if none present
                if exist(startingDir(2:end), 'file') == 2
                    try
                        fid = fopen(startingDir(2:end), 'r');
                            setpref('fileBrowser','columnOrders', str2num(fgetl(fid)));                
                            C = textscan(fid, '%q %u16 %q', 'delimiter', char(9));
                        fclose(fid);
                        setpref('fileBrowser','columnNames', C{1});
                        setpref('fileBrowser','columnWidths', C{2});
                        setpref('fileBrowser','columnTags', C{3});
                        setappdata(getappdata(0, 'fileBrowser'), 'fixedColumns', 0);                        
                        populateColumns(listHandle);
                        setappdata(getappdata(0, 'fileBrowser'), 'fixedColumns', 1);
                        if listHandle.getColumnCount > 0 && listHandle.getRowCount > 0
                            addEpisodes(treeHandle.getLastSelectedPathComponent.getUserObject);
                        end
                        return;
                    catch
                        error(['Error reading column file: ' startingDir(2:end)])
                    end
                else
                    error(['No such file: ' startingDir(2:end)])
                end
            end
        end        
        
		startingDir = strtrim({startingDir});
		startingDir = startingDir{1};
        if ispc
            desktopPath = fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), 'Desktop', filesep);        
        else
            desktopPath = fullfile(getenv('HOME'), 'Desktop', filesep);
        end
        if strfind(startingDir, desktopPath)
            startingDir = ['Desktop' startingDir(numel(desktopPath):end)];
            rootNode = handles{3};
            dirs = find(startingDir == filesep);            
            dirs = dirs(2:end);
        else
            dirs = find(startingDir == filesep);            
        end
        if startingDir(end) ~= filesep
            dirs(end + 1) = numel(startingDir);
        end
        
        node = rootNode;
        i = 1;
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
                    if strcmpi(nodeInfo.getPath, startingDir(1:dirs(i)))
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
            if ~strcmpi(nodeInfo.getPath, startingDir(1:dirs(i)))
                addNewEpisode(node, startingDir(dirs(i - 1) + 1:end));
                break
            end
            i = i + 1;
        end
        treeHandle.scrollPathToVisible(javax.swing.tree.TreePath(node.getPath));
        treeHandle.expandPath(javax.swing.tree.TreePath(node.getPath));
    end

%% **************
%% event handlers
%% **************

function resizeMe(varargin)
    handles = get(varargin{1}, 'userData');
    ratio = getappdata(varargin{1}, 'ratio');
    if ~isempty(handles)
        figPos = get(varargin{1}, 'position');
        set(handles{5}, 'position', [0 0 round(figPos(3) * ratio) figPos(4)]);
        set(handles{6}, 'position', [round(figPos(3) * ratio) 0 round(figPos(3) *(1 - ratio)) figPos(4)]);
    end
    
function treeMouseUp(varargin)
    drawnow; % without this, sometimes expanding a node of the tree reloads the table
    switch get(varargin{2}, 'Button')
        case 3
            figPos = get(getappdata(0, 'fileBrowser'), 'position');
            handles = get(getappdata(0, 'fileBrowser'), 'userData');            
            set(getappdata(handles{1}, 'uiContextMenu'), 'position', [get(varargin{2}, 'X') figPos(4) - get(varargin{2}, 'Y')], 'visible', 'on');
        case 1
            if strcmp(get(get(varargin{2}, 'Source'), 'name'), 'NodeClicked')
                treeHandle = get(varargin{2}, 'Source');
                set(treeHandle, 'name', '');
                whichNode = treeHandle.getLastSelectedPathComponent;
                if isempty(whichNode)
                    return % no node selected
                end
                nodeInfo = whichNode.getUserObject;
                nodePath = char(nodeInfo.getPath);
                if ~strcmpi(nodePath, '')
                    set(getappdata(0, 'fileBrowser'), 'name', 'Loading...');
                    drawnow;
                    addEpisodes(nodeInfo);
                end
                set(getappdata(0, 'fileBrowser'), 'name', nodePath);
                drawnow;
            end
    end
        
function treeExpand(varargin)
    oldName = get(getappdata(0, 'fileBrowser'), 'name');
    set(getappdata(0, 'fileBrowser'), 'name', 'Parsing...');
    drawnow;
    rootNode = get(get(varargin{2}, 'path'), 'LastPathComponent');
    treeModel = get(varargin{2}, 'Source');
    treeModel = treeModel.getModel;
    tempNode = get(rootNode, 'FirstChild');
    for i = 1:get(rootNode, 'childCount')
        nodeObject = tempNode.getUserObject;
        if strcmp(char(nodeObject.getParsed), '0')
            try
                if ~addSubDirs(treeModel, tempNode)
                    addSeqNodes(treeModel, tempNode);
                end
            catch
                % some folders miss a parsed tag and end up here
            end
            nodeObject.setParsed('1');
        end
        if i < get(rootNode, 'childCount')
            tempNode = get(tempNode, 'NextSibling');
        end
    end
    set(getappdata(0, 'fileBrowser'), 'name', oldName);    
   
function moveColumn(varargin)
    % fix orders in preferences
    if varargin{2}.getFromIndex == varargin{2}.getToIndex
        return % why bother
    end
    columnOrders = getpref('fileBrowser', 'columnOrders');
    savedOrders = columnOrders;
    columnOrders = columnOrders([1:varargin{2}.getToIndex - 1 varargin{2}.getFromIndex varargin{2}.getToIndex:end]);
    columnOrders(varargin{2}.getFromIndex + (varargin{2}.getToIndex < varargin{2}.getFromIndex)) = [];
    setpref('fileBrowser', 'columnOrders', columnOrders);     
    
    % fix orders in table model
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    % http://www.exampledepot.com/egs/javax.swing.table/RemCol.html
    % Correct the model indices in the TableColumn objects
    % by changing all of the model indices to match
    enum = handles{4}.getColumnModel().getColumns();
    enum.nextElement; % skip the hidden column with the file name
    enum.nextElement; % skip the hidden column with the filter info   
    i = 1;
    while enum.hasMoreElements
        c = enum.nextElement();
        c.setModelIndex(find(columnOrders == savedOrders(i), 1, 'first') + 1);
        i = i + 1;
    end                   
    
function addColumn(varargin)
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    parentMenu = get(get(varargin{1}, 'parent'), 'parent');
    columnNames = getpref('fileBrowser', 'columnNames');
    columnWidths = getpref('fileBrowser', 'columnWidths');
    columnTags = getpref('fileBrowser', 'columnTags');
    columnOrders = getpref('fileBrowser', 'columnOrders');
        
    colHeader = get(varargin{1}, 'Label');
    if ~strcmp(colHeader, 'New...')
        whichCol = find(strcmp(columnNames, colHeader), 1, 'first');
        newCol = javax.swing.table.TableColumn(handles{4}.getColumnCount);
        newCol.setHeaderValue(columnNames{whichCol});
        newCol.setPreferredWidth(columnWidths(whichCol));
        handles{4}.getModel.setColumnCount(handles{4}.getColumnCount + 1);
        handles{4}.addColumn(newCol);
        handles{4}.getModel.addColumn(java.lang.String(columnNames{whichCol}));
        handles{4}.getModel.fireTableStructureChanged;
        
        delete(varargin{1});
        setpref('fileBrowser','columnOrders',[columnOrders whichCol]);      
    else
        % input dialog with width, name, tag
        outParams = inputdlg({'Name', 'Width', 'Function'},'Column',1, {'','60',''});
        
        if numel(outParams) > 0
            % add column
            newCol = javax.swing.table.TableColumn(handles{4}.getModel.getColumnCount);
            newCol.setHeaderValue(outParams{1});
            newCol.setPreferredWidth(str2double(outParams{2}));
            handles{4}.getModel.setColumnCount(handles{4}.getColumnCount + 1);            
            handles{4}.addColumn(newCol);            
            handles{4}.getModel.addColumn(java.lang.String(outParams{1}));            
            handles{4}.getModel.fireTableStructureChanged;
            
            % add to prefs
            columnNames{end + 1} = outParams{1};
            columnWidths(end + 1) = str2double(outParams{2});
            columnTags{end + 1} = outParams{3};
            whichCol = length(columnNames);            
            setpref('fileBrowser','columnNames', columnNames);
            setpref('fileBrowser','columnWidths', columnWidths);
            setpref('fileBrowser','columnTags', columnTags);
            setpref('fileBrowser','columnOrders',[columnOrders numel(columnTags)]);
            colHeader = outParams{1};
        else
            colHeader = [];
        end     
    end
    
    % add to plotVs menu
    if ~isempty(colHeader)
        setpref('fileBrowser', 'columnOrders', [columnOrders whichCol]);
        uimenu(findobj('type', 'uimenu', 'label', 'Plot vs', 'parent', parentMenu), 'Label', colHeader, 'callback', @plotColumnVs);
        oldName = get(getappdata(0, 'fileBrowser'), 'name');
        set(getappdata(0, 'fileBrowser'), 'name', 'Loading Column Data...');    
        drawnow
        whichNode = handles{1}.getLastSelectedPathComponent;
        if ~isempty(whichNode)
            nodeInfo = whichNode.getUserObject;
            nodePath = char(nodeInfo.getPath);
            if ~strcmpi(nodePath, '') && ismember(double(nodeInfo.getIcon), [1:7 13:17])
                set(getappdata(0, 'fileBrowser'), 'name', 'Loading...');
                drawnow;
                addEpisodes(nodeInfo);
            end    
        end
        set(getappdata(0, 'fileBrowser'), 'name', oldName);
    end
    
function editColumns(varargin)
% edit the available column contents
    if isdeployed
        msgbox('Not available when compiled')
        return
    end
	handles = get(getappdata(0, 'fileBrowser'), 'userData');
    columnNames = getpref('fileBrowser', 'columnNames');
    columnTags = getpref('fileBrowser', 'columnTags');
    columnOrders = getpref('fileBrowser', 'columnOrders');
	columnData = [columnNames(columnOrders) columnTags(columnOrders)];
	disp('You may edit the text of columns, but do not add or remove columns.');
    disp('Type dbcont in the command window when done.');
	openvar('columnData');
	keyboard
    for i = 1:handles{4}.getColumnCount - 2
        handles{4}.getColumnModel.getColumn(i + 1).setHeaderValue(columnData{i, 1});
    end
    columnNames(columnOrders) = columnData(:,1);
    setpref('fileBrowser', 'columnNames', columnNames);
    columnTags(columnOrders) = columnData(:,2);
    setpref('fileBrowser', 'columnTags', columnTags);
    whichNode = handles{1}.getLastSelectedPathComponent;
    if ~isempty(whichNode)
        nodeInfo = whichNode.getUserObject;
        nodePath = char(nodeInfo.getPath);
        if ~strcmpi(nodePath, '') && ismember(double(nodeInfo.getIcon), [1:7 13:17])
            set(getappdata(0, 'fileBrowser'), 'name', 'Loading...');
            drawnow;
            addEpisodes(nodeInfo);
            set(getappdata(0, 'fileBrowser'), 'name', nodePath);
        end    
    end
	
function removeColumn(varargin)
    % ask whether they would like to remove it from the database
    whichMenu = get(varargin{1}, 'parent');
    varargin = getappdata(getappdata(0, 'fileBrowser'), 'varargin');    
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    whichCol = handles{4}.getColumnModel.getColumnIndexAtX(varargin{2}.getX);
    colHeader = handles{4}.getColumnModel.getColumn(whichCol).getHeaderValue;    
    
    switch questdlg('Do you want to permanently remove the column from the database?', 'Remove Column from Database');
        case 'Yes'
            % remove column
            columnNames = getpref('fileBrowser', 'columnNames');
            columnTags = getpref('fileBrowser','columnTags');
            columnWidths = getpref('fileBrowser','columnWidths');	
            columnOrders = getpref('fileBrowser','columnOrders');
            colIndex = find(strcmp(columnNames, colHeader), 1, 'first');
            
            % stolen entirely from:
            % http://www.exampledepot.com/egs/javax.swing.table/RemCol.html
            col = handles{4}.getColumnModel.getColumn(whichCol);
            columnModelIndex = col.getModelIndex;
            
            % Correct the model indices in the TableColumn objects
            % by decrementing those indices that follow the deleted column
            enum = handles{4}.getColumnModel().getColumns();
            while enum.hasMoreElements
                c = enum.nextElement();
                if c.getModelIndex() >= columnModelIndex
                    c.setModelIndex(c.getModelIndex()-1);
                end
            end            
            
            drawnow; % hangs without this pause
            handles{4}.removeColumn(col);    
            colIds = handles{4}.getModel.getTableModel.getColumnIdentifiers;
            data = handles{4}.getModel.getDataVector;
            colIds.removeElementAt(columnModelIndex);
            % Remove the column data
            for r=0:data.size-1
                row = data.get(r);
                row.removeElementAt(columnModelIndex);
            end
            handles{4}.getModel.setDataVector(data, colIds);
            
            handles{4}.getModel.fireTableStructureChanged();
            
            % remove pref
            whichOrder = find(columnOrders == colIndex, 1);
            setpref('fileBrowser','columnNames',columnNames([1:colIndex - 1 colIndex + 1:end]));
            setpref('fileBrowser','columnTags',columnTags([1:colIndex - 1 colIndex + 1:end]));
            setpref('fileBrowser','columnWidths',columnWidths([1:colIndex - 1 colIndex + 1:end]));
            setpref('fileBrowser','columnOrders',columnOrders([1:whichOrder - 1 whichOrder + 1:end]) - (columnOrders([1:whichOrder - 1 whichOrder + 1:end]) > colIndex));				
            
            % remove from plotVs menu
            delete(findobj('type', 'uimenu', 'label', colHeader, 'parent', findobj('type', 'uimenu', 'label', 'Plot vs', 'parent', whichMenu)));
            
        case 'No'
            % stolen entirely from:
            % http://www.exampledepot.com/egs/javax.swing.table/RemCol.html
            col = handles{4}.getColumnModel.getColumn(whichCol);
            columnModelIndex = col.getModelIndex;
            
            % Correct the model indices in the TableColumn objects
            % by decrementing those indices that follow the deleted column
            enum = handles{4}.getColumnModel().getColumns();
            while enum.hasMoreElements
                c = enum.nextElement();
                if c.getModelIndex() >= columnModelIndex
                    c.setModelIndex(c.getModelIndex()-1);
                end
            end
            
            drawnow; % hangs without this
            handles{4}.removeColumn(col);    
            colIds = handles{4}.getModel.getTableModel.getColumnIdentifiers;
            data = handles{4}.getModel.getDataVector;
            colIds.removeElementAt(columnModelIndex);
            % Remove the column data
            for r=0:data.size-1
                row = data.get(r);
                row.removeElementAt(columnModelIndex);
            end
            handles{4}.getModel.setDataVector(data, colIds);

            handles{4}.getModel.fireTableStructureChanged();

            % add to menus
            addMenu = findobj('label', 'Add Column', 'parent', whichMenu);
            kids = get(addMenu, 'children');
            set(kids(1), 'separator', 'off', 'label', colHeader);
            uimenu(addMenu, 'Label', 'New...', 'separator', 'on', 'callback', @addColumn);
            
            % remove pref
            columnNames = getpref('fileBrowser', 'columnNames');                
            columnOrders = getpref('fileBrowser','columnOrders');       
            colIndex = find(strcmp(columnNames, colHeader), 1, 'first');
            whichOrder = find(columnOrders == colIndex, 1);
            setpref('fileBrowser','columnOrders',columnOrders([1:whichOrder - 1 whichOrder + 1:end]));				
            
            % remove from plotVs menu
            delete(findobj('type', 'uimenu', 'label', colHeader, 'parent', findobj('type', 'uimenu', 'label', 'Plot vs', 'parent', whichMenu)));

        case {'Cancel', ''}
            % do nothing
    end
    
function plotColumnVs(varargin)
    vsColumnName = get(varargin{1}, 'Label');
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    varargin = getappdata(getappdata(0, 'fileBrowser'), 'varargin');    
    thisColumn = handles{4}.getColumnModel.getColumn(handles{4}.getColumnModel.getColumnIndexAtX(varargin{2}.getX)).getModelIndex();  
    thisColumnName = handles{4}.getColumnModel().getColumn(thisColumn).getHeaderValue;
 
    for i = 1:handles{4}.getColumnCount - 1
        if strcmp(handles{4}.getColumnModel.getColumn(i).getHeaderValue, vsColumnName)
            vsColumn = i;
            break
        end
    end    
    
    % determine whether this will be a bar chart or an X-Y scatter
    xData = zeros(handles{4}.getRowCount - 1, 1);
    yData = xData;
    numCategories = 0;
    categories = {};
    xIsTime = 0;
    yIsTime = 0;
    for i = 1:handles{4}.getRowCount
        tempData = handles{4}.getModel.getValueAt(i - 1,vsColumn);
        if length(find(tempData == ':')) > 1
            % this is time data so back convert
            xData(i) = time2sec(tempData);
            xIsTime = 1;
        elseif isnumeric(tempData)
            % numeric data
            xData(i) = tempData;
        elseif ismember(tempData(end), ['A' 'V']) && all(ismember(tempData(1:end - 2), ['e' '+' 'N' 'a' 'n' ' ' '-' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' '.']))
            % numeric with unit suffix
            xData(i) = str2double(tempData(1:end -2));            
        else
            % categorical data
            if any(ismember(tempData, categories))
                xData(i) = find(strcmp(tempData, categories));
            else
                numCategories = numCategories + 1;
                categories{numCategories} = tempData;
                xData(i) = numCategories;
            end
        end
        tempData = handles{4}.getModel.getValueAt(i - 1,thisColumn);
        if length(find(tempData == ':')) > 1
            % this is time data so back convert
            yData(i) = time2sec(tempData);
            yIsTime = 1;
        elseif isnumeric(tempData)
            % numeric data
            yData(i) = tempData;
        elseif ismember(tempData(end), ['A' 'V']) && all(ismember(tempData(1:end - 2), ['e' '+' ' ' 'N' 'a' 'n' '-' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' '.']))
            % numeric with unit suffix
            yData(i) = str2double(tempData(1:end -2));
        else
            error('Ydata cannot be categorical for plotting')
        end        
    end
    
    figure('numbertitle', 'off', 'name', get(getappdata(0, 'fileBrowser'), 'name'));
    if numCategories == 0
        % scatter plot
        plot(xData, yData, 'linestyle', 'none', 'marker', 'o', 'color', [0 0 0], 'markerSize', 4);
        if xIsTime
            tempTicks = get(gca, 'xticklabel');
            set(gca, 'xticklabel', sec2time(tempTicks));
        end
        if yIsTime
            tempTicks = get(gca, 'yticklabel');
            set(gca, 'yticklabel', sec2time(tempTicks));
        end        
    else
        % bar like plot
        plot(xData, yData, 'linestyle', 'none', 'marker', 'o', 'color', [0 0 0], 'markerSize', 4);
        set(gca, 'xtick', 1:numCategories);
        set(gca, 'xticklabel', categories);
        set(gca, 'xlim', [0.5 numCategories + 0.5]);
        if yIsTime
            tempTicks = get(gca, 'yticklabel');
            set(gca, 'yticklabel', sec2time(tempTicks));
        end           
    end
    xlabel(vsColumnName);
    ylabel(thisColumnName);

function copyColumn(varargin)
    % copy to clipboard as tab-delimited
    handles = get(getappdata(0, 'fileBrowser'), 'userData');    
    varargin = getappdata(getappdata(0, 'fileBrowser'), 'varargin');
    thisColumn = handles{4}.getColumnModel.getColumn(handles{4}.getColumnModel.getColumnIndexAtX(varargin{2}.getX)).getModelIndex();  
    
    clipText = '';
    if isempty(strfind(handles{4}.getColumnModel().getColumn(thisColumn).getHeaderValue, 'Time'))    
        for i = 0:handles{4}.getRowCount - 1
            clipText = [clipText num2str(handles{4}.getModel.getValueAt(i,thisColumn)) char(13)];
        end
    else
        for i = 0:handles{4}.getRowCount - 1
            clipText = [clipText num2str(time2sec(handles{4}.getModel.getValueAt(i,thisColumn))) char(13)];
        end        
    end
    
    clipboard('copy', clipText);
    
function copyAllColumns(varargin)
    % copy all columns to clipboard as tab-delimited
    handles = get(getappdata(0, 'fileBrowser'), 'userData');    
    
    clipText = 'Path';
    for j = 1:handles{4}.getColumnCount - 1
        clipText = [clipText char(9) handles{4}.getColumnModel().getColumn(j).getHeaderValue];
    end
    clipText = [clipText char(13)];
    
    for i = 0:handles{4}.getRowCount - 1
        for j = 0:handles{4}.getColumnCount - 1
            if isempty(strfind(handles{4}.getColumnModel().getColumn(j).getHeaderValue, 'Time'))
                clipText = [clipText num2str(handles{4}.getModel.getValueAt(i,j)) char(9)];
            else
                clipText = [clipText num2str(time2sec(handles{4}.getModel.getValueAt(i,j))) char(9)];
            end
        end
        clipText = [clipText(1:end - 1) char(13)];
    end
    
    clipboard('copy', clipText);    

function copyRows(varargin)
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    if ~double(handles{4}.getSelectedRowCount)
        return
    end
    whichSelected = handles{4}.getSelectedRows;

    clipText = '';
    for i = whichSelected'
        for j = 1:handles{4}.getColumnCount
            tempText = handles{4}.getModel.getValueAt(i, j - 1);
            if isnumeric(tempText)
                clipText = [clipText num2str(tempText) char(9)];
            else
                clipText = [clipText tempText char(9)];
            end
        end
        clipText = [clipText(1:end - 1) char(13)];
    end
    
    clipboard('copy', clipText);          
    
function exportColumn(varargin)
    % copy to workspace as matrix
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    varargin = getappdata(getappdata(0, 'fileBrowser'), 'varargin');
    thisColumn = handles{4}.getColumnModel.getColumn(handles{4}.getColumnModel.getColumnIndexAtX(varargin{2}.getX)).getModelIndex();  
    thisColumnName = handles{4}.getColumnModel().getColumn(thisColumn).getHeaderValue;
    
    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, {thisColumnName});
    if ~isempty(varName)
        xData = zeros(handles{4}.getRowCount, 1);
        for i = 1:handles{4}.getRowCount
            tempData = handles{4}.getModel.getValueAt(i - 1,thisColumn);
            if length(find(tempData == ':')) > 1
                % this is time data so back convert
                xData(i) = time2sec(tempData);
            elseif isnumeric(tempData) %all(ismember(tempData, ['e' '+' 'N' 'a' 'n' ' ' '-' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' '.']))
                % numeric data
                xData(i) = tempData;
            elseif ismember(tempData(end), ['A' 'V' 'm']) && all(ismember(tempData(1:end - 2), ['e' '+' 'N' 'a' 'n' ' ' '-' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' '.']))
                % numeric with unit suffix
                xData(i) = str2double(tempData(1:end -2));            
            else
                % categorical data
                if ~iscell(xData)
                    clear xData;
                end
                xData{i} = tempData;
            end
        end
        tempVarName = genvarname(varName, evalin('base', 'who'));
        if strcmp(varName, tempVarName)
        	assignin('base', varName{1}, xData);
        else
            switch questdlg(strcat('''', varName, ''' is not a valid variable name in the base workspace.  Is ''', tempVarName, ''' ok?'), 'Uh oh');
                case 'Yes'
                	assignin('base', tempVarName{1}, xData);
                case 'No'
                    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, tempVarName);
                    assignin('base', genvarname(varName{1}), xData);
                case 'Cancel'
                    % do nothing
            end
        end
    end

function loadEpisode(varargin)
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    if strcmp(class(varargin{2}), 'java.awt.event.MouseEvent')
        varargin{1} = get(varargin{2}, 'Source');
        whichButton = get(varargin{2}, 'Button');
    else
        % assume that it is ok to use the file and not the image table
        varargin{1} = handles{4};
        whichButton = 1;
        
        % if this was a keypress then only take certain keys
        if strcmp(class(varargin{2}), 'java.awt.event.KeyEvent') && ~ismember(varargin{2}.getKeyCode, [40 38])
            return
        end
    end
    % determine whether we are over a column
    if strcmp(class(varargin{1}), 'javax.swing.JTable')
        switch whichButton 
            case 1
                listModel = varargin{1}.getModel;
                fileNames = {};
                for i = (varargin{1}.getSelectedRows)'
                    fileNames{end + 1} = listModel.getValueAt(i,0);
                end
                clickTable(fileNames);
            case 3
                containerPos = get(handles{6}, 'position');
                set(getappdata(handles{4}, 'uiContextMenu'), 'position', [varargin{2}.getX + handles{1}.getWidth containerPos(4) - varargin{2}.getY], 'visible', 'on');        
        end
    else % handle column clicks
        containerPos = get(handles{6}, 'position');
        set(getappdata(handles{4}, 'columnContextMenu'), 'position', [varargin{2}.getX + handles{1}.getWidth containerPos(4)], 'visible', 'on');        
        setappdata(getappdata(0, 'fileBrowser'), 'varargin', varargin);
    end    
    
function closeBrowser(varargin)
	set(varargin{1}, 'units', 'pixels');
	setpref('locations', 'fileBrowser', [get(varargin{1}, 'position') getappdata(varargin{1}, 'ratio')]);

	handles = get(getappdata(0, 'fileBrowser'), 'userData');
    if ~isempty(get(handles{4}, 'tag'))
        fileBrowser(['$write ' fileparts(which('fileBrowser')) filesep 'Loaders' filesep get(handles{4}, 'tag') 'Columns.txt']);
    end    
    
    % call any specific clean up routines
    cleanUp;
    
    % removes the handle from the appdata construct
    rmappdata(0, 'fileBrowser');
    delete(varargin{1})
    
%% *****************
%% private functions
%% *****************
function populateColumns(listHandle, fileType)
if nargin == 1 || (~strcmp(get(listHandle, 'tag'), fileType) && ~getappdata(getappdata(0, 'fileBrowser'), 'fixedColumns'))
    % if there was an old set of info then save it
    if ~isempty(get(listHandle, 'tag'))
        fileBrowser(['$write ' fileparts(which('fileBrowser')) filesep 'Loaders' filesep get(listHandle, 'tag') 'Columns.txt']);
    end
    
    if nargin > 1
        % add channels from txt file
        fid = fopen([fileparts(which('fileBrowser')) filesep 'Loaders' filesep fileType 'Columns.txt'], 'r');
        if fid < 0
            % we don't have any info for this file type so use default columns        
            fid = fopen([fileparts(which('fileBrowser')) filesep 'Loaders' filesep 'columns.txt'], 'r');
        end
            columnOrders = str2num(fgetl(fid)); 
            C = textscan(fid, '%q %u16 %q', 'delimiter', char(9));
        fclose(fid);
        columnNames = C{1};
        columnWidths = C{2};

        % put this data somewhere for later access
        setpref('fileBrowser','columnOrders', columnOrders);            
        setpref('fileBrowser','columnNames', columnNames);
        setpref('fileBrowser','columnWidths', columnWidths);
        setpref('fileBrowser','columnTags', C{3});   
    else
        % assume these things were already set
        fileType = '';
        columnOrders = getpref('fileBrowser','columnOrders');            
        columnNames = getpref('fileBrowser','columnNames');
        columnWidths = getpref('fileBrowser','columnWidths');
    end
            
    % prepare the column click menus
    addColumnMenu = findobj(getappdata(listHandle, 'columnContextMenu'), 'Label', 'Add Column');
    delete(get(addColumnMenu, 'children'));
    for i = 1:numel(columnNames)
        if ~ismember(i, columnOrders)
            uimenu(addColumnMenu,'Label',columnNames{i},'Callback', @addColumn);
        end
    end
    uimenu(addColumnMenu,'Label','New...','Callback',@addColumn);
    plotVsMenu = findobj(getappdata(listHandle, 'columnContextMenu'), 'Label', 'Plot vs');    
    delete(get(plotVsMenu, 'children'));
    for i = columnOrders
        uimenu(plotVsMenu,'Label',columnNames{i},'Callback', @plotColumnVs);
    end   
            
    handles = get(getappdata(0, 'fileBrowser'),'userData');
    set(handles{6}, 'visible', 'off');
    drawnow;
    % fill in info for the column headers
    headerHandle = listHandle.getColumnModel;
    for i = headerHandle.getColumnCount - 1:-1:0
        listHandle.removeColumn(listHandle.getColumnModel.getColumn(0)); 
    end

    % setup the column headers
    listHandle.getModel.setColumnCount(0);   

    % add a column for file path
    newCol = javax.swing.table.TableColumn(0);        
    newCol.setHeaderValue('');
    newCol.setMinWidth(0);
    newCol.setMaxWidth(0);
    listHandle.addColumn(newCol);
    listHandle.getModel.addColumn(java.lang.String(''));   

    % add a column for whether a row is highlighted
    newCol = javax.swing.table.TableColumn(1);        
    newCol.setHeaderValue('F');
    newCol.setMinWidth(0);
    newCol.setMaxWidth(10);
    listHandle.addColumn(newCol);
    listHandle.getModel.addColumn(java.lang.String(''));        
    for i = 1:numel(columnOrders)
        newCol = javax.swing.table.TableColumn(i + 1);        
        newCol.setHeaderValue(columnNames{columnOrders(i)});
        newCol.setPreferredWidth(columnWidths(columnOrders(i)));
        listHandle.addColumn(newCol);
        listHandle.getModel.addColumn(java.lang.String(columnNames{columnOrders(i)}));        
    end

    % create a ui context menu for right clicks on the list view
    menuHandle = getappdata(listHandle, 'uiContextMenu');
    menuKids = get(menuHandle, 'children');
    delete(menuKids(1:end - 1));
    if ~isempty(fileType)    
        fileNames = dir([fileparts(which('fileBrowser')) filesep 'Loaders' filesep fileType]);
        beenSeparated = 0;
        for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
            try
                funHandle = str2func(iFiles{1}(1:end - 2));
                if ~beenSeparated
                    uimenu(menuHandle, 'Label', funHandle(), 'callback', @characterizeEpisode, 'userData', funHandle, 'separator', 'on');
                    beenSeparated = 1;
                else
                    uimenu(menuHandle, 'Label', funHandle(), 'callback', @characterizeEpisode, 'userData', funHandle);
                end
            catch
                disp(['File ' iFiles{1} ' in Loader folder for ' fileType ' is not properly formatted.']);
            end
        end        
    end
    
    % keep a record of what filetype this is
    set(handles{6}, 'visible', 'on');
	set(listHandle, 'tag', fileType);
end

function characterizeDirectory(varargin)
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
    whichNode = handles{1}.getLastSelectedPathComponent;
    if isempty(whichNode)
        whichNode = handles{3};
    end
    nodeInfo = whichNode.getUserObject;
    nodePath = char(nodeInfo.getPath);
    feval(get(varargin{1}, 'userData'), nodePath);
    
function reparseDir(varargin)
	handles = get(getappdata(0, 'fileBrowser'), 'userData');
    
    whichNode = handles{1}.getLastSelectedPathComponent;
    if isempty(whichNode)
        error('Must first select a node to reparse')
    end
    nodeInfo = whichNode.getUserObject;
    nodeInfo.setParsed('0');
    if nodeInfo.getIcon == 12
        % if this was from a preParse file then let the us know that it is
        % now live
        nodeInfo.setIcon(java.lang.Integer(10));
    end
    if strcmp(nodeInfo.getPath, ['Desktop' filesep])
        % reparse drives
        for i = 0:whichNode.getChildCount() - 1
            whichNode.getChildAt(i).getUserObject.setParsed('0');
        end
        pathData = whichNode.getPath;
        handles{1}.expandPath(javax.swing.tree.TreePath(pathData(1)));        
    else    
        whichNode.removeAllChildren;
        if ~addSubDirs(handles{1}.getModel, whichNode)
            addSeqNodes(handles{1}.getModel, whichNode);
        end
        handles{1}.collapsePath(javax.swing.tree.TreePath(whichNode.getPath))
    end
    handles{1}.getModel.reload(whichNode);

function characterizeEpisode(varargin)
    handles = get(getappdata(0, 'fileBrowser'), 'userData');

    if ~double(handles{4}.getSelectedRowCount)
        return
    end
    % find all selected files
    fileNames = {};
    for epiIndex = handles{4}.getSelectedRows'
        fileNames{end + 1} = handles{4}.getModel.getValueAt(epiIndex,0);
    end
    if ~iscell(fileNames) == 1
        fileNames = fileNames{1};
    end        
    feval(get(varargin{1}, 'userData'), fileNames);