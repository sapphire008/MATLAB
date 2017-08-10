function outData = fastAHPSlope(inData, timePerPoint, startTime, axisHandle) % in mV
% ahpDepths = fastAHP(dataTrace, timerPerPoint, startTime, outputAxisHandle);
% defaults:
%   timePerPoint = 0.2 ms
%   startTime = 0 ms
%   outputAxisHandle is a handle to a new newScope figure
%
% determine the distance (in mV) from spike threshold to the bottom of the
% AHP sag of the action potential in a minimally-stimulated cell
% After Luebke, Frotscher, and Spruston 1998

% respond with the menu text if no inputs given
if ~nargin
    outData = 'AHP Slope';
    return
end

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
    
    spikes = detectSpikes(inData, 25, 1);
    whichSpikes = spikes > 125 & spikes < length(inData) - timePoints * 2;
    
    spikes = [spikes(whichSpikes) length(inData)];    
    spikePeaks = detectSpikes(inData, 25, 4);   
    spikePeaks = spikePeaks(whichSpikes);
    smoothData = sgolayfilt(inData, 3, 19);
    bottomValue = nan(1, length(spikes) - 1);
    bottomLoc = bottomValue;
    laterValue = bottomValue;
    outData = laterValue;
	
    if length(spikes) > 1
        for i = 1:length(spikes) - 1
            [bottomValue(i) bottomLoc(i)] = min(inData(spikes(i):fcnMin(smoothData(spikePeaks(i):spikes(i + 1) - 1), 1, 'first') + spikePeaks(i)));
            if spikes(i) - 1 + bottomLoc(i) + timePoints > spikes(i + 1)
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
                axisHandle = axisHandle.axes(1);
				set(get(axisHandle, 'parent'), 'name', ['Fast AHP, Mean = ' num2str(mean(outData), '%3.2f') ' mV']);
            else
                outData = num2str(outData);
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