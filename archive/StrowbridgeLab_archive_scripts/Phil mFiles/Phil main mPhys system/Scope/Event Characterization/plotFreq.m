function outText = plotFreq(varargin)
persistent filterLength
if ~nargin
    outText = 'Plot Frequency';
    return
end

    analysisAxis('eventFreqPlot', varargin{4});
    
    handles = get(gcf, 'userData');
    whichAxis = find(handles.axes == varargin{4});
    whichData = get(handles.channelControl(whichAxis).channel, 'value');
    
    % get handles to the event traces
    events = getappdata(gca, 'events');
    
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
    if numel(events(varargin{5}).data) > 1
        % unsmoothed
        yData = zeros(size(xData));
        % this is simply a boxcar filter, but implemented using the
        % filter command it took 100x longer
        changeData = ones(1, 2 * numel(events(varargin{5}).data));
        changeData(end/2 + 1:end) = -1;
        whereData = [round((events(varargin{5}).data) / handles.xStep(whichData) - filterLength / 2) round((events(varargin{5}).data) / handles.xStep(whichData)) + filterLength / 2 + 1];
        [whereData indices] = sort(whereData);           
        lastSum = sum(whereData <= 0);
        yData(1:whereData(lastSum + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
        for j = lastSum + 1:min([find(whereData < length(yData), 1, 'last') - 1 size(whereData, 2) - 1]);
            lastSum = lastSum + changeData(indices(j));
            yData(whereData(j):whereData(j + 1)) = lastSum / (filterLength * handles.xStep(whichData) / 1000);
        end

        line(xData, yData, 'color', get(varargin{3}, 'color'), 'parent', handles.analysisAxis{whichAxis}.eventFreqPlot);
        set(get(gca, 'userData'), 'string', ['Boxcar filtered at ' num2str(filterLength * handles.xStep(whichData)) ' ms']);            
    end

    set(handles.analysisAxis{whichAxis}.eventFreqPlot, 'ylim', [0 3 * max(get(handles.analysisAxis{whichAxis}.eventFreqPlot, 'ylim'))]);
    ylabel(handles.analysisAxis{whichAxis}.eventFreqPlot, 'Hz');
    set(handles.analysisAxis{whichAxis}.eventFreqPlot, 'ycolor', get(varargin{3}, 'color'));
        
    filterLength = filterLength * handles.xStep(whichData);