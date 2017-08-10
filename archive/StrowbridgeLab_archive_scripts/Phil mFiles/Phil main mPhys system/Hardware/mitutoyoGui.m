function mitutoyoGui
% on two-photon A com7 is the Y, and com8 is the x, solartron is com1
if ~isappdata(0, 'mitutoyoGui')
	if ~ispref('locations', 'mitutoyoGui')
		setpref('locations', 'mitutoyoGui', [100 50 46 5.9]);
	end
	% try setting up the communications ports
    if ~ispref('mitutoyo', 'xComm')
        try
            setupMitutoyo;
        catch
            error('Error in setting up hardware')
        end
    end
    
    figHandle = hgload('mitutoyoGui');
    handles = guihandles(figHandle);
    setappdata(0, 'mitutoyoGui', figHandle);
    set(figHandle, 'position', getpref('locations', 'mitutoyoGui'), 'closeRequestFcn', @closeMe);

    set(handles.cmdTakeImage, 'callback', @takeImage);
	set(handles.txtCellName, 'callback', @zeroCounter);
	set(handles.txtStackName, 'callback', @zeroCounter);

    if ~isappdata(0, 'mitutoyoX')
        try
            xComm = serial(['COM' sprintf('%0.0f', getpref('mitutoyo', 'xComm'))]);
            set(xComm,...
                'baudrate', 9600,...
                'parity', 'none',...
                'databits', 8,...
                'stopbits', 1,...
                'requesttosend', 'on',...
                'dataterminalready', 'on',...
                'timeout', .2,...
                'outputbuffersize', 1024,...
                'inputbuffersize', 512,...
                'terminator', 'CR');
            fopen(xComm)
        catch
            error(['Error with serial port COM' sprintf('%0.0f', getpref('mitutoyo', 'xComm')) ' in setting up mitutoyo X indicator']);
        end

        try
            yComm = serial(['COM' sprintf('%0.0f', getpref('mitutoyo', 'yComm'))]);
            set(yComm,...
                'baudrate', 9600,...
                'parity', 'none',...
                'databits', 8,...
                'stopbits', 1,...
                'requesttosend', 'on',...
                'dataterminalready', 'on',...
                'timeout', .2,...
                'outputbuffersize', 1024,...
                'inputbuffersize', 512,...
                'terminator', 'CR');
            fopen(yComm)
        catch
            error(['Error with serial port COM' sprintf('%0.0f', getpref('mitutoyo', 'yComm')) ' in setting up mitutoyo Y indicator']);
        end		
        while strcmp(get(yComm, 'status'), 'closed')
            wait(0.1)
        end

        setappdata(0, 'mitutoyoX', xComm);
        setappdata(0, 'mitutoyoY', yComm);
    else
        xComm = getappdata(0, 'mitutoyoX');
        yComm = getappdata(0, 'mitutoyoY');
    end
    
    if ~isappdata(0, 'mitutoyoZ');
        if ~ispref('solartron', 'commPort')
            commPort = inputdlg('Enter serial port to which Solartron is connected', 'Comm ', 1, {'3'});
            if isempty(commPort)
                warning('Must set a value for Solartron indicator serial port');
            elseif any(commPort{1} > 57 | commPort{1} < 48)
                warning('Value must be a number')
            else    
                setpref('solartron', 'commPort', str2double(commPort{1}));
            end
        end
        if ispref('solartron', 'commPort')
            zComm = serial(['COM' sprintf('%0.0f', getpref('solartron', 'commPort'))]);
            set(zComm,...
                'baudrate', 57600,...
                'parity', 'none',...
                'databits', 8,...
                'stopbits', 1,...
                'requesttosend', 'off',...
                'dataterminalready', 'off',...
                'timeout', 1,...
                'outputbuffersize', 1024,...
                'inputbuffersize', 25,...
                'terminator', 'CR/LF');
            fopen(zComm)
            while strcmp(get(zComm, 'status'), 'closed')
                wait(0.1)
            end        
            setappdata(0, 'mitutoyoZ', zComm);        
        else
            zComm = [];
        end
    else
        zComm = getappdata(0, 'mitutoyoZ');
    end
    
    % set up a timer
        mitutoyoTimer =timer('name', 'mitutoyoTimer', 'TimerFcn', @mitutoyoLocation, 'Period', 0.6, 'executionMode', 'fixedDelay', 'busyMode', 'drop');
        start(mitutoyoTimer)
        
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
    figHandle = figure(getappdata(0, 'mitutoyoGui'));
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
%         stop(mitutoyoTimer);
        if ~hasPath
            tempPath = path;
            path = uigetdir(path, 'Enter location for stack');
            if path == 0
                path = tempPath;
                return
            end
        end
        
        cellName = get(handles.txtCellName, 'string');
		cellName(cellName == '.') = '_';
		stackName = get(handles.txtStackName, 'string');
		stackName(stackName == '.') = '_';
			
		rasterScan([path filesep cellName '.' stackName '.' num2str(imageCounter) '.img']);
		imageCounter = imageCounter + 1;
%         start(mitutoyoTimer);
        set(varargin{1}, 'enable', 'on');
    end

	function mitutoyoLocation(varargin)
		% ask for the current position
		fprintf(xComm, 'R');
		tempLabel{1} = ['X = ' num2str(str2double(fgetl(xComm))) ' mm'];
		fprintf(yComm, 'R');
		tempLabel{2} = ['Y = ' num2str(str2double(fgetl(yComm))) ' mm'];
        if ~isempty(zComm)
            pause(.01)
            fwrite(zComm, char(2));
            tempLabel{3} = ['Z = ' num2str(str2double(fgetl(zComm))) ' mm'];
        end
        pause(.01)
        set(handles.lblLocation, 'string', tempLabel);
    end

    function closeMe(varargin)
%         stop(mitutoyoTimer);                
%         delete(mitutoyoTimer);        
        fclose(xComm);
		fclose(yComm);
        delete(xComm);
		delete(yComm);
        if ~isempty(zComm)
            fclose(zComm);
            delete(zComm);
        end
		setpref('locations', 'mitutoyoGui', get(figHandle, 'position'));
		rmappdata(0, 'mitutoyoGui');
		rmappdata(0, 'mitutoyoX');
		rmappdata(0, 'mitutoyoY');
		if isappdata(0, 'mitutoyoZ')
			rmappdata(0, 'mitutoyoZ');
		end
        delete(figHandle);
    end
end