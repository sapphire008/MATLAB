function stringData = fitAlpha(yData, timePerPoint, startingTime, axisHandle, traceName)
% fits single alpha function to data

if ~nargin
    stringData = 'Alpha';
    return
end
    
    xData = (0:length(yData) - 1) .* timePerPoint ./ 1000;
    estimates = fminsearch(@sinFun, [(max(yData) - min(yData)) * exp(1) .02 0 0], optimset('MaxFunEvals', 1000, 'Display', 'none'));
    
    yData = (estimates(1) .* (xData - estimates(3)) ./ estimates(2) .* exp(-(xData - estimates(3)) ./ estimates(2)) + estimates(4));
    if estimates(1) > 0
        yData(yData < estimates(4)) = estimates(4);
    else
        yData(yData > estimates(4)) = estimates(4);
    end

    lineHandle = line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Amp = ' sprintf('%1.1f', estimates(1) / exp(1)) ' mV, tau = ' sprintf('%1.1f', estimates(2) * 1000) ' ms'')'],  'xData', startingTime + xData*1000, 'ydata', yData, 'displayName', traceName);
    stringData = ['Amp = ' sprintf('%1.1f', estimates(1) / exp(1)) ' mV, tau = ' sprintf('%1.1f', estimates(2) * 1000) ' ms'];
    setappdata(lineHandle, 'printData', ['Alpha amp = ' sprintf('%1.1f', estimates(1) / exp(1)) ' mV, tau = ' sprintf('%1.1f', estimates(2) * 1000) ' ms']);
    
% expfun accepts curve parameters as inputs, and outputs sse
    function sse = sinFun(params)
        fitData = (params(1) .* (xData - params(3)) ./ params(2) .* exp(-(xData - params(3)) ./ params(2)) + params(4));
        if params(1) > 0
            fitData(fitData < params(4)) = params(4);
        else
            fitData(fitData > params(4)) = params(4);
        end
        
        ErrorVector = fitData - yData;
        sse = ErrorVector * ErrorVector';
    end
end