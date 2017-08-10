function stringData = fit3Exp(yData, timePerPoint, startingTime, axisHandle, traceName)
% fits three exponents to data

    if ~nargin
        stringData = 'Triple Exponent';
        return
    end

    [decayTau1 decayTau2 decayTau3 FittedCurve] = fitDecayTriple(yData);
    lineHandle = line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Taus = ' sprintf('%4.1f', decayTau1 * timePerPoint) ', ' sprintf('%4.1f', decayTau2 * timePerPoint) ', ' sprintf('%4.1f', decayTau3 * timePerPoint) ''')'],  'xData', startingTime + (0:timePerPoint:(length(FittedCurve) - 1) * timePerPoint), 'ydata', FittedCurve, 'displayName', traceName);
        setappdata(lineHandle, 'printData', ['Tau1 = ' sprintf('%4.2f', decayTau1) ', Tau2 = ' sprintf('%4.2f', decayTau2)]);
    stringData = [num2str(decayTau1 * timePerPoint) ' ms, ' num2str(decayTau2 * timePerPoint) ' ms, ' num2str(decayTau3 * timePerPoint) ' ms'];
