function zStackGui

if ~isappdata(0, 'zStackGui')
	if ~ispref('locations', 'zStackGui')
		setpref('locations', 'zStackGui', [100 50 24.4 5.9]);
	end

    figHandle = hgload('zStack');
    handles = guihandles(figHandle);
    setappdata(0, 'zStackGui', figHandle);
    set(figHandle, 'position', getpref('locations', 'zStackGui'), 'closeRequestFcn', @closeMe);

    set(handles.cmdTakeImage, 'callback', @takeImage);
	set(handles.txtCellName, 'callback', @zeroCounter);
	set(handles.txtStackName, 'callback', @zeroCounter);
        
    % set the starting path for z stacks
    if isappdata(0, 'experiment')
        set(0, 'showHidden', 'on')
        path = get(findobj('tag', 'mnuSetDataFolder'), 'userData');
        set(0, 'showHidden', 'off');
        hasPath = true;
    else
        path = pwd;
        hasPath = false;
    end
        
else
    % restack the windows
    figHandle = figure(getappdata(0, 'zStackGui'));
end

onScreen(figHandle);
imageCounter = 1;
if isappdata(0, 'currentExperiment')
    experimentData = getappdata(0, 'currentExperiment');
    set(findobj('tag', 'txtCellName'), 'string', experimentData.cellName)
end

    function zeroCounter(varargin)
        imageCounter = 1;
    end

    function takeImage(varargin)
        set(varargin{1}, 'enable', 'off');
        if ~hasPath
            tempPath = path;
            path = uigetdir(path, 'Enter location for stack');
            if path == 0
                path = tempPath;
                set(varargin{1}, 'enable', 'on');
                return
            end
        end
        
        cellName = get(handles.txtCellName, 'string');
		cellName(cellName == '.') = '_';
		stackName = get(handles.txtStackName, 'string');
		stackName(stackName == '.') = '_';
			
		rasterScan([path filesep cellName '.' stackName '.' num2str(imageCounter) '.img']);
		imageCounter = imageCounter + 1;
        set(varargin{1}, 'enable', 'on');
    end

    function closeMe(varargin)
		setpref('locations', 'zStackGui', get(figHandle, 'position'));
        rmappdata(0, 'zStackGui');
        delete(figHandle);
    end
end