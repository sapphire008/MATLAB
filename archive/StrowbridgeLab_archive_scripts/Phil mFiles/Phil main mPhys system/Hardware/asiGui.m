function asiGui

if ~isappdata(0, 'asiGui')
    if ~ispref('locations', 'asiGui')
		setpref('locations', 'asiGui', [100 50 46 10.4]);
    end

	if ~ispref('ASI', 'commPort')
        try
    		setupASI;
        catch
            error('Error in setting up ASI');
        end
	end    

    figHandle = hgload('asiGui');
    handles = guihandles(figHandle);
    setappdata(0, 'asiGui', figHandle);
    set(figHandle, 'position', getpref('locations', 'asiGui'), 'closeRequestFcn', @closeMe);
    
    set(handles.xStep, 'callback', @setXStep);
    set(handles.yStep, 'callback', @setYStep);
    set(handles.zStep, 'callback', @setZStep);
    set(handles.incX, 'callback', @incX);
    set(handles.decX, 'callback', @decX);
    set(handles.incY, 'callback', @incY);
    set(handles.decY, 'callback', @decY);
    set(handles.incZ, 'callback', @incZ);
    set(handles.decZ, 'callback', @decZ);
    set(handles.doZStack, 'callback', @doZStack);
	
    try
		commPort = serial(['COM' sprintf('%0.0f', getpref('ASI', 'commPort'))]);
		set(commPort,...
			'baudrate', 9600,...
			'parity', 'none',...
			'databits', 8,...
			'stopbits', 1,...
			'requesttosend', 'on',...
			'dataterminalready', 'on',...
			'timeout', 1,...
			'outputbuffersize', 512,...
			'inputbuffersize', 1024,...
            'bytesAvailableFcnMode', 'byte',...
            'bytesAvailableFcnCount', 3,...
            'terminator', '',...
            'flowControl', 'hardware',...
            'recordName', 'myRecord.txt',...
            'recordDetail', 'verbose');
		fopen(commPort)
	catch
		error(['Error with serial port COM' sprintf('%0.0f', getpref('ASI', 'commPort')) ' in setting up ASI']);
    end	
    setappdata(0, 'asiPort', commPort);
	
    % let the port open and get set
        pause(1)
        asiTimer =timer('name', 'asiLocation', 'TimerFcn', @asiLocation, 'Period', 0.5, 'executionMode', 'fixedDelay', 'busyMode', 'drop');
    
    % setup increments
        fwrite(commPort, [char(255) char(66)]); % low level commands mode
        setXStep;
        setYStep;
        setZStep;
        start(asiTimer);
        
    % set the starting path for z stacks
        path = pwd;
        
else
    % restack the windows
    figHandle = figure(getappdata(0, 'asiGui'));
end

