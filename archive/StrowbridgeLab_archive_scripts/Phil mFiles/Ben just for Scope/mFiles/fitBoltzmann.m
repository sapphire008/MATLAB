function stringData = fitBoltzmann(yData, timePerPoint, startingTime, axisHandle, traceName)
% fits single sine wave to data

if ~nargin
    stringData = 'Boltzmann';
    return
end

    xData = (0:length(yData) - 1) .* timePerPoint ./ 1000;
    estimates = fminsearch(@boltzFun, [range(yData) * 2 range(yData) * 2 .05 .001], optimset('MaxFunEvals', 1000000, 'Display', 'none'));

    lineHandle = line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Tau = ' sprintf('%4.1f', estimates(2) * timePerPoint) ''')'],  'xData', startingTime + xData*1000, 'ydata', (estimates(2) + (estimates(1) - estimates(2)) ./ (1 + exp((xData - estimates(3))./estimates(4)))), 'displayName', traceName);
    stringData = [sprintf('%1.2f', estimates(3) * 1000 + startingTime) ' ms'];
    setappdata(lineHandle, 'printData', ['Boltzmann offset = ' sprintf('%1.2f', estimates(3) * 1000 + startingTime) ' ms']);


% expfun accepts curve parameters as inputs, and outputs sse,
% the sum of squares error for: offest + A * exp(-xdata./tau1) + B * exp(-xdata./tau2) - yData
    function sse = boltzFun(params)
        ErrorVector = (params(2) + (params(1) - params(2)) ./ (1 + exp((xData - params(3))./params(4)))) - yData;
        sse = ErrorVector * ErrorVector';
    end
end