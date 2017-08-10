function outText = plotPercentCorrelation(varargin)
persistent filterLength
persistent sameBounds
if ~nargin
    outText = 'Plot Percent Correlation';
    return
end

    if isempty(sameBounds)
		sameBounds = [-2.5 2.5];
    end     	
	tempData = inputdlg({'Same start (ms)','Stop (ms)'},'Same Events...',1, {num2str(sameBounds(1)), num2str(sameBounds(2))});      
    if numel(tempData) == 0
        return
    end
    sameBounds = [str2double(tempData(1)) str2double(tempData(2))];
    analysisAxis('eventFreqPlot', varargin{4});
    
    handles = get(gcf, 'userData');
    whichAxis = find(handles.axes == gca);
    whichData = get(handles.channelControl(whichAxis).channel, 'value');
    
    % get handles to the event traces
    fromEvents = getappdata(handles.axes(1), 'events');
    toEvents = getappdata(handles.axes(2), 'events');  
    events = [fromEvents toEvents];
    
    % plot the frequency data
	xData = handles.minX(whichData):handles.xStep(whichData):handles.maxX(whichData);    
    if isempty(filterLength)
        % suggest a window that has, on average, 5 events in it
    	filterLength = round(length(xData) / length(events(1).data) * handles.xStep(whichData) * 2.5) * 2;
        howManyDigits = floor(log10(filterLength));
        filterLength = round(filterLength / 10^howManyDigits) * 10^howManyDigits;
    end
    tempData = inputdlg({'Boxcar length (msec)'},'Plot Freq...',1, {num2str(filterLength)});      
    if numel(tempData) == 0
        return
    end
    filterLength = round(str2double(tempData) / handles.xStep(whichData));
    if filterLength > size(xData, 2)
        filterLength = size(xData, 2);
    end
    yData = zeros(numel(events), size(xData, 2));    
    allCoincidents = [];
    
    kids = get(handles.axes, 'children');   
    if ~iscell(kids)
        kids = {kids};
    end
    for index = 1:numel(kids)
        kids{index} = kids{index}(strcmp(get(kids{index}, 'userData'), 'data'));
        for j = 1:numel(kids{index})
            kidTraces{index}{j} = get(kids{index}(j), 'displayName');
        end
    end    
    
    for i = 1:numel(fromEvents)
        if numel(fromEvents(i).data) > 1
            % this is simply a boxcar filter, but implemented using the
            % filter command it took 100x longer
            changeData = ones(1, 2 * numel(fromEvents(i).data));
            changeData(end/2 + 1:end) = -1;
            whereData = [round((fromEvents(i).data) / handles.xStep(whichData) - filterLength / 2) round((fromEvents(i).data) / handles.xStep(whichData)) + filterLength / 2 + 1];
            [whereData indices] = sort(whereData);           
            lastSum = sum(whereData <= 0);
            yData(i, 1:whereData(lastSum + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
            for j = lastSum + 1:min([find(whereData < length(yData), 1, 'last') - 1 size(whereData, 2) - 1]);
                lastSum = lastSum + changeData(indices(j));
                yData(i, whereData(j):whereData(j + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
            end
        end
        if numel(toEvents(i).data) > 1
            % this is simply a boxcar filter, but implemented using the
            % filter command it took 100x longer
            changeData = ones(1, 2 * numel(toEvents(i).data));
            changeData(end/2 + 1:end) = -1;
            whereData = [round((toEvents(i).data) / handles.xStep(whichData) - filterLength / 2) round((toEvents(i).data) / handles.xStep(whichData)) + filterLength / 2 + 1];
            [whereData indices] = sort(whereData);           
            lastSum = sum(whereData <= 0);
            yData(i, 1:whereData(lastSum + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
            for j = lastSum + 1:min([find(whereData < length(yData), 1, 'last') - 1 size(whereData, 2) - 1]);
                lastSum = lastSum + changeData(indices(j));
                yData(i, whereData(j):whereData(j + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
            end
        end
        dataStruct = zeros(2, max([length(fromEvents(i).data) length(toEvents(i).data)]));
        dataStruct(1, 1:length(fromEvents(i).data)) = fromEvents(i).data;
        dataStruct(2, 1:length(toEvents(i).data)) = toEvents(i).data;
        [spikeTimes title coincidentEvents] = crossCorr(dataStruct', sameBounds, sameBounds);
        allCoincidents = [allCoincidents coincidentEvents];
    end

    changeData = ones(1, 2 * numel(allCoincidents));
    changeData(end/2 + 1:end) = -1;
    whereData = [round((allCoincidents) / handles.xStep(whichData) - filterLength / 2) round((allCoincidents) / handles.xStep(whichData)) + filterLength / 2 + 1];
    [whereData indices] = sort(whereData);           
    lastSum = sum(whereData <= 0);
    zData = zeros(1, size(xData, 2));    
    zData(1:whereData(lastSum + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
    for j = lastSum + 1:min([find(whereData < length(yData), 1, 'last') - 1 size(whereData, 2) - 1]);
        lastSum = lastSum + changeData(indices(j));
        zData(whereData(j):whereData(j + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
    end
    line(xData, zData./mean(yData, 1), 'color', [0 0 0], 'linewidth', 1, 'parent', handles.analysisAxis{whichAxis}.eventFreqPlot);             
    
    newScope({[mean(yData); zData], zData./mean(yData, 1)}, xData);
    ylabel(handles.analysisAxis{whichAxis}.eventFreqPlot, '%');
    
    set(handles.analysisAxis{whichAxis}.eventFreqPlot, 'ylim', [0 3 * max(get(handles.analysisAxis{whichAxis}.eventFreqPlot, 'ylim'))]);
    filterLength = filterLength * handles.xStep(whichData);    