function success = replaceTrace(newData, channelName)
success = 0;
zData = evalin('base', 'zData');

% error checking
if length(newData) ~= length(zData.traceData{1})
    msgbox(['Error in replaceTrace.m. Current trace is ' num2str(length(zData.traceData{1})) ' points long. Replacement trace is ' num2str(length(newData)) ' points long.']);
    return
end

if nargin < 2
    % replace default trace
    handles = get(getappdata(0, 'scopes'), 'userData');
    whichChannel = get(handles.channelControl(handles.axes == gca).channel, 'value');
else
    % replace specified trace
    whichChannel = find(cellfun(@(x) ~isempty(x), strfind(zData.protocol(1).channelNames, channelName)), 1, 'first');
    if isempty(whichChannel)
        msgbox(['Error in replaceTrace.m. Channel requested, ' channelName ' is not a vaild option.']);
        return
    end
end
currentTrace = getappdata(0, 'currentTrace');
if isempty(currentTrace)
    zData.traceData{whichChannel}(:,1) = newData;
else
    zData.traceData{whichChannel}(:,strcmp({zData.protocol.fileName}, currentTrace)) = newData;
end
assignin('base', 'zData', zData);
success = 1;