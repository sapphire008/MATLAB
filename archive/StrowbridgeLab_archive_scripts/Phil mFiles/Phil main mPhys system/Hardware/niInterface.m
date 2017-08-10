function niInterface(scanPoints, pixelUs, returnScanPosition, triggeredAcquisition)
persistent hDaqTools
persistent hAO
persistent hAI
persistent hDIO

    if ~isappdata(0, 'niInterface')
        figHandle = figure('visible', 'off', 'tag', 'niInterface');
        hDaqTools = actxcontrol('CWDAQControlslib.CWDaqTools.1');
        hAO = actxcontrol('CWDAQControlslib.CWAO.1', 'callback', {'DAQError', @shareError; 'DAQWarning', @shareError});
        hAI = actxcontrol('CWDAQControlslib.CWAI.1', 'callback', {'AcquiredData', @dataIn; 'DAQError', @shareError; 'DAQWarning', @shareError});
        hDIO = actxcontrol('CWDAQControlslib.CWDIO.1', 'callback', {'DAQError', @shareError; 'DAQWarning', @shareError});

        setappdata(0, 'niInterface', figHandle);
        set(figHandle, 'userData', [hDaqTools hAO hAI hDIO]);
    end

    if nargin > 0
        temp = get(getappdata(0, 'niInterface'), 'userData');
        hDaqTools = temp(1);
        hAO = temp(2);
        hAI = temp(3);
        hDIO = temp(4);

        gainValue = 10; % one of [0.5 1 2 5 10]

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
            invoke(hAI.Channels, 'Add', '0', gainValue, -gainValue);
            invoke(hAI.Channels, 'Add', '1', gainValue, -gainValue);            
        end
        invoke(hAI, 'NScans', length(scanPoints));
        invoke(hAI, 'NScansPerBuffer', length(scanPoints));
        invoke(hAI, 'UseDefaultBufferSize', 0);
        invoke(hAI.ScanClock, 'InternalClockMode', 1);
        invoke(hAI.ScanClock, 'ClockSourceType', 1);
        invoke(invoke(hAI, 'ScanClock'), 'Period', pixelUs / 1000000); % in sec  
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
        
        invoke(hDIO.Channels, 'RemoveAll');  
        invoke(hDIO.Channels, 'Add', '0');
        hDIO.SingleWrite(returnScanPosition); 
        
        setappdata(getappdata(0, 'niInterface'), 'pixelUs', pixelUs);
        
        % load the analog out
        hAO.Write(scanPoints(:));
        hAO.Start;
        hAI.Start;
    end

function dataIn(varargin)
    newScope({varargin{4}(1,:), varargin{4}(2,:)}, (1:size(varargin{4}, 2)) * (getappdata(getappdata(0, 'niInterface'), 'pixelUs') / 1000));

function shareError(varargin)
    error([varargin{7} ' error: ' varargin{5}]);