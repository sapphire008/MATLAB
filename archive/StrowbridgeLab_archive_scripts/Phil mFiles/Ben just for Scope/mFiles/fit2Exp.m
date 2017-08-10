function stringData = fit2Exp(yData, timePerPoint, startingTime, axisHandle)
% fits two exponents to data

    if ~nargin
        stringData = 'Double Exponent';
        return
    end

    [decayTau1 decayTau2 FittedCurve] = fitDecayDouble(yData);
    line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Taus = ' sprintf('%4.1f', decayTau1 * timePerPoint) ', ' sprintf('%4.1f', decayTau2 * timePerPoint) ''')'],  'xData', startingTime + (0:timePerPoint:(length(FittedCurve) - 1) * timePerPoint), 'ydata', FittedCurve);
    stringData = [num2str(decayTau1 * timePerPoint) ' ms, ' num2str(decayTau2 * timePerPoint) ' ms'];