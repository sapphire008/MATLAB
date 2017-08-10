function stringData = fitLine(yData, timePerPoint, startingTime, axisHandle, traceName)
% fits line to data

if ~nargin
    stringData = 'Line';
    return
end

% check for sufficient input
if length(yData) < 2
    stringData = '';
    return
end

xData = startingTime + (0:timePerPoint:(length(yData) - 1) * timePerPoint);    
values = polyfit(xData, yData, 1);

% draw a line to show the fit
lineHandle = line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Slope = ' sprintf('%4.2f', values(1)) ' units/ms, intercept = ' sprintf('%4.1f', values(2)) ' ms'')'],  'xData', xData, 'ydata', polyval(values, xData), 'displayName', traceName);

% return some text
stringData = ['Slope = ' sprintf('%0.2f', values(1))];
setappdata(lineHandle, 'printData', ['Slope = ' sprintf('%0.0f', values(1))]);