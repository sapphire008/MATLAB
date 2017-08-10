function addFunctionToPlot(traceName, xData, yData, colorName, lineWidth, lineStyle)

% zData=evalin('base','zData');
handles = get(getappdata(0, 'scopes'), 'userData');
channelNames = get(handles.channelControl(1).channel, 'string');
  whichAxis = find(cellfun(@(x) ~isempty(x), strfind(channelNames(cell2mat(get([handles.channelControl.channel], 'value'))), traceName)));
%    whichChannel = find(cellfun(@(x) ~isempty(x), strfind(zData.protocol(1).channelNames, traceName)), 1, 'first');
%     if isempty(whichChannel)
%         msgbox(['Error in replaceTrace.m. Channel requested, ' channelName ' is not a vaild option.']);
%         return
%     end
%     whichAxis=whichChannel;
%     whichAxis=1; % worked with 1 = I
figure(handles.figure);
axes(handles.axes(whichAxis));
% line(xData, yData, 'parent', handles.axes(whichAxis),'color',colorName,'linewidth',lineWidth, 'linestyle',lineStyle);
line(xData, yData,'color',colorName,'linewidth',lineWidth, 'linestyle',lineStyle);