onScreen(figHandle);
	
	function decX(varargin)
		fwrite(commPort, [char(24) char(45) char(0) char(58)]);
	end

	function incX(varargin)
		fwrite(commPort, [char(24) char(43) char(0) char(58)]);
	end

	function decY(varargin)
		fwrite(commPort, [char(25) char(45) char(0) char(58)]);
	end

	function incY(varargin)
		fwrite(commPort, [char(25) char(43) char(0) char(58)]);
	end

	function decZ(varargin)
		fwrite(commPort, [char(26) char(45) char(0) char(58)]);
	end

	function incZ(varargin)
		fwrite(commPort, [char(26) char(43) char(0) char(58)]);
	end

	function setXStep(varargin)
		fwrite(commPort, [char(24) char(68) char(3) char(mod(str2double(get(handles.xStep, 'string')) * 10, 256)) char(round(mod(str2double(get(handles.xStep, 'string')) * 10 / 256, 256))) char(round(mod(str2double(get(handles.xStep, 'string')) * 10 / 256 / 256, 256))) char(58)]);
	end

	function setYStep(varargin)
		fwrite(commPort, [char(25) char(68) char(3) char(mod(str2double(get(handles.yStep, 'string')) * 10, 256)) char(round(mod(str2double(get(handles.yStep, 'string')) * 10 / 256, 256))) char(round(mod(str2double(get(handles.yStep, 'string')) * 10 / 256 / 256, 256))) char(58)]);      
	end

	function setZStep(varargin)
		fwrite(commPort, [char(26) char(68) char(3) char(mod(-str2double(get(handles.zStep, 'string')) * 10, 256)) char(round(mod(-str2double(get(handles.zStep, 'string')) * 10 / 256, 256))) char(round(mod(-str2double(get(handles.zStep, 'string')) * 10 / 256 / 256, 256))) char(58)]);                  
    end

    function doZStack(varargin)
        if strcmp(get(varargin{1}, 'string'), 'Execute')
            stop(asiTimer);
            set(handles.doZStack, 'string', 'Stop');
            tempPath = path;
            path = uigetdir(path, 'Enter location for stack');
            if path == 0
                path = tempPath;
                return
            end

            currentPosition = readASI;
            startPoint = currentPosition(3);
            stepSize = str2double(get(handles.zStep, 'string'));
            stopPoint = startPoint + str2double(get(handles.stackHeight, 'string'));
            cellName = get(handles.txtCellName, 'string');
            cellName(cellName == '.') = '_';
            stackName = get(handles.txtStackName, 'string');
            stackName(stackName == '.') = '_';
            if stepSize > 0
                if stopPoint >= startPoint
                    if stepSize < 0
                        msgbox('With a negative step you will never achieve an increase in height.  Please change the step or stack height');
                        return
                    end
                    comparisonFunction = @le;
                    movementFunction = @incZ;
                else
                    if stepSize > 0
                        msgbox('With a positive step you will never achieve a decrease in height.  Please change the step or stack height');
                        return
                    end
                    comparisonFunction = @ge;
                    movementFunction = @decZ;
                end
            else
                if stopPoint <= startPoint
                    if stepSize > 0
                        msgbox('With a negative step you will never achieve an increase in height.  Please change the step or stack height');
                        return
                    end
                    comparisonFunction = @ge;
                    movementFunction = @incZ;
                else
                    if stepSize < 0
                        msgbox('With a positive step you will never achieve a decrease in height.  Please change the step or stack height');
                        return
                    end
                    comparisonFunction = @le;
                    movementFunction = @decZ;
                end                
            end

            imageCounter = 1;
            while comparisonFunction(currentPosition(3), stopPoint)
                rasterScan([path filesep cellName '.' stackName '.' num2str(imageCounter) '.img']);
                movementFunction();
                pause(.5);
                if strcmp(get(handles.doZStack, 'string'), 'Execute')
                    return
                end

                asiLocation;
                imageCounter = imageCounter + 1;
                currentPosition = readASI;
                newVal = 46 * abs((startPoint - currentPosition(3)) / (startPoint - stopPoint));
                if ~isnan(newVal) && newVal ~= 0
                    set(handles.progressBar, 'position', [0 0 newVal .2]);                
                end
            end
        end
        set(handles.progressBar, 'position', [0 0 46 .2]);                        
        set(handles.doZStack, 'string', 'Execute');        
        start(asiTimer);
    end

	function asiLocation(varargin)
        currentPosition = readASI;
		tempLabel{1} = ['X = ' num2str(currentPosition(1)) char(181) 'm'];
		tempLabel{2} = ['Y = ' num2str(currentPosition(2)) char(181) 'm'];
		tempLabel{3} = ['Z = ' num2str(currentPosition(3)) char(181) 'm'];
		set(handles.lblLocation, 'string', tempLabel);
    end

    function closeMe(varargin)
        stop(asiTimer);                
        delete(asiTimer);        
        fclose(commPort);
        delete(commPort);
        rmappdata(0, 'asiPort');
		setpref('locations', 'asiGui', get(figHandle, 'position'));
		rmappdata(0, 'asiGui');
        delete(figHandle);
    end
end