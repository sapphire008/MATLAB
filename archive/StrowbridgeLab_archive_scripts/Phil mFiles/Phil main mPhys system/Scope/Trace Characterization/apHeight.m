function outData = apHeight(inData, timePerPoint, startTime, axisHandle) % in mV
% spikeHeights = APHeight(dataTrace, timerPerPoint, startTime, outputAxisHandle);
% defaults:
%   timePerPoint = 0.2 ms
%   startTime = 0 ms
%   outputAxisHandle is a handle to a new newScope figure
%
% determine the height (in mV) from the point at which the AP crosses
% threshold to the point at the peak of the AP occurs

% respond with the menu text if no inputs given
if ~nargin
    outData = 'AP Height';
    return
end
    
    outData = NaN;
    
    if sum(size(inData) > 1) > 1
        error('Input data must be a row or column vector')
    end

    if nargin < 2
		timePerPoint = 0.2;
    end
    
    if nargin < 3
        startTime = 0;
    end

    spikes = [detectSpikes(inData, 25, 1) length(inData)];
    
    if length(spikes) > 1
		loc = nan(length(spikes), 1);
        for spikeIndex = 1:length(spikes) - 1
            % find where the falling phase equals this height
            [junk loc(spikeIndex)] = max(inData(spikes(spikeIndex) + 1:min([spikes(spikeIndex + 1) spikes(spikeIndex) + 23])));
            outData(spikeIndex) = inData(spikes(spikeIndex) + loc(spikeIndex)) - inData(spikes(spikeIndex));
        end

        if ~nargout || (nargin == 4 && ishandle(axisHandle))
            
            if nargin < 4
                axisHandle = newScope(inData, startTime:timePerPoint:(length(inData) - 1)*timePerPoint - startTime, 'Trace V');            
                axisHandle = axisHandle.axes(1);
				set(get(axisHandle, 'parent'), 'name', ['AP Heights, Mean Height = ' num2str(mean(outData), '%3.2f') ' mV']); 
            end
           
            set(0, 'currentfigure', get(axisHandle, 'parent'));
            set(gcf, 'currentAxes', axisHandle);

            try
                spikes(end) = [];
                loc(end) = [];
                for i = 1:size(outData, 1)
                    % plot thresholds
                    line((spikes - 2) * timePerPoint + startTime, inData(spikes), 'color', [1 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP Height = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                    % plot peaks
                    line((spikes + loc' - 2) * timePerPoint + startTime, inData(spikes + loc'), 'color', [0 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP Height = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                end
            catch
                % at least return something

            end         
        end               
    end