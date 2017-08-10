function changeAdBoard(figHandle)

% called after the hardware source of the protocolViewer changes

	if nargin < 1
		figHandle = gcf;
	end
	
	handles = get(figHandle, 'userData');
    hwNames = get(handles.source, 'string');
    if isempty(hwNames)
        return
    end
    timerState = get(timerfind('name', 'experimentClock'), 'running');
    stop(timerfind('name', 'experimentClock'));
    
    if isfield(handles, 'channelType') && all(ishandle(handles.channelType))
        delete(handles.channelType);
        delete(handles.channelRange);
        delete(handles.channelExtGain);
        delete(handles.channelName);
    end
    
    oldHardware = getappdata(0, 'adBoard');
    if isstruct(oldHardware) && isfield(oldHardware, 'analogIn')
        delete(oldHardware.analogIn);
        delete(oldHardware.analogOut);
    end
    otherChannels = getpref('amplifiers', 'otherChannels');
    otherChannelFactors = getpref('amplifiers', 'otherChannelFactors');    
    gainNames = getpref('amplifiers', 'gainNames');
    gainScales = getpref('amplifiers', 'gainScales');    
    if ~iscell(hwNames)
        hwNames = {hwNames};
    end
    switch hwNames{get(handles.source, 'value')}
        case 'ITC-18' % itc 18 has 8 analog inputs
			adBoard.numRead = 8;
            adBoard.numWrite = 4;
            if ~ispref('amplifiers', 'amplifiers')
				currentAmps;
				if ~ispref('amplifiers', 'amplifiers')
					error('No amplifiers setup.  See file ''currentAmps.m'' for an example')
				end
            end
			rangeNames = getpref('itc18', 'rangeNames');
			rangeScales = getpref('itc18', 'rangeScales');
            adBoard.minSampleRate = 12;
            adBoard.maxSampleRate = 200000;
            tempTTL = questdlg('Number of TTL lines to use', 'ITC-18 TTLs','4','8','16','4');
            if isempty(tempTTL)
                adBoard.numDig = 4;
            else
                adBoard.numDig = str2double(tempTTL);
            end
            createExpTTL(adBoard.numDig);
            tabData = getappdata(getappdata(0, 'runningProtocol'), 'tabData');
            set(tabData.tabButtons(2), 'enable', 'on');    
            createTTL(getappdata(0, 'runningProtocol'));
            set(timerfind('name', 'experimentClock'), 'TimerFcn', 'experimentTimerITC');
        case 'None' % no hardware present
            set(timerfind('name', 'experimentClock'), 'TimerFcn', 'experimentTimerNoHardware');    
            adBoard.minSampleRate = 0;
            adBoard.maxSampleRate = inf;
            adBoard.numRead = 2;
            adBoard.numWrite = 1;
            rangeNames = {'±1'};
            rangeScales = 1;
            adBoard.numDig = 0;
        otherwise
            hwIds = get(handles.source, 'userData');
            hwDrivers = hwIds{1};
            hwIds = hwIds{2};
            try
                adBoard.analogIn = analoginput(hwDrivers{get(handles.source, 'value')}, hwIds{get(handles.source, 'value')});
            catch
                hwNames = get(handles.source, 'string');
                errorMsg = [hwNames{get(handles.source, 'value')} ' does not support input'];
                set(handles.source, 'value', 1);                
                changeAdBoard(figHandle);
                error(errorMsg);
            end            
            ranges = daqhwinfo(adBoard.analogIn, 'InputRanges');
            adBoard.numRead = daqhwinfo(adBoard.analogIn, 'TotalChannels');
            for i = 1:size(ranges, 1)
                rangeNames{i} = ['±' num2str(ranges(i,2)) ' V'];
            end
            rangeScales = diff(ranges,1,2)./2;
            adBoard.minSampleRate = daqhwinfo(adBoard.analogIn, 'MinSampleRate');
            adBoard.maxSampleRate = daqhwinfo(adBoard.analogIn, 'MaxSampleRate');            
            try
                adBoard.analogOut = analogoutput(hwDrivers{get(handles.source, 'value')}, hwIds{get(handles.source, 'value')});            
            catch
                hwNames = get(handles.source, 'string');
                errorMsg = [hwNames{get(handles.source, 'value')} ' does not support output'];
                set(handles.source, 'value', 1);
                changeADBoard(figHandle);
                error(errorMsg);
            end
            adBoard.numWrite = daqhwinfo(adBoard.analogOut, 'TotalChannels');
            try
                adBoard.digitalIO = digitalio(hwDrivers{get(handles.source, 'value')}, hwIds{get(handles.source, 'value')});    
                adBoard.numDig = daqhwinfo(adBoard.digitalIO, 'TotalLines');
                if adBoard.numDig > 8
                    whichTTLs = inputdlg('Due to slow GUI rendering, using more than 8 TTL is not recommended. If you would like to use only a subset of the TTLs please enter those numbers below using brackets for lists.', 'Set TTLs', 1, {['1:' num2str(adBoard.numDig - 1)]});
                    if ~isempty(whichTTLs)
                        whichTTLs = str2num(whichTTLs);
                        if isempty(whichTTLs)
                            warning('Bad formatting in TTL input. Will use all.')
                        end
                    end      
                end
                if ~exist('whichTTLs', 'var') || isempty(whichTTLs)
                    whichTTLs = 0:adBoard.numDig - 1;
                end
                addline(adBoard.digitalIO, whichTTLs, 'out');
            catch
                adBoard.numDig = 0;
            end
            checkHandles = createExpTTL(adBoard.numDig);   
            tabData = getappdata(getappdata(0, 'runningProtocol'), 'tabData');
            if ~isempty(strfind(adBoard.analogIn.Name, 'nidaq'))
                set(tabData.tabButtons(2), 'enable', 'on');        
                createTTL(getappdata(0, 'runningProtocol'));
                set(timerfind('name', 'experimentClock'), 'TimerFcn', 'experimentTimerRTSI');
            else
                set(checkHandles, 'callback', @updateTTLs);
                set(tabData.tabButtons(2), 'enable', 'off');                  
                set(timerfind('name', 'experimentClock'), 'TimerFcn', 'experimentTimer');              
            end
    end
    adBoard.inputRanges = rangeScales;
    setappdata(0, 'adBoard', adBoard);
    set(handles.channelHolder, 'position', [1 23 71.8 14.864]);		
    for x = adBoard.numRead:-1:1
        uicontrol('unit', 'char', 'style', 'text', 'parent', handles.channelHolder, 'position', [2.6  2 - (x-1) * 1.769 12.2 1.462], 'tag', 'channelName', 'string', ['A/D Chan ' num2str(x-1)]);
        uicontrol('callback', 'saveProtocol; changeRunningChannel;', 'background', [1 1 1], 'unit', 'char', 'style', 'pop', 'parent', handles.channelHolder, 'position', [18.6  2.2 - (x-1) * 1.769 19.8 1.538], 'tag', 'channelType', 'string', otherChannels, 'value', 1, 'userData', otherChannelFactors);
%         setappdata(tempHandle, 'source', ['AD ' sprintf('%1.0f', x - 1) ', ']);
%         setappdata(tempHandle, 'originalScroll', [18.6  13.077 - (x-1) * 1.769 19.8 1.538]);
        uicontrol('callback', 'saveProtocol', 'background', [1 1 1], 'unit', 'char', 'style', 'pop', 'parent', handles.channelHolder, 'position', [40.8  2.2 - (x-1) * 1.769 19.8 1.538], 'tag', 'channelRange', 'string', rangeNames, 'value', numel(rangeScales), 'userData', rangeScales);       
        uicontrol('callback', 'saveProtocol', 'background', [1 1 1], 'unit', 'char', 'style', 'pop', 'parent', handles.channelHolder, 'position', [62.0  2.2 - (x-1) * 1.769 10.0 1.538], 'tag', 'channelExtGain', 'string', gainNames, 'value', 1, 'userData', gainScales);               
    end	    
	set(figHandle, 'userData', guihandles(figHandle));
    saveProtocol;

    % reset all of the amplifier channel selections
    for i = 1:adBoard.numRead
        readChoices{i} = ['A/D ' num2str(i - 1)];
    end
    readChoices{end + 1} = 'None';
    for i = 1:adBoard.numWrite
        writeChoices{i} = ['D/A ' num2str(i - 1)];
    end
    writeChoices{end + 1} = 'None';
    for i = 1:numel(handles.ampType)
        if get(handles.ampCurrent, 'value') > adBoard.numRead + 1
            set(handles.ampCurrent, 'value', adBoard.numRead + 1);
        end
        set(handles.ampCurrent, 'string', readChoices);
        if get(handles.ampVoltage, 'value') > adBoard.numRead + 1
            set(handles.ampVoltage, 'value', adBoard.numRead + 1);
        end
        set(handles.ampVoltage, 'string', readChoices);
        if get(handles.ampTelegraph, 'value') > adBoard.numRead + 1
            set(handles.ampTelegraph, 'value', adBoard.numRead + 1);
        end
        set(handles.ampTelegraph, 'string', readChoices);
        if get(handles.ampStimulus, 'value') > adBoard.numWrite + 1
            set(handles.ampStimulus, 'value', adBoard.numWrite + 1);
        end
        set(handles.ampStimulus, 'string', writeChoices);        
    end
    
    if adBoard.numRead > 14
        set(handles.channelScroll, 'visible', 'on', 'callback', @scrollChannels, 'value', 0, 'min', 0, 'max', adBoard.numRead - 15, 'sliderStep', [1 15] ./ (adBoard.numRead - 15)); 
        scrollChannels(handles.channelScroll);
    else
        set(handles.channelScroll, 'visible', 'off'); 
    end    

    rate = adBoard.minSampleRate;
    acqRates = {};
    while rate < adBoard.maxSampleRate
        acqRates{end + 1} = num2str(rate / 1000);
        rate = rate * 2;
        howManyDigits = floor(log10(rate));
        firstDigit = round((rate/(10^howManyDigits)));
        switch firstDigit
            case 3
                firstDigit = 2;
            case {4, 6, 7}
                firstDigit = 5;
            case {8, 9}
                firstDigit = 1;
                howManyDigits = howManyDigits + 1;
        end
        rate = firstDigit * 10^howManyDigits;
    end
    acqRates{end + 1} = 'Other';
    set(handles.acquisitionRate, 'string', acqRates, 'value', 1);    
    set(handles.timePerPoint, 'string', '200');
    saveProtocol;    
    checkAcquisitionRate;    
	if isfield(handles, 'ampType')
        for i = 1:numel(handles.ampType)
            changeVoltage(i, figHandle);
			changeCurrent(i, figHandle);
			changeTelegraph(i, figHandle);
        end
    end
    
    if strcmp(timerState, 'on')
        start(timerfind('name', 'experimentClock'));
    end
    
    function scrollChannels(varargin)
        kids = get(handles.channelHolder, 'children');
        sliderOffset = get(varargin{1}, 'value');
        set(handles.channelHolder, 'position', [1 21.4 + (adBoard.numRead - 14 - sliderOffset) * 1.769 71.8 14.864]);
        set(kids([1:(adBoard.numRead  - 15 - sliderOffset) * 4 (adBoard.numRead - sliderOffset) * 4 + 1:end]), 'visible', 'off')
        set(kids((adBoard.numRead  - 15 - sliderOffset) * 4 + 1:(adBoard.numRead - sliderOffset) * 4), 'visible', 'on');      
    end    

    function updateTTLs(varargin)
        newVal = 0;
        for j = 1:adBoard.numDig
            newVal = newVal + get(checkHandles(j), 'value') * 2^(j-1);
        end
        putvalue(adBoard.digitalIO, newVal);        
    end
end