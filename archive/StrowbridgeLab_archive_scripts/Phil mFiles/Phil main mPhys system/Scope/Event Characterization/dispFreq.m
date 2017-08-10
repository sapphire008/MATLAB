function outText = dispFreq(varargin)
persistent tempData
if ~nargin
    outText = 'Interval Frequency';
    return
end
   
if isempty(tempData)
    tempData = {'10000', '15000'};
end
   
    % get handles to the event traces
    events = getappdata(gca, 'events');
    
    tempData = inputdlg({'From (msec)', 'To'},'Interval Freq...',1, {num2str(tempData{1}), num2str(tempData{2})});          
    disp([sprintf('%1.2f', sum(events(varargin{5}).data >= str2double(tempData{1}) & events(varargin{5}).data <= str2double(tempData{2})) / (str2double(tempData{2}) - str2double(tempData{1})) * 1000) ' Hz']);
    