function stringData = slowAHP(traceData, protocol, ampNum, axisHandle)
    % returns magnitude of AHP after a positive step
    
if ~nargin
    stringData = 'Slow AHP';
    return
end    

    filterLength = round(5 * 1000 / protocol.timePerPoint); % msec of window filtering

	steps = findSteps(protocol, ampNum);

    if ~isempty(steps)
        % there are steps on this amplifier so find the first
        % depolarizing one
        stepStart = find(steps(:, 2) > 0, 1, 'first');
        stepStop = find(steps(:, 2) < 0, 1, 'last');
        if stepStart == 1
            baselineStart = 1;
        else
            baselineStart = steps(stepStart - 1, 1) * 1000 / protocol.timePerPoint;
        end
        if ~isempty(stepStart)
            baselineData = traceData(baselineStart:steps(stepStart, 1) * 1000 / protocol.timePerPoint);
            if stepStop < size(steps, 1)
                hyperData = traceData(steps(stepStop, 1) * 1000 / protocol.timePerPoint:steps(stepStop + 1, 1) * 1000 / protocol.timePerPoint);            
            else
                hyperData = traceData(steps(stepStop, 1) * 1000 / protocol.timePerPoint:end);            
            end
            traceResponse = (calcMean(baselineData) - min(movingAverage(hyperData, filterLength)));
            stringData = [sprintf('%1.2f', traceResponse) ' mV'];

            try
                % plot baseline
                line(get(axisHandle, 'xlim'), [calcMean(baselineData) calcMean(baselineData)], 'color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Slow AHP = ' sprintf('%4.1f', traceResponse) ' mV|pA})'], 'displayName', protocol.fileName);
                % plot value at sag
                lineHandle = line(get(axisHandle, 'xlim'), [calcMean(baselineData) calcMean(baselineData)] - traceResponse, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Slow AHP = ' sprintf('%5.2f', traceResponse) ' mV|pA'')'], 'displayName', protocol.fileName);
                setappdata(lineHandle, 'printData', ['Slow AHP = ' num2str(traceResponse, '%4.2f')]);
            catch
                % at least return something

            end     
        end % ~isempty(stepStart)
    end % ~isempty(steps)