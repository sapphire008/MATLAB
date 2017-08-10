function stringData = sag(traceData, protocol, ampNum, axisHandle)
    % returns ratio of steady state deflection to maximum deflection
    
if ~nargin
    stringData = 'Sag Ratio';
    return
end    
    
    filterLength = round(40 * 1000 / protocol.timePerPoint); % ms of window filtering

	steps = findSteps(protocol, ampNum);
    sagRatio = nan;

    if ~isempty(steps)
        % there are steps on this amplifier so find the first
        % hyperpolarizing one
        stepStart = find(steps(:, 2) < 0, 1, 'first');
        if stepStart == 1
            baselineStart = 1;
        else
            baselineStart = steps(stepStart - 1, 1) * 1000 / protocol.timePerPoint;
        end
        if ~isempty(stepStart)
            baselineData = traceData(baselineStart:steps(stepStart, 1) * 1000 / protocol.timePerPoint);
            if stepStart < size(steps, 1)
                hyperData = traceData(steps(stepStart, 1) * 1000 / protocol.timePerPoint:steps(stepStart + 1, 1) * 1000 / protocol.timePerPoint);            
            else
                hyperData = traceData(steps(stepStart, 1) * 1000 / protocol.timePerPoint:end);            
            end
            % find where the hyperpolarizing step has leveled off
            dataDer = diff(movingAverage(hyperData, filterLength));
            whereFlat = find(dataDer > 0, 1, 'first');
            traceResponse = (calcMean(baselineData) - calcMean(hyperData(whereFlat:length(hyperData))));
            % check step size and whether the amp was turned on for the whole step
            if traceResponse > 3 && (whereFlat < steps(stepStart, 1) + .3 * length(hyperData) || min(hyperData(1:round(length(hyperData)*.3))) <= calcMean(hyperData(whereFlat:length(hyperData))))
                [sagMax whereMax] = min(hyperData);
                if whereMax < length(hyperData) * .3
                    sagRatio = traceResponse / (calcMean(baselineData) - sagMax);
                    stringData = sprintf('%1.3f', sagRatio);
                    
                    try
                        % plot baseline
                        line(get(parentHandle, 'xlim'), [calcMean(baselineData) calcMean(baselineData)], 'color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Sag ratio = ' sprintf('%4.1f', sagRatio) '})'], 'displayName', protocol.fileName);
                        % plot value in step
                        line(get(parentHandle, 'xlim'), [calcMean(hyperData(whereFlat:length(hyperData))) calcMean(hyperData(whereFlat:length(hyperData)))], 'color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Sag ratio = ' sprintf('%4.1f', sagRatio) '})'], 'displayName', protocol.fileName);
                        % plot value at sag
                        lineHandle = line(get(parentHandle, 'xlim'), [sagMax sagMax], 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Sag Ratio = ' sprintf('%5.2f', sagRatio) ''')'], 'displayName', protocol.fileName);
                        setappdata(lineHandle, 'printData', ['Sag = ' num2str(sagRatio, '%4.2f')]);
                    catch
                        % at least return something

                    end     
                end
            end % ~nargout
        end % ~isempty(stepStart)
    end % ~isempty(steps)