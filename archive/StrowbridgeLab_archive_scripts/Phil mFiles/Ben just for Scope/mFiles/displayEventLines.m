function displayEventLines(channelName,baselineValue, eventTimes,eventAmps,eventColors)
  
   y1=baselineValue;
   
   handles = get(getappdata(0, 'scopes'), 'userData');
   channels = get(handles.channelControl(1).channel, 'string');
   whichTrace = find(cellfun(@(x) ~isempty(x), strfind(channels(cell2mat(get([handles.channelControl.channel], 'value'))), channelName)), 1);
   
   if ~isempty(whichTrace)
       for eventIndex=1:numel(eventTimes)
           x1= (eventTimes(eventIndex) ) ;
           y2=y1+eventAmps(eventIndex);
           line([x1 x1], [y1 y2], 'color', eventColors(eventIndex), 'linewidth', 2, 'parent', handles.axes(whichTrace));
       end
   end


end