function zImage = takeTwoPhotonNI(fileName, scanPoints, beamOnPoints, pixelUs, returnScanPosition, triggeredAcquisition, focus)
persistent hDaqTools
persistent hAO
persistent hAI
persistent hDIO
persistent ljHandle

zImage = [];

    if isempty(hDIO)
        if isappdata(0, 'rasterHandles')
            % for if persistent variables were cleared
            rasterHandles = getappdata(0, 'rasterHandles');
            hDaqTools = rasterHandles{1};
            hAO = rasterHandles{2};
            hAI = rasterHandles{3};
            hDIO = rasterHandles{4};
            ljHandle = rasterHandles{5};
            
        else
            rasterScanFigure = getappdata(0, 'rasterScan');

        % setup the ni board
            hDaqTools = actxcontrol('CWDAQControlslib.CWDaqTools.1', 'parent', rasterScanFigure, 'position', [1 1 1 1]);
            hAO = actxcontrol('CWDAQControlslib.CWAO.1', 'parent', rasterScanFigure, 'position', [1 1 1 1], 'callback', {'DAQError', @shareError; 'DAQWarning', @shareError});
            hAI = actxcontrol('CWDAQControlslib.CWAI.1', 'parent', rasterScanFigure, 'position', [1 1 1 1], 'callback', {'AcquiredData', @dataIn; 'DAQError', @shareError; 'DAQWarning', @shareError});
%             hDIO = actxcontrol('CWDAQControlslib.CWDIO.1', 'parent', rasterScanFigure, 'position', [1 1 1 1], 'callback', {'DAQError', @shareError; 'DAQWarning', @shareError});
            warning('off', 'daq:digitalio:adaptorobsolete');             
            hDIO = digitalio('nidaq', 1);
            addline(hDIO, [0 1], 'Out');

        % setup the labjack U12
            if ~libisloaded('ljackuw')
                fileInfo = dir([getenv('systemroot') filesep 'system32' filesep 'ljackuw.dll']);
                if isempty(fileInfo) || fileInfo.datenum < 733100
                    error('Incompatible or absent ljackuw.dll file.  Please download U12 drivers from the Labjack website');
                end
                loadlibrary('ljackuw','ljackuw_Mat.h');
        %         updateLabJack;
            end

        % setup the labjack UE9
%             if ~(libisloaded('labjackud') || libisloaded('labjackud_doublePtr'))
%                 fileInfo = dir([getenv('systemroot') filesep 'system32' filesep 'labjackud.dll']);
%                 if isempty(fileInfo) || fileInfo.datenum < 733480
%                     error('Incompatible or absent labjackud.dll file.  Please download UE9 drivers from the Labjack website');
%                 end
%                 if exist([getenv('systemdrive') '\progra~1\LabJack\drivers\labjackud.h'], 'file') ~= 2
%                     error('Absent header file for labjack UE9 drivers.  Please download UE9 drivers from the Labjack website');
%                 end                                
%                 loadlibrary('labjackud','C:\progra~1\LabJack\drivers\labjackud.h');
%                 loadlibrary('labjackud', 'labjackud_doublePtr.h', 'alias', 'labjackud_doublePtr');
%             end
%             [Error ljHandle] = ljud_OpenLabJack(9,2,'129.22.192.127',0); % Returns ljHandle for open LabJack
%             if Error ~=0
%                 % abort
%                 close(rasterScan);
%             end
%             Error_Message(Error) % Check for and display any Errors    
%             Error_Message(ljud_eGet(ljHandle, 1000, 2000, 12, 0));
%             Error_Message(ljud_eGet(ljHandle, 2000, 0, 105, 0));     

            % close the shutter
                putvalue(hDIO, 0);
%                 Error_Message(ljud_eGet(ljHandle, 40, 0, 1, 0));

%             % steer the beam in this direction
%               Error_Message(ljud_eGet(ljHandle, 40, 2, bitget(getpref('twoPhoton','chanNum'), 1), 0));
%               Error_Message(ljud_eGet(ljHandle, 40, 3, bitget(getpref('twoPhoton','chanNum'), 2), 0));      

              setappdata(0, 'rasterHandles', {hDaqTools, hAO, hAI, hDIO, ljHandle});
        end
    end

    if nargin < 1
        return % just asked for setup
    end
    
    if nargin < 5
        returnScanPosition = false;
    end

    if nargin < 6
        triggeredAcquisition = false;
    end
    
    if nargin < 7
        focus = false;
    end

    % pad the DA to make sure we get enough AD
    scanPoints = scanPoints([1:end end * ones(1, round(150 / pixelUs))], :);
    
    if nargin > 0
        % truncate the points to the limits of the AD board
        if any(any(abs(scanPoints) > 12))
            switch questdlg(['At the current pixel duration of ' sprintf('%0.1f', pixelUs) ' ' char(181) 's the scan requires voltage deviations of ' sprintf('%0.1f', max(max(abs(scanPoints)))) ' volts, exceeding those allowed by the AD board (10 volts).  Would you like to use a truncated version or abort the scan to adjust the pixel duration?'], 'Too Fast', 'Truncate', 'Abort', 'Truncate')
                case 'Truncate'
                    scanPoints(scanPoints > 9.996) = 9.996;
                    scanPoints(scanPoints < -9.996) = -9.996;
                otherwise
                    error('Scan width too large')
            end
        end        
        
        if ~returnScanPosition
            % set PMT
                driveVoltage = 2 - 2 * str2double(get(findobj(getappdata(0, 'rasterScan'), 'tag', 'txtLaserIntensity'), 'string')) / 100;                
                if calllib('ljackuw', 'EAnalogOut', 0, 0, get(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtGain1'),'value') * 0.9, driveVoltage) ~=0
                    error('Error sending PMT gain settting to lab jack');
                end

            % handle UE9 calls
                % set pockel cell        
%                 driveVoltage = 51.0088 - 19.83726 * log((-1.09451 + str2double(get(findobj('tag', 'txtLaserIntensity'), 'string')) / 100) / (-0.09641 - str2double(get(findobj('tag', 'txtLaserIntensity'), 'string')) / 10000));
%                 driveVoltage = str2double(get(findobj('tag', 'txtLaserIntensity'), 'string')) / 100;                
%                 Error_Message(ljud_eGet(ljHandle, 20, 0, driveVoltage, 0));

                % check to see if the beam is ours or if it is in use
%                 [lngError valueCode] = ljud_eGet(ljHandle, 30, 8, 0, 0);                
%                 if ~valueCode % Uniblitz controller is TTL high when shutter closed
%                     error('Shutter manually open'); 
%                 end 
                
%                 [lngError valueCode] = ljud_eGet(ljHandle, 37, 0, 0, 8);
%                 if lngError ~= 0
%                     Error_Message(lngError);
%                 end

                % check whether shutter is open
%                 if ~bitget(valueCode, 1)
%                     error('Shutter already requested open'); 
%                 end  

                % determine which setup is selected
%                 switch bitand(valueCode, 12)
%                     case 0
%                         currentChannel = 0; % two photon A
%                     case 4
%                         currentChannel = 1; % two photon B
%                     case 8
%                         currentChannel = 2; % DIC4
%                     case 12
%                         currentChannel = 3; % DIC2
%                     otherwise
%                         error('Unknown setup selected');
%                 end

%                 if currentChannel ~= getpref('twoPhoton', 'chanNum')
%                     % determine lockout status
%                     switch bitand(valueCode, 2)
%                         case 0
%                             % beam not in use so get it
%                             Error_Message(ljud_eGet(ljHandle, 40, 2, bitget(getpref('twoPhoton','chanNum'), 1), 0));
%                             Error_Message(ljud_eGet(ljHandle, 40, 3, bitget(getpref('twoPhoton','chanNum'), 2), 0)); 
% 
%                             % recurr into this function once new setup selected
%                             zImage = takeTwoPhotonNI(fileName, scanPoints, beamOnPoints, pixelUs, returnScanPosition, triggeredAcquisition);
%                             return
%                         case 2
%                             disp('Beam currently in use. Please wait');
%                             return % beam in use so just cancel
%                         otherwise
%                             error('Unknown lockout code');
%                     end         
%                 end
        end % ~ returnScanPosition
        
        % set NI board
        gainValues = [10 5 2 1 0.5 0.2];

        hAI.Reset;
        hAO.Reset;
        hDaqTools.RouteSignal(hAI.Device, 3, 4);
        if triggeredAcquisition
            set(hAI.StartCondition, 'Type', 1);
            set(hAI.StartCondition, 'Mode', 1);
        else
            set(hAI.StartCondition, 'Type', 0);
        end
        invoke(hAI.Channels, 'RemoveAll');
        if returnScanPosition
            invoke(hAI.Channels, 'Add', '0', 2, -2);
            invoke(hAI.Channels, 'Add', '1', 2, -2);            
        else
            invoke(hAI.Channels, 'Add', '0', gainValues(get(findobj('tag', 'pmtAD1'), 'value')), -gainValues(get(findobj('tag', 'pmtAD1'), 'value')));
            invoke(hAI.Channels, 'Add', '1', gainValues(get(findobj('tag', 'pmtAD2'), 'value')), -gainValues(get(findobj('tag', 'pmtAD2'), 'value')));            
        end
        invoke(hAI, 'NScans', length(scanPoints));
        invoke(hAI, 'NScansPerBuffer', length(scanPoints));
        invoke(hAI, 'UseDefaultBufferSize', 0);
        invoke(hAI.ScanClock, 'InternalClockMode', 1);
        invoke(hAI.ScanClock, 'ClockSourceType', 1);
%         invoke(invoke(hAI, 'ScanClock'), 'Period', pixelUs / 1000000); % in sec  
        invoke(hAI.ScanClock, 'Period', pixelUs / 1000000); % in sec          
        invoke(hAI, 'ReturnDataType', 2);
        hAI.Configure;

        invoke(hAO.UpdateClock, 'ClockSourceType', 8);
        invoke(hAO.UpdateClock, 'ClockSourceSignal', '2');
        invoke(hAO, 'AllocationMode', 3);
        invoke(hAO, 'NIterations', 1);
        invoke(hAO, 'Infinite', 0);
        invoke(hAO, 'NUpdates', length(scanPoints));
        invoke(hAO.Channels, 'RemoveAll');
        invoke(hAO.Channels, 'Add', '0,1');
        hAO.Configure;

        % i think that this can be replaced by a call to Dig_Prt_Config in:
%         loadlibrary('nidaq32.dll', 'C:\Program Files\National Instruments\NI-DAQ\Include\nidaq.h')
%         invoke(hDIO.Channels, 'RemoveAll');  
%         invoke(hDIO.Channels, 'Add', '0');
%         .Ports(0).Assignment = 2; % set as an output 
%         invoke(invoke(hDIO.Ports, 'Item', 1), 'Assignment', 2);
%         hDIO.SingleWrite(returnScanPosition); % this appears to always be high and not be set by this command

        putvalue(hDIO, returnScanPosition);
        
%         if ~triggeredAcquisition
%             % lockout beam control
%             Error_Message(ljud_eGet(ljHandle, 40, 1, 1, 0));    
%         end
            
        if ~returnScanPosition              
            % open the shutter
                putvalue(hDIO, 2);
%             Error_Message(ljud_eGet(ljHandle, 40, 0, 0, 0));
            pause(0.005); % let the shutter open
        end
        
        % transfer data to subfunction
        setappdata(getappdata(0, 'rasterScan'), 'returnScanPosition', returnScanPosition);
        setappdata(getappdata(0, 'rasterScan'), 'triggeredAcquisition', triggeredAcquisition);
        setappdata(getappdata(0, 'rasterScan'), 'scanPoints', scanPoints);
        setappdata(getappdata(0, 'rasterScan'), 'pixelUs', pixelUs);
        setappdata(getappdata(0, 'rasterScan'), 'focusing', isstruct(focus));
        
        % let everyone know that we are scanning
        set(getappdata(0, 'rasterScan'), 'name', 'Raster Scan -- Scanning');  

        % load the analog out
        hAO.Write(reshape(scanPoints', [], 1));
        hAO.Start;
        hAI.Start;

        % return if triggered acquisition (or the board will never be
        % triggered)
        if triggeredAcquisition
            return
        end
        
        % wait for the image to finish
        waitfor(getappdata(0, 'rasterScan'), 'name');

        % retransfer data from subfunction
        zImage = getappdata(getappdata(0, 'rasterScan'), 'zImage');
        
        if nargin == 7
            zImage.info = focus.header;
            tic
            numFrames = 0;
            while strcmp(get(findobj('tag', 'cmdFocus'), 'string'), 'Stop')
                % let everyone know that we are scanning
                set(getappdata(0, 'rasterScan'), 'name', 'Raster Scan -- Scanning');  
                setappdata(getappdata(0, 'rasterScan'), 'focusing', 1);

                hAI.Reset;
%                 hAO.Reset;
                set(hAI.StartCondition, 'Type', 0);
                invoke(hAI.Channels, 'RemoveAll');
                invoke(hAI.Channels, 'Add', '0', gainValues(get(findobj('tag', 'pmtAD1'), 'value')), -gainValues(get(findobj('tag', 'pmtAD1'), 'value')));
                invoke(hAI.Channels, 'Add', '1', gainValues(get(findobj('tag', 'pmtAD2'), 'value')), -gainValues(get(findobj('tag', 'pmtAD2'), 'value')));            
                invoke(hAI, 'NScans', length(scanPoints));
                invoke(hAI, 'NScansPerBuffer', length(scanPoints));
                invoke(hAI, 'UseDefaultBufferSize', 0);
                invoke(hAI.ScanClock, 'InternalClockMode', 1);
                invoke(hAI.ScanClock, 'ClockSourceType', 1);
                invoke(invoke(hAI, 'ScanClock'), 'Period', pixelUs / 1000000); % in sec  
                invoke(hAI, 'ReturnDataType', 2);
                hAI.Configure;

%                 invoke(hAO.UpdateClock, 'ClockSourceType', 8);
%                 invoke(hAO.UpdateClock, 'ClockSourceSignal', '2');
%                 invoke(hAO, 'AllocationMode', 3);
%                 invoke(hAO, 'NIterations', 1);
%                 invoke(hAO, 'Infinite', 0);
%                 invoke(hAO, 'NUpdates', length(scanPoints));
%                 invoke(hAO.Channels, 'RemoveAll');
%                 invoke(hAO.Channels, 'Add', '0,1');
                hAO.Configure;
                
                % load the analog out
                hAO.Write(reshape(scanPoints', [], 1));
                hAO.Start;
                hAI.Start;

                % wait for the image to finish
                waitfor(getappdata(0, 'rasterScan'), 'name');

                % retransfer data from subfunction
                tempImage = getappdata(getappdata(0, 'rasterScan'), 'zImage');

                % correct for lags
                zImage.stack = reshape(circshift(tempImage.photometry(:,1), [-round(focus.lagX) 0]), [], focus.pixelsY);

                % trim off the turn arounds
                zImage.stack = zImage.stack(focus.turnLength + 1:end, :);

                % flip the return lines of the x dimension
                zImage.stack(:, 1:2:end) = zImage.stack(end:-1:1, 1:2:end);  
                
                % display the image
                imageBrowser(zImage);
                numFrames = numFrames + 1;
            end
            disp([num2str(numFrames / toc) ' frames per second'])
            % close the shutter
                putvalue(hDIO, 0);
%             Error_Message(ljud_eGet(ljHandle, 40, 0, 1, 0)); 

%             % unlock beam control
%             Error_Message(ljud_eGet(ljHandle, 40, 1, 0, 0));                     
        end
    end

    function dataIn(varargin)
        returnScanPosition = getappdata(getappdata(0, 'rasterScan'), 'returnScanPosition');
        triggeredAcquisition = getappdata(getappdata(0, 'rasterScan'), 'triggeredAcquisition');    
        scanPoints = getappdata(getappdata(0, 'rasterScan'), 'scanPoints');        
        focusing = getappdata(getappdata(0, 'rasterScan'), 'focusing');
        
        if ~focusing
            if ~returnScanPosition
                % close the shutter
                putvalue(hDIO, 0);
%                 Error_Message(ljud_eGet(ljHandle, 40, 0, 1, 0)); 
            end

%             if ~triggeredAcquisition
%                 % unlock beam control
%                 Error_Message(ljud_eGet(ljHandle, 40, 1, 0, 0));     
%             end
        end
        
        if ~returnScanPosition
            if ~focusing
                zImage.info = struct( 'Filename', '','ProgramNumber',(3),'ProgramMode',(0),'DataOffset',(0),'Width',(0),...
                    'Height',(0),'NumImages',(0),'NumChannels',(0),'Comment','', 'MiscInfo','',...
                    'ImageSource','','PixelMicrons',(0), 'MillisecondPerFrame',(0),'Objective','',...
                    'AdditionalMagnification','', 'SizeOnSource','','SourceProcessing','','AdditionalInformation','');

                % write location information into the header
                if ispref('mitutoyo', 'xComm')
                    % read the coordinates from there
                    currentPosition = readMitutoyo;
                elseif ispref('ASI', 'commPort')
                    currentPosition = readASI;
                else
                    currentPosition = [0 0 0];
                end
                objectiveOrigins = getpref('objectives', 'origins');
                objectiveDeltas = getpref('objectives', 'deltas');
                objectiveIndex = get(findobj('tag', 'objectiveName'), 'value');
                if objectiveIndex > numel(objectiveDeltas)
                    objectiveIndex = numel(objectiveDeltas);
                    warning('Bad objective calibration');
                end
                zImage.info.origin = [objectiveOrigins(objectiveIndex, :) + currentPosition(1:2) .* getpref('objectives', 'micronPerMit') + [str2double(get(findobj('tag', 'centerX'),'string')) str2double(get(findobj('tag', 'centerY'),'string')) ] .* (objectiveDeltas(objectiveIndex) * [1 1]) currentPosition(3)];
        %         zImage.info.MiscInfo = [zImage.info.MiscInfo sprintf(', X = %g, Y = %g, Z = %g', [zImage.info.origin currentPosition(3)])];

                if numel(currentPosition) > 2
                    zImage.info.origin(3) = currentPosition(3);
                end
            end

            zImage.photometry = varargin{4}(:,round(150 / getappdata(getappdata(0, 'rasterScan'), 'pixelUs')) + 1:end)';
        else
            zImage.photometry = double(varargin{4}(:,round(150 / getappdata(getappdata(0, 'rasterScan'), 'pixelUs')) + 1:end)') .* 4 .* repmat([0.0016749 0.0016734], size(scanPoints, 1) - round(150 / getappdata(getappdata(0, 'rasterScan'), 'pixelUs')), 1) + repmat([0.0072195 0.0035648], size(scanPoints, 1) - round(150 / getappdata(getappdata(0, 'rasterScan'), 'pixelUs')), 1); % positions saturate at +/- 3.423
        end        
        
        % let everyone know that we are done scanning
        setappdata(getappdata(0, 'rasterScan'), 'zImage', zImage);
        set(getappdata(0, 'rasterScan'), 'name', 'Raster Scan');       
    end

    function shareError(varargin)
        error([varargin{7} ' error: ' varargin{5}]);
    end
end