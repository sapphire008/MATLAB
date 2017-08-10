function outData = apThreshold(inData, timePerPoint, startTime, axisHandle)
% thresholds = APthreshold(dataTrace, timerPerPoint, startTime, outputAxisHandle);
% defaults:
%   timePerPoint = 0.2 ms
%   startTime = 0 ms
%   outputAxisHandle is a handle to a new newScope figure
%
% determine the membrane potential (in mV) where the maximum of the second
% derivative in the period immediately before the spike, looking for the
% first time that the second derivative has a peak in that period that is
% at least 25% of that height, and then searching backward from that peak
% to the first time that the second derivative is less than 10% of that
% maximum peak

% respond with the menu text if no inputs given
if ~nargin
    outData = 'AP Threshold';
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
    
    spikes = detectSpikes(inData, 25, 1);
    if ~isempty(spikes)
        outData = inData(spikes);

        if ~nargout || (nargin == 4 && ishandle(axisHandle))
            
            if nargin < 4
                axisHandle = newScope(inData, startTime:timePerPoint:(length(inData) - 1)*timePerPoint - startTime, 'Trace V');  
                axisHandle = axisHandle.axes(1);
				set(get(axisHandle, 'parent'), 'name', ['AP Threshold, Mean = ' num2str(mean(outData) * timePerPoint, '%3.2f') ' mV']);       
            end
           
            set(0, 'currentfigure', get(axisHandle, 'parent'));
            set(gcf, 'currentAxes', axisHandle);

            try
                for i = 1:size(outData, 1)
                    % plot thresholds
                    line((spikes - 1) * timePerPoint + startTime, inData(spikes), 'color', [0 1 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP Threshold = ' sprintf('%6.1f', outData(i)) ' mV'')']);
                end
            catch
                % at least return something

            end         
        end       
    end