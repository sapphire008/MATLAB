function startRunningScope

stop(timerfind('name', 'experimentClock'))
if ~isappdata(0, 'runningScope')
	% set the pref if not present
	if ~ispref('locations', 'runningScope')
		setpref('locations', 'runningScope', [321 3 319 22]);
	end
	
	% starts a running scope of the current channels
	protocolData = getappdata(0, 'currentProtocol');

	samplingRate = 1000000 / protocolData.timePerPoint;
	numSeconds = 5;
    for i = 1:numel(changeRunningChannel)
        yData{i} = nan(1000000 * numSeconds / protocolData.timePerPoint, 1);
    end
	handles = newScope(yData, (protocolData.timePerPoint / 1000:protocolData.timePerPoint / 1000:1000 * numSeconds)');
	
	yData = nan(numSeconds * samplingRate, 1);
	set(handles.axes, 'xlim', [0 numSeconds * 1000],...
		'ylimmode', 'auto',...
		'drawmode', 'fast',...
		'color', [0 0 0]);

    for i = handles.axes
        kids = get(i, 'children');
        set(kids(end - 2), 'ydata', yData, 'color', [0 .8 0], 'erasemode', 'normal');
        set(kids(end), 'color', [1 1 0]);
    end

	% set gui properties
	handles.isRunning = uicontrol('style', 'check',...
		'parent', handles.timeControl.frame,...
		'string', 'Run',...
		'value', 0,...
		'units', 'normalized',...
		'position', [0.45 0.05 0.2 0.3],...
        'userData', 0,...
		'callback', @changeRunning);

	handles.windowTime = uicontrol('style', 'edit',...
		'parent', handles.timeControl.frame,...
		'string', num2str(numSeconds),...
		'units', 'normalized',...
		'position', [.7 0.05 0.1 0.3],...
		'callback', @changeWindowTime);

	uicontrol('style', 'text',...
		'parent', handles.timeControl.frame,...
		'horizontal', 'left',...
		'string', 'sec',...
		'units', 'normalized',...
		'position', [.8 .04 0.2 0.3]);

	set([handles.channelControl.channel], 'callback', @changeRunningChannel);

	set(gcf, 'closerequestfcn', @closeMe);

	set(gcf, 'userData', handles);
	setappdata(0, 'runningScope', gcf);
	set(gcf, 'position', getpref('locations', 'runningScope'));	
	changeRunningChannel;
else
	figure(getappdata(0, 'runningScope'));
end

onScreen(gcf);
start(timerfind('name', 'experimentClock'))
    
function changeRunning(varargin)
    persistent callbackHandles
    
    handles = get(gcf, 'userData');
	if get(handles.isRunning, 'value')
        callbackHandles = get(gcf, {'windowbuttondownfcn', 'windowbuttonmotionfcn', 'windowbuttonupfcn'});
        set(gcf, {'windowbuttondownfcn', 'windowbuttonmotionfcn', 'windowbuttonupfcn'}, {'', '', ''});
        for i = 1:handles.axesCount
            kids = get(handles.axes(i), 'children');
            set(kids(end - 1:end), 'visible', 'off');
        end
        set([handles.channelControl.channel], 'enable', 'off');        
    else
        try
            set(gcf, {'windowbuttondownfcn', 'windowbuttonmotionfcn', 'windowbuttonupfcn'}, callbackHandles);   
        catch
            % gets here once in an unreliable while
        end
        for i = 1:handles.axesCount
            kids = get(handles.axes(i), 'children');
            set(kids(end), 'visible', 'on');
        end        
        set([handles.channelControl.channel], 'enable', 'on');
        set(handles.isRunning, 'userData', 1);
        handles.markerFixed = 0;
        set(gcf, 'userData', handles);
	end
	
function changeWindowTime(varargin)
	handles = get(gcf, 'userData');
	timeWindow = str2double(get(handles.windowTime, 'string'));
	if ~isnan(timeWindow)
		if timeWindow < 1
			msgbox('Time window must be at least 1 second');
			return
		end
		set(handles.axes, 'xlim', [0 timeWindow * 1000]);
		setAxisLabels(handles.axes(1));
		if timeWindow * 1000 >= handles.maxX(1)
			spareData = nan(1, (1000 * timeWindow - handles.maxX(1)) / handles.xStep(1));
			for i = 1:handles.axesCount
				kids = get(handles.axes(i), 'children');
				set(kids(end - 2), 'yData', [spareData get(kids(end - 2), 'yData')], 'xData', 0:handles.xStep(1):timeWindow * 1000 - handles.xStep(1));
			end
		else
			for i = 1:handles.axesCount
				kids = get(handles.axes(i), 'children');				
				yData = get(kids(end - 2), 'yData');
				set(kids(end - 2), 'yData', yData((handles.maxX(1) - timeWindow * 1000) / handles.xStep(1) + 1:end), 'xData', 0:handles.xStep(1):timeWindow * 1000 - handles.xStep(1));
			end			
		end
		handles.maxX = zeros(numel(get(handles.channelControl(1).channel, 'string')), 1) + timeWindow .* 1000;
		set(gcf, 'userData', handles);
	end
    
function closeMe(varargin)
	setpref('locations', 'runningScope', get(gcf, 'position'));
    if isappdata(0, 'runningScope')
        rmappdata(0, 'runningScope');
    end
    delete(varargin{1});