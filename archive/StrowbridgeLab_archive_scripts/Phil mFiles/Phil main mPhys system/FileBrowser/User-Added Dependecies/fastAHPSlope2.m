function [outData meanSpikeTime isiSlope firstGap gapTime] = fastAHPSlope2(inData, timePerPoint, startTime, axisHandle) % in mV
% ahpDepths = fastAHP(dataTrace, timerPerPoint, startTime, outputAxisHandle);
% defaults:
%   timePerPoint = 0.2 ms
%   startTime = 0 ms
%   outputAxisHandle is a handle to a new newScope figure
%
% determine the distance (in mV) from spike threshold to the bottom of the
% AHP sag of the action potential in a minimally-stimulated cell
% After Luebke, Frotscher, and Spruston 1998
    timePoints = 12 * 5;
    
    if sum(size(inData) > 1) > 1
        error('Input inData must be a row or column vector')
    end

    if nargin < 2
		timePerPoint = 0.2;
    end
    
    if nargin < 3
        startTime = 0;
    end
    
    spikes = detectSpikes(inData, 10, 1);
    whichSpikes = spikes > 60 & spikes < length(inData) - timePoints * 2;
    meanSpikeTime = mean(spikes(~isnan(spikes))) / numel(inData);
    spikeISIs = diff(spikes);
    firstGap = find(spikeISIs > 4 * spikeISIs(1), 1, 'first');
    
    if isempty(firstGap)
        if spikeISIs(1) > 300
            firstGap = nan;
            isiSlope = nan;
        else
            firstGap = numel(spikeISIs) + 1;
        end
    end
    if firstGap < 3
        firstGap = nan;
        isiSlope = nan;
    end
    if firstGap > 6
        firstGap = 6;
    end
    if ~isnan(firstGap)
        lineCoef = polyfit(1:firstGap - 1, spikeISIs(1:firstGap - 1), 1);
        isiSlope = 5 / lineCoef(1);
    end
    if ~isnan(firstGap)
        gapTime = spikes(firstGap);
    else
        gapTime = nan;
    end
    
    spikes = [spikes(whichSpikes) length(inData)];    
    spikePeaks = detectSpikes(inData, 10, 4);   
    spikePeaks = spikePeaks(whichSpikes);
    smoothData = sgolayfilt(inData, 3, 19);
    bottomValue = nan(1, length(spikes) - 1);
    bottomLoc = bottomValue;
    laterValue = bottomValue;
    outData = laterValue;
	
    if length(spikes) > 1
        for i = 1:length(spikes) - 1
            [bottomValue(i) bottomLoc(i)] = min(inData(spikes(i):fcnMin(smoothData(spikePeaks(i):spikes(i + 1) - 1), 1, 'first') + spikePeaks(i)));
            if spikes(i) - 1 + bottomLoc(i) + timePoints > numel(inData) || spikes(i) + timePoints * 2 >= spikes(i + 1) %spikes(i + 1)
                bottomValue(i) = nan;
                outData(i) = nan;
                spikes(i) = nan;                    
            else
                laterValue = inData(spikes(i) - 1 + bottomLoc(i) + timePoints);
                outData(i) = 5 * (laterValue - bottomValue(i)) / timePoints;                
            end
        end  
        
        if ~nargout || (nargin == 4 && ishandle(axisHandle))
            
            if nargin < 4
                axisHandle = newScope(inData, startTime:timePerPoint:(length(inData) - 1)*timePerPoint - startTime, 'Trace V');            
				set(axisHandle, 'name', ['Fast AHP, Mean = ' num2str(mean(outData), '%3.2f') ' mV']);
                axisHandle = axisHanle.axes(1);
            end
           
            set(0, 'currentfigure', get(axisHandle, 'parent'));
            set(gcf, 'currentAxes', axisHandle);

            try
                for i = 1:size(outData, 2)
                    if ~isnan(spikes(i))
                        % plot thresholds
                        line((spikes(i) - 1) * timePerPoint + startTime, inData(spikes(i)), 'color', [1 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Fast AHP = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                        % plot min
                        line((spikes(i) + bottomLoc(i) - 1) * timePerPoint + startTime, inData(spikes(i) + bottomLoc(i)), 'color', [1 0 1], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Fast AHP = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                        % plot later
                        line((spikes(i) + bottomLoc(i) + timePoints - 1) * timePerPoint + startTime, inData(spikes(i) + bottomLoc(i) + timePoints), 'color', [0 1 1], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Fast AHP = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                    end
                end
            catch
                % at least return something

            end    
        end          
    end