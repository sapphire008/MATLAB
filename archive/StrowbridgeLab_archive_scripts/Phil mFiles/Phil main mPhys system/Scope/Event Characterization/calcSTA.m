function outText = calcSTA(varargin)
persistent windowBounds
if ~nargin
    outText = 'Event-Triggered Average';
    return
end

    if isempty(windowBounds)
        windowBounds = [-10 100];
    end
    handleList = get(gcf, 'userData');
    handles = handleList.axes;
    kids = get(handles, 'children');
    if ~iscell(kids)
        kids = {kids};
    end
    for index = 1:numel(kids)
        kids{index} = kids{index}(strcmp(get(kids{index}, 'userData'), 'data'));
        for j = 1:numel(kids{index})
            kidTraces{index}{j} = get(kids{index}(j), 'displayName');
        end
    end

    windowBounds = str2double(inputdlg({'Window Start (msec)', 'Window End (msec)'},'',1, {num2str(windowBounds(1)); num2str(windowBounds(2))}));
    
    events = getappdata(gca, 'events');

    if numel(events(varargin{5}).data)
        for axesIndex = 1:numel(handles)
            data{axesIndex} = get(kids{axesIndex}(strcmp(events(varargin{5}).traceName, kidTraces{axesIndex})), 'yData')';
        end        
        eventTriggeredAverage(events(varargin{5}).data' ./ handleList.xStep(get(handleList.channelControl(handleList.axes == gca).channel, 'value')), data, windowBounds, handleList.xStep(cell2mat(get([handleList.channelControl.channel], 'value'))), 0);  
    end  