function outData = apWidth(traceData, timePerPoint, startTime, axisHandle)
% apWidths = APWidth(dataTrace, timerPerPoint, startTime, outputAxisHandle);
% defaults:
%   timePerPoint = 0.2 ms
%   startTime = 0 ms
%   outputAxisHandle is a handle to a new newScope figure
%
% determine the time (in ms) from the point at which the AP crosses
% threshold to the point at which it is passing back by threshold on the
% way down

% respond with the menu text if no inputs given
if ~nargin
    outData = 'AP Width';
    return
end

    outData = NaN;

    if sum(size(traceData) > 1) > 1
        error('Input data must be a row or column vector')
    end

    if nargin < 2
		timePerPoint = 0.2;     
    end
    
    if nargin < 3
        startTime = 0;
    end
    
    spikes = [detectSpikes(traceData, 25, 1) length(traceData)];
    if length(spikes) > 1
		loc = nan(length(spikes), 1);
		pointDrop = loc;
		for spikeIndex = 1:length(spikes) - 1
            % find where the falling phase equals this height
            [junk loc(spikeIndex)] = max(1 ./(traceData(spikes(spikeIndex) + 2:min([spikes(spikeIndex + 1) spikes(spikeIndex) + 23])) - traceData(spikes(spikeIndex))));
            if loc(spikeIndex) >= spikes(end) - spikes(spikeIndex) - 1
               % the last spike doesn't descend in the window
               loc = loc(1:end - 1);
               spikes = spikes(1:end - 1);
               break 
            end
            %linearly interpolate
            pointDrop(spikeIndex) = traceData(spikes(spikeIndex) + loc(spikeIndex)) - traceData(spikes(spikeIndex) + 2 + loc(spikeIndex)); 
            outData(spikeIndex) = (loc(spikeIndex) - ((traceData(spikes(spikeIndex)) - traceData(spikes(spikeIndex) + 2 + loc(spikeIndex))) / pointDrop(spikeIndex)) + 1);
		end
		outData = outData * timePerPoint;

        if (~nargout && exist('pointDrop', 'var')) || (nargin == 4 && ishandle(axisHandle))
            
            if nargin < 4
                axisHandle = newScope(traceData, startTime:timePerPoint:(length(traceData) - 1)*timePerPoint - startTime, 'Trace V');            
                axisHandle = axisHandle.axes(1);
                set(get(axisHandle, 'parent'), 'name', ['AP Widths, Mean Width = ' num2str(mean(outData), '%3.2f') ' ms']);  
            end
           
            set(0, 'currentfigure', get(axisHandle, 'parent'));
            set(gcf, 'currentAxes', axisHandle);

            try
                spikes(end) = [];
                loc(end) = [];
                pointDrop(end) = [];
                for i = 1:size(outData, 1)
                    % plot starts
                    line((spikes - 1) * timePerPoint + startTime, traceData(spikes), 'color', [1 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP Width = ' sprintf('%6.1f', outData(i) * timePerPoint) ' msec'')']);
                    % plot stops
                    line((spikes - 1) * timePerPoint + startTime + outData, traceData(spikes) + ((loc' - round(loc')) .* pointDrop'), 'color', [0 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP Width = ' sprintf('%6.1f', outData(i) * timePerPoint) ' msec'')']);
                end
            catch
                % at least return something

            end       
            if nargin == 4
                outData = num2str(outData);  
            end
        end       
    end