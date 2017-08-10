function stringData = fit1Exp(yData, timePerPoint, startingTime, axisHandle, traceName)
% fits single exponent to data

    if ~nargin
        stringData = 'Single Exponent';
        return
    end

    [decayTau FittedCurve] = fitDecaySingle(yData);
    lineHandle = line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Tau = ' sprintf('%4.1f', decayTau * timePerPoint) ''')'],  'xData', startingTime + (0:timePerPoint:(length(FittedCurve) - 1) * timePerPoint), 'ydata', FittedCurve, 'displayName', traceName);
    setappdata(lineHandle, 'printData', ['Tau = ' sprintf('%4.2f', decayTau)]);
    stringData = [num2str(decayTau * timePerPoint) ' ms'];