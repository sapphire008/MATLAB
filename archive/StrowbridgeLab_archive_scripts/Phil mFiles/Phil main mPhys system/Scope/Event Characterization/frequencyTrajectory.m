function outText = frequencyTrajectory(varargin)
persistent binWidth
if ~nargin
    outText = 'Frequency Trajectory';
    return
end
    
    handles = get(gcf, 'userData');
    whichAxis = find(handles.axes == gca);
    channelNames = get(handles.channelControl(whichAxis).channel, 'string');
    whichData = get(handles.channelControl(whichAxis).channel, 'value');    
    
    % get handles to the event traces
    for i = 1:numel(handles.axes)
        events{i} = getappdata(handles.axes(i), 'events');
        % combine all events for an episode
        [a b n] = unique({events{i}.traceName});
        for j = 1:numel(a)
            events{i}(b(j)).data = sort([events{i}(n==j).data]);
        end
        events{i} = events{i}(b);
    end
    
    % plot the frequency data
	xData = handles.minX(whichData):handles.xStep(whichData):handles.maxX(whichData);    
    if isempty(binWidth)
    	binWidth = 1000;
    end
    tempData = inputdlg({'Bin Width (msec)'},'Freq Traj...',1, {num2str(binWidth)});      
    if numel(tempData) == 0
        return
    end
    binWidth = str2double(tempData);
    if binWidth > size(xData, 2) * handles.xStep(whichData)
        binWidth = size(xData, 2) * handles.xStep(whichData);
    end
    yData = nan(3, 5, fix(length(xData) / (binWidth / handles.xStep(whichData))));    
    for i = 1:numel(events)
        for j = 1:size(yData, 3)
            for k = 1:numel(events{i})
                yData(i, k, j) = sum(events{i}(k).data > (j - 1) * binWidth & events{i}(k).data <= j * binWidth);
            end
        end
    end

    assignin('base', 'yData2', yData);
    yData = squeeze(mean(yData, 2));
    figure('numberTitle', 'off', 'name', 'Frequency Trajectory');
    plot3(yData(1, :), yData(2, :), yData(3, :), '-ok');
    xlabel(channelNames{get(handles.channelControl(1).channel, 'value')});
    ylabel(channelNames{get(handles.channelControl(2).channel, 'value')});
    zlabel(channelNames{get(handles.channelControl(3).channel, 'value')});
    hold on
    plot3(yData(1, 10:11), yData(2, 10:11), yData(3, 10:11), '-or', 'markerFaceColor', 'r');
    plot3(yData(1, 1:10), yData(2, 1:10), yData(3, 1:10), '-ob', 'markerFaceColor', 'b');
        