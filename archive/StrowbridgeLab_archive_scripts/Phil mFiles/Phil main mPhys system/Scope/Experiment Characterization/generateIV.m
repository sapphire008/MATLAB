function stringData = generateIV(traceData, protocol, ampNum, axisHandle)
% generate an IV curve given the input data and calculate a input
% resistance 
% error estimates are from http://www.nd.edu/~rwilliam/stats1/ "Bivariate regression I/II"
% and "Standard errors for regression coefficients; multicollinearity"

if ~nargin
    stringData = 'Generate IV Curve';
    return
end

    filterLength = round(40 * 1000 / protocol(1).timePerPoint); % msec of window filtering
    step = [];
    response = [];
    startValue = [];
    
    lineHandles = get(axisHandle, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    if ~sum(lineType)
        stringData = '';
        return
    end
    traceData = flipud(cell2mat(get(lineHandles(lineType), 'ydata')));
    protocol = evalin('base', 'zData.protocol');   

    for i = 1:size(traceData, 1)
        steps = findSteps(protocol(i), ampNum);	
        if ~isempty(steps)
            % there are steps on this amplifier so find the first
            % hyperpolarizing one
            baselineValue = calcMean(traceData(i, 1:steps(1, 1) * 1000 / protocol(1).timePerPoint));
            if size(steps, 1) > 1
                hyperData = traceData(i, steps(1, 1) * 1000 / protocol(i).timePerPoint:steps(2, 1) * 1000 / protocol(i).timePerPoint);            
            else
                hyperData = traceData(i, steps(1, 1) * 1000 / protocol(i).timePerPoint:end);            
            end
            stimStep = steps(1, 2);
            % find where the hyperpolarizing step has leveled off
            dataDer = diff(movingAverage(hyperData, filterLength));
            whereFlat = find(dataDer > 0, 1, 'first');
            traceResponse = calcMean(hyperData(whereFlat:length(hyperData))) - baselineValue;
            % check step size and whether the amp was turned on for the whole step
            if abs(traceResponse) > 1
                step(end + 1) = stimStep;
                response(end + 1) = traceResponse;
                startValue(end + 1) = baselineValue;
            end
        end % ~isempty(steps)
    end
    
    % produce the output
    uniqueSteps = sort(unique(step));
    errorBars = zeros(1, numel(uniqueSteps));
    for i = 1:numel(uniqueSteps)
        tempResponse = response(step == uniqueSteps(i));
        outData(i) = mean(tempResponse);
        errorBars(i) = std(tempResponse);
    end
    
    % plot the ouput
        figure('numbertitle', 'off');
        outData = outData + mean(startValue(step == uniqueSteps(1)));        
        if strcmp(protocol(1).ampTypeName{ampNum}(end - 1:end), 'VC') % voltage clamp
            temp = step;
            step = response;
            response = temp;
        end
        values = polyfit(step, response, 1);
        if sum(errorBars) > 0
            errorBarLength = range(uniqueSteps) / 40;
            if strcmp(protocol(1).ampTypeName{ampNum}(end - 1:end), 'VC') % current clamp
                line([uniqueSteps - errorBarLength; uniqueSteps + errorBarLength; uniqueSteps; uniqueSteps; uniqueSteps + errorBarLength; uniqueSteps - errorBarLength], [outData - errorBars; outData - errorBars; outData - errorBars; outData + errorBars; outData + errorBars; outData + errorBars], 'color', [0 0 0]);
            else        
                line([outData - errorBars; outData - errorBars; outData - errorBars; outData + errorBars; outData + errorBars; outData + errorBars], [uniqueSteps - errorBarLength; uniqueSteps + errorBarLength; uniqueSteps; uniqueSteps; uniqueSteps + errorBarLength; uniqueSteps - errorBarLength], 'color', [0 0 0]);                
            end
        else
            line(outData, uniqueSteps, 'marker', 'x', 'markeredgecolor', [0 0 0], 'linestyle', 'none');
        end              
        set(gcf, 'name', ['Rin = ' sprintf('%4.2f', 1000 * values(1)) ' +/- ' sprintf('%4.2f', 1000 * sqrt(sum((response - polyval(values, response)).^2) / (numel(step) - 1)) / sum(sqrt((step - mean(step)).^2))) '  M ohms']);                
        values(1) = 1 / values(1);
        values(2) = -values(2) * values(1);
        xData = linspace(min(get(gca, 'xlim')), max(get(gca, 'xlim')), 100);
        if strcmp(protocol(1).ampTypeName{ampNum}(end - 1:end), 'VC') % voltage clamp
            line(xData, polyval(values, xData) + mean(startValue(response == uniqueSteps(1))));         
        else
            line(xData, polyval(values, xData - mean(startValue(step == uniqueSteps(1)))));        
        end
        outValue = 1000 / values(1);        
        xlabel('Voltage (mV)');
        ylabel('Current (pA)');
        
        stringData = get(gcf, 'name');