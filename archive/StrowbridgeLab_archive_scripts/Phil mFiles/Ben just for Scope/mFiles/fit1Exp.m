function stringData = fit1Exp(yData, timePerPoint, startingTime, axisHandle)
% fits single exponent to data

    if ~nargin
        stringData = 'Single Exponent';
        return
    end

    [decayTau FittedCurve] = fitDecaySingle(yData);
    line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Tau = ' sprintf('%4.1f', decayTau * timePerPoint) ''')'],  'xData', startingTime + (0:timePerPoint:(length(FittedCurve) - 1) * timePerPoint), 'ydata', FittedCurve);
    stringData = [num2str(decayTau * timePerPoint) ' ms'];