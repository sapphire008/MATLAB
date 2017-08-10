function stringData = fitSine(yData, timePerPoint, startingTime, axisHandle, traceName)
% fits single sine wave to data
persistent frequency

if ~nargin
    stringData = 'Sine';
    return
end

if isempty(frequency)
    frequency = 60; % Hz
end

temp = inputdlg('Sine Frequency (Hz)','Fit Sine',1,{num2str(frequency)});

if ~isempty(temp)
    frequency = str2double(temp);
    
    xData = (0:length(yData) - 1) .* timePerPoint ./ 1000;
%     sinComp = 2*sum(((yData-mean(yData)).*-sin(2*pi*frequency*xData)).^2)/length(xData);
%     cosComp = 2*sum(((yData-mean(yData)).*cos(2*pi*frequency*xData)).^2)/length(xData);
%     ampVal = sqrt(sinComp^2+cosComp^2);
%     phaseVal = unwrap(atan2(sinComp, cosComp)) - pi/2;
    estimates = fminsearch(@sinFun, [mean(yData) range(yData) / 2 0], optimset('MaxFunEvals', 1000, 'Display', 'none'));
    lineHandle = line('parent', axisHandle, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Tau = ' sprintf('%4.1f', estimates(2) * timePerPoint) ''')'],  'xData', startingTime + xData*1000, 'ydata', estimates(1) + estimates(2)*sin(estimates(3) + 2*pi*frequency*xData), 'displayName', traceName);
    stringData = [sprintf('%1.2f', estimates(2)) ' mV, phase = ' sprintf('%1.3f', estimates(3)) ' radians, lag = ' sprintf('%1.2f', estimates(3) / 2 / pi / frequency * 1000) ' ms'];
    setappdata(lineHandle, 'printData', ['Sine fit = ' sprintf('%1.2f', estimates(2)) ' mV, phase = ' sprintf('%1.3f', estimates(3)) ' radians, lag = ' sprintf('%1.2f', estimates(3) / 2 / pi / frequency * 1000) ' ms']);
end

% expfun accepts curve parameters as inputs, and outputs sse,
% the sum of squares error for: offest + A * exp(-xdata./tau1) + B * exp(-xdata./tau2) - yData
    function sse = sinFun(params)
        ErrorVector = (params(1) + params(2) .* sin(params(3) + 2 .* pi .* frequency .* xData)) - yData;
        sse = ErrorVector * ErrorVector';
    end
end