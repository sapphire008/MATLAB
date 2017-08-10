function makeLines2(traceName, colorName, lineWidth)

%  zData=evalin('base','zData');
handles = get(getappdata(0, 'scopes'), 'userData');
channelNames = get(handles.channelControl(1).channel, 'string');
  whichAxis = find(cellfun(@(x) ~isempty(x), strfind(channelNames(cell2mat(get([handles.channelControl.channel], 'value'))), traceName)));
%     whichChannel = find(cellfun(@(x) ~isempty(x), strfind(zData.protocol(1).channelNames, traceName)), 1, 'first');
%     if isempty(whichChannel)
%         msgbox(['Error in replaceTrace.m. Channel requested, ' channelName ' is not a vaild option.']);
%         return
%     end
%     whichAxis=whichChannel;
%     whichAxis=1; % worked with 1 = I
kids = get(handles.axes(whichAxis), 'children');
xData = get(kids(1), 'xdata');
yData = get(kids(1), 'ydata');
% msgbox(['Mean of trace being affected is: ' num2str(mean(yData))]);

% get rid of the old line
delete(kids(1));

% generate a new bunch of lines
whereBig = find(yData ~= 0);
newX = [xData(whereBig); xData(whereBig); nan(size(whereBig))];
newY = [zeros(size(whereBig)); yData(whereBig); nan(size(whereBig))];
% msgbox(['Axis program would like to work on: ' num2str(whichAxis)]);
line(newX(:), newY(:), 'parent', handles.axes(whichAxis),'color',colorName,'linewidth',lineWidth);
% figure(handles.figure);
%  axes(handles.axes(whichChannel));
%  line(newX(:), newY(:),'color',colorName,'linewidth',lineWidth);
%  refresh(handles.figure);