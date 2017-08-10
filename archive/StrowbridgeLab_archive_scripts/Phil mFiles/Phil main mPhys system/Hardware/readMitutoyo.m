function currentPosition = readMitutoyo

if ~isappdata(0, 'mitutoyoX')
	% try setting up the communications ports
    if ~ispref('mitutoyo', 'xComm')
		setupMitutoyo;
    end

	try
		xComm = serial(['COM' sprintf('%0.0f', getpref('mitutoyo', 'xComm'))]);
		set(xComm,...
			'baudrate', 9600,...
			'parity', 'none',...
			'databits', 8,...
			'stopbits', 1,...
			'requesttosend', 'on',...
			'dataterminalready', 'on',...
			'timeout', 1,...
			'outputbuffersize', 1024,...
			'inputbuffersize', 512,...
			'terminator', 'CR');
		fopen(xComm)
    catch
        if isempty(xComm) 
            error(['Error with serial port COM' sprintf('%0.0f', getpref('mitutoyo', 'xComm')) ' in setting up mitutoyo X indicator']);
        end
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
			'timeout', 1,...
			'outputbuffersize', 1024,...
			'inputbuffersize', 512,...
			'terminator', 'CR');
		fopen(yComm)
    catch
        if isempty(yComm)        
            error(['Error with serial port COM' sprintf('%0.0f', getpref('mitutoyo', 'yComm')) ' in setting up mitutoyo Y indicator']);
        end
	end		
    while strcmp(get(yComm, 'status'), 'closed')
		pause(0.1)
    end
    setappdata(0, 'mitutoyoX', xComm);
    setappdata(0, 'mitutoyoY', yComm);
    
    if ~ispref('solartron', 'commPort')
        commPort = inputdlg('Enter serial port to which Solartron is connected', 'Comm ', 1, {'3'});
        if isempty(commPort)
            warning('Must set a value for Solartron indicator serial port');
        elseif any(commPort{1} > 57 | commPort{1} < 48)
            warning('Value must be a number')
        else    
            setpref('solartron', 'commPort', commPort);
        end
    end
    
    if ispref('solartron', 'commPort')
        try
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
        catch
            if isempty(zComm)
               error(['Error with serial port COM' sprintf('%0.0f', getpref('solartron', 'commPort')) ' in setting up Solartron indicator']);
            end
        end
    end    
end

% ask for the current position
fprintf(getappdata(0, 'mitutoyoX'), 'R');
currentPosition(1) = str2double(fgetl(getappdata(0, 'mitutoyoX')));
fprintf(getappdata(0, 'mitutoyoY'), 'R');
currentPosition(2) = str2double(fgetl(getappdata(0, 'mitutoyoY')));
if isappdata(0, 'mitutoyoZ')
    fwrite(getappdata(0, 'mitutoyoZ'), char(2));
    currentPosition(3) = str2double(fgetl(getappdata(0, 'mitutoyoZ')));
    if isnan(currentPosition(3))
        pause(.1)
        fwrite(getappdata(0, 'mitutoyoZ'), char(2));
        currentPosition(3) = str2double(fgetl(getappdata(0, 'mitutoyoZ')));   
        if isnan(currentPosition(3))
            pause(.1)
            fwrite(getappdata(0, 'mitutoyoZ'), char(2));
            currentPosition(3) = str2double(fgetl(getappdata(0, 'mitutoyoZ')));   
        end
    end
else
    currentPosition(3) = 0;
end