function stringData = fitLineExtra(yData, timePerPoint, startingTime, axisHandle)
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
line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Slope = ' sprintf('%4.1f', values(1)) ', intercept = ' sprintf('%4.1f', values(1)) ''')'],  'xData', xData, 'ydata', polyval(values, xData));

% return some text
stringData = ['Slope = ' sprintf('%0.0f', values(1))];