function stringData = rIn(traceData, protocol, ampNum, axisHandle)
    % returns resistance (in Mohms) and capacitance (in pFarads) of membrane
    
if ~nargin
    stringData = 'Input Resistance';
    return
end    

    filterLength = round(40 * 1000 / protocol.timePerPoint); % msec of window filtering

	steps = findSteps(protocol, ampNum);
	
    if ~isempty(steps)
        % there are steps on this amplifier so find the first
        % hyperpolarizing one
%         stepStart = find(steps(:, 2) < 0, 1, 'first');
        stepStart = 1;
        if stepStart == 1
            baselineStart = 1;
        else
            baselineStart = steps(stepStart - 1, 1) * 1000 / protocol.timePerPoint;
        end
        if ~isempty(stepStart)
            baselineData = traceData(baselineStart:steps(stepStart, 1) * 1000 / protocol.timePerPoint);
            if stepStart ~= size(steps, 1)
                hyperData = traceData(steps(stepStart, 1) * 1000 / protocol.timePerPoint:steps(stepStart + 1, 1) * 1000 / protocol.timePerPoint);            
            else
                hyperData = traceData(steps(stepStart, 1) * 1000 / protocol.timePerPoint:end);            
            end
            stimStep = steps(stepStart, 2);
            % find where the hyperpolarizing step has leveled off
            dataDer = diff(movingAverage(hyperData, filterLength));
            whereFlat = find(dataDer > 0, 1, 'first');
            traceResponse = calcMean(hyperData(whereFlat:length(hyperData))) - calcMean(baselineData);
            % check step size and whether the amp was turned on for the whole step
            if abs(traceResponse) > 1.5 && (whereFlat < steps(stepStart, 1) + .3 * length(hyperData) || min(hyperData(1:round(length(hyperData)*.3))) <= calcMean(hyperData(whereFlat:length(hyperData))))
                if strcmp(protocol.ampTypeName{ampNum}(end - 1:end), 'CC')
                    resistance = traceResponse / stimStep * 1000; % R (in Mohms) = deltaVoltage (in mV) / deltaCurrent (in pA) * 1000
                else
                    resistance = stimStep / traceResponse * 1000; % R (in Mohms) = deltaVoltage (in mV) / deltaCurrent (in pA) * 1000
                end
                [tau FittedCurve ssePer ssePer] = fitDecaySingle(hyperData(10:110));
                ssePer = ssePer / 100;
                capacitance = tau * protocol.timePerPoint / resistance; % tau (in msec) / resistance (in Mohms) * 1000 = capacitance (in pFarads)               
                stringData = [sprintf('%1.2f', resistance) ' M Ohms'];
                
                try
                    % plot baseline
                    line(get(axisHandle, 'xlim'), [calcMean(baselineData) calcMean(baselineData)], 'color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Resistance = ' sprintf('%4.1f', resistance) ' Mohms''; ''Capacitance = ' sprintf('%7.1f', capacitance) ' pFarads''})'], 'displayName', protocol.fileName);
                    % plot value in step
                    lineHandle = line(get(axisHandle, 'xlim'), [calcMean(hyperData(whereFlat:length(hyperData))) calcMean(hyperData(whereFlat:length(hyperData)))], 'color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Resistance = ' sprintf('%4.1f', resistance) ' Mohms''; ''Capacitance = ' sprintf('%7.1f', capacitance) ' pFarads''})'], 'displayName', protocol.fileName);
                    setappdata(lineHandle, 'printData', ['Rin = ' num2str(resistance, '%5.1f') ' mOhm']);
                    % plot capacitance fit
                    lineHandle = line((1:numel(FittedCurve)) * protocol.timePerPoint / 1000 + steps(stepStart, 1) + 2, FittedCurve, 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Resistance = ' sprintf('%4.1f', resistance) ' Mohms''; ''Capacitance = ' sprintf('%7.1f', capacitance) ' pFarads''; ''SSE = ' sprintf('%1.2f', ssePer) ' per point''})'], 'displayName', protocol.fileName);
                    setappdata(lineHandle, 'printData', ['Capacitance = ' num2str(capacitance, '%7.1f') 'pF']);
                catch
                    % at least return something

                end     
            end 
        end % ~isempty(stepStart)
    end % ~isempty(steps)