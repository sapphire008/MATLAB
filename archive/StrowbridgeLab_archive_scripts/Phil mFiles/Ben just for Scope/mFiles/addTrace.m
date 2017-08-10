function success = addTrace(newData, channelName)
success = 0;
zData = evalin('base', 'zData');

% error checking
if length(newData) ~= length(zData.traceData{1})
    msgbox(['Error in addTrace.m. Current trace is ' num2str(length(zData.traceData{1})) ' points long. Replacement trace is ' num2str(length(newData)) ' points long.']);
    return
end

if any(cellfun(@(x) ~isempty(x), strfind(zData.protocol(1).channelNames, channelName)))
    msgbox('Error in addTrace.m. Trace name already taken');
    return
end

zData.traceData{end + 1} = repmat(newData, size(zData.traceData{1}, 2), 1)';
for i = 1:numel(zData.protocol)
    zData.protocol(i).channelNames{end + 1} = channelName;
end
assignin('base', 'zData', zData);
success = 1;