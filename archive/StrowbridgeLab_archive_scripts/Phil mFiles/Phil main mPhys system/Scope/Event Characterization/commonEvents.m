function allSpikes = commonEvents(varargin)
persistent windowBounds
persistent sameBounds
    
if nargin == 0
    allSpikes = 'Find Common Events';
    return
end

    if isempty(sameBounds)
		sameBounds = [-2.5 2.5];
    end    
    if isempty(windowBounds)
        windowBounds = [-10 100];
    end    
    handleList = get(gcf, 'userData');
	
	tempData = inputdlg({'Window start (ms)', 'Stop', 'Same start (ms)','Stop (ms)'},'Same Events...',1, {num2str(windowBounds(1)), num2str(windowBounds(2)), num2str(sameBounds(1)), num2str(sameBounds(2))});      
	if numel(tempData) == 0
        return
	end
	windowBounds = [str2double(tempData(1)) str2double(tempData(2))];
    sameBounds = [str2double(tempData(3)) str2double(tempData(4))];
    
    if handleList.axesCount > 2
        error('Only valid for two axes')
    end
    
    if gca == handleList.axes(1)
        fromAxis = 2;
        toAxis = 1;
    else
        fromAxis = 1;
        toAxis = 2;
    end
    
    fromEvents = getappdata(handleList.axes(fromAxis), 'events');
    toEvents = getappdata(handleList.axes(toAxis), 'events');  
    kids = get(handleList.axes, 'children');   
    if ~iscell(kids)
        kids = {kids};
    end
    for index = 1:numel(kids)
        kids{index} = kids{index}(strcmp(get(kids{index}, 'userData'), 'data'));
        for j = 1:numel(kids{index})
            kidTraces{index}{j} = get(kids{index}(j), 'displayName');
        end
    end    
    outData = {nan(round(diff(windowBounds) / handleList.xStep(get(handleList.channelControl(fromAxis).channel, 'value'))) + 1, 1000)...
        nan(round(diff(windowBounds) / handleList.xStep(get(handleList.channelControl(toAxis).channel, 'value'))) + 1, 1000)};
    dataIndex = 1;
    xData = {(windowBounds(1) / handleList.xStep(get(handleList.channelControl(fromAxis).channel, 'value')):windowBounds(2) / handleList.xStep(get(handleList.channelControl(1).channel, 'value')))...
        (windowBounds(1) / handleList.xStep(get(handleList.channelControl(fromAxis).channel, 'value')):windowBounds(2) / handleList.xStep(get(handleList.channelControl(1).channel, 'value')))};
    allCoincidents = [];
    allSpikes = [];
    for i = 1:numel(toEvents)
        for j = find(strcmp(toEvents(i).traceName, {fromEvents.traceName}))
            dataStruct = zeros(2, max([length(fromEvents(j).data) length(toEvents(i).data)]));
            dataStruct(1, 1:length(fromEvents(j).data)) = fromEvents(j).data;
            dataStruct(2, 1:length(toEvents(i).data)) = toEvents(i).data;
            [spikeTimes title coincidentEvents] = crossCorr(dataStruct', sameBounds, sameBounds);
            allSpikes = [allSpikes spikeTimes];
            allCoincidents = [allCoincidents coincidentEvents];
            if ~isempty(coincidentEvents) && ~nargout
                fromData = get(kids{fromAxis}(strcmp(fromEvents(j).traceName, kidTraces{fromAxis})), 'yData');
                toData = get(kids{toAxis}(strcmp(fromEvents(j).traceName, kidTraces{toAxis})), 'yData');
                for k = 1:numel(coincidentEvents)
                    outData{1}(:, dataIndex) = fromData(round(coincidentEvents(k) / handleList.xStep(get(handleList.channelControl(fromAxis).channel, 'value'))) + xData{fromAxis})';
                    outData{2}(:, dataIndex) = toData(round(coincidentEvents(k) / handleList.xStep(get(handleList.channelControl(toAxis).channel, 'value'))) + xData{toAxis})';
                    
                    dataIndex = dataIndex + 1;
                end
            end
        end          
    end
    fromEvents(end + 1).data = sort(allCoincidents);
    fromEvents(end).traceName = 'All';
    fromEvents(end).type = 'Coincident Events';
    setappdata(handleList.axes(fromAxis), 'events', fromEvents);
    showEvents(handleList.axes(fromAxis));
    possibleChannels = get(handleList.channelControl(fromAxis).channel, 'string');
    if ~nargout
        newScope({outData{1}(:, 1:dataIndex - 1), outData{2}(:, 1:dataIndex - 1)}, [windowBounds(1) handleList.xStep(get(handleList.channelControl(fromAxis).channel, 'value')) windowBounds(2); windowBounds(1) handleList.xStep(get(handleList.channelControl(toAxis).channel, 'value')) windowBounds(2)], {possibleChannels{get(handleList.channelControl(fromAxis).channel, 'value')}, possibleChannels{get(handleList.channelControl(toAxis).channel, 'value')}}); 
    end