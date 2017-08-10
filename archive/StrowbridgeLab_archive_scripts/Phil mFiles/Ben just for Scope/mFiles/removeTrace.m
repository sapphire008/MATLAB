function success = removeTrace(channelName)
success = 0;
zData = evalin('base', 'zData');
whatChannel = find(cellfun(@(x) ~isempty(x), strfind(zData.protocol(1).channelNames, channelName)), 1, 'first');

if isempty(whatChannel)
    msgbox('Error in removeTrace.m. Trace name not found');
    return
end

handles = get(getappdata(0, 'scopes'), 'userData');

for i = 1:numel(zData.protocol(1).ampType)
    if whatChannel == whichChannel(zData.protocol(1), i) 
        for j = 1:handles.axesCount
            if whatChannel == get(handles.channelControl(j).channel, 'value')
                msgbox('Error in removeTrace.m. Cannot remove informative trace. Please select another trace in scope window before removing.')
                return    
            end
        end
    end
end

zData.traceData(whatChannel) = [];
for i = 1:numel(zData.protocol)
    zData.protocol(i).channelNames(whatChannel) = [];
end
assignin('base', 'zData', zData);
success = 1;