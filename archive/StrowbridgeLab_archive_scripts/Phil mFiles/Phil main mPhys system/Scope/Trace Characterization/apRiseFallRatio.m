function outData = apRiseFallRatio(traceData, timePerPoint, startTime, axisHandle)
% apWidths = apRiseFallRatio(dataTrace, timerPerPoint, startTime, outputAxisHandle);
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
    outData = 'AP Rise-Fall Ratio';
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
    
    spikes = [detectSpikes(traceData, 25, 4) length(traceData)];
    if length(spikes) > 1
		loc = nan(length(spikes), 1);
		for spikeIndex = 1:length(spikes) - 1
            % find where the falling phase equals this height
            [junk loc(spikeIndex)] = max(1 ./(traceData(spikes(spikeIndex) + 2:min([spikes(spikeIndex + 1) spikes(spikeIndex) + 23])) - traceData(spikes(spikeIndex))));
            if loc(spikeIndex) == spikes(end) - spikes(spikeIndex)
               % the last spike doesn't descend in the window
               loc = loc(1:end - 1);
               spikes = spikes(1:end - 1);
               break 
            end
            %linearly interpolate
            riseFit(:, spikeIndex) = polyfit(1:3, traceData(spikes(spikeIndex) + (-4:-2)), 1);
            fallFit(:, spikeIndex) = polyfit(1:3, traceData(spikes(spikeIndex) + (2:4)), 1);
            outData(spikeIndex) = riseFit(2, spikeIndex) / fallFit(2, spikeIndex);
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
                for i = 1:size(outData, 2)
                    % plot starts
                    line(startTime + (spikes(i) - 1 + (-4:-2)) * timePerPoint, polyval(riseFit(:,i), 1:3), 'color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''RiseSlope = ' sprintf('%6.1f', riseFit(2, i) / timePerPoint) ' mV/ms'', ''FallSlope = ' sprintf('%6.1f', fallFit(2, i) / timePerPoint) ' mV/ms'', ''Ratio  = ' sprintf('%1.3f', outData(i) * timePerPoint) '''})']);
                    % plot stops
                    line(startTime + (spikes(i) - 1 + (2:4)) * timePerPoint, polyval(fallFit(:,i), 1:3), 'color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''RiseSlope = ' sprintf('%6.1f', riseFit(2, i) / timePerPoint) ' mV/ms'', ''FallSlope = ' sprintf('%6.1f', fallFit(2, i) / timePerPoint) ' mV/ms'', ''Ratio  = ' sprintf('%1.3f', outData(i) * timePerPoint) '''})']);
                end
            catch
                % at least return something

            end       
        end       
    end