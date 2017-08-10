function [outData bottomLoc] = fastAHP(inData, timePerPoint, startTime, axisHandle) % in mV
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
    outData = 'Fast AHP';
    return
end
    
    if sum(size(inData) > 1) > 1
        error('Input inData must be a row or column vector')
    end

    if nargin < 2
		timePerPoint = 0.2;
    end
    
    if nargin < 3
        startTime = 0;
    end
    
    smoothData = sgolayfilt(inData, 3, 39);
    spikes = [detectSpikes(inData, 25, 1) length(inData)];
    spikePeaks = detectSpikes(inData, 25, 4);
    bottomValue = nan(1, length(spikes) - 1);
    bottomLoc = bottomValue;
    outData = bottomLoc;
	
    if length(spikes) > 1
        for i = 1:length(spikes) - 1
            minLoc = fcnMin(smoothData(spikePeaks(i):spikes(i + 1) - 1), 1, 'first');
            if ~isempty(minLoc)
                [bottomValue(i) bottomLoc(i)] = min(inData(spikes(i):minLoc + spikePeaks(i)));
                outData(i) = inData(spikes(i)) - bottomValue(i);
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
                    % plot thresholds
                    line((spikes(i) - 2) * timePerPoint + startTime, inData(spikes(i)), 'color', [1 0 1], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Fast AHP = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                    % plot basins
                    line((bottomLoc(i) + spikes(i) - 3) * timePerPoint + startTime, bottomValue(i), 'color', [0 1 1], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Fast AHP = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                end
            catch
                % at least return something

            end    
        end          
    end