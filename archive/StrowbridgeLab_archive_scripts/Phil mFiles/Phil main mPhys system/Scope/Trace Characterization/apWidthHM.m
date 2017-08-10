function outData = apWidthHM(inData, timePerPoint, startTime, axisHandle)
% apWidthsAtHalfMax = APWidthHM(dataTrace, timerPerPoint, startTime, outputAxisHandle);
% defaults:
%   timePerPoint = 0.2 ms
%   startTime = 0 ms
%   outputAxisHandle is a handle to a new newScope figure
%
% determine the time (in ms) from the point vertically half way between
% where the AP crosses threshold and the peak to the point at which it is
% passing back by this height on the way down

% respond with the menu text if no inputs given
if ~nargin
    outData = 'AP Width at Half Max';
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

    % find the APs at threshold
    spikeThreshs = [detectSpikes(inData, 25, 1) length(inData)];
    spikePeaks = detectSpikes(inData, 25, 4);
    if length(spikeThreshs) > 1
        riseLoc = zeros(1, numel(spikePeaks));
        fallLoc = riseLoc;
        riseVal = riseLoc;
        fallVal = riseLoc;
        spikeIndex = 1;
        while spikeIndex <= length(spikePeaks)
            % interpolate the data at 100x using cubic splines
            interpolatedData = interp1(spikeThreshs(spikeIndex):spikeThreshs(spikeIndex + 1), inData(spikeThreshs(spikeIndex):spikeThreshs(spikeIndex + 1)), spikeThreshs(spikeIndex):.01:spikeThreshs(spikeIndex + 1), 'spline');

            % find the data point that is halfway up
            riseLoc(spikeIndex) = find(interpolatedData >= inData(spikeThreshs(spikeIndex)) + (inData(spikePeaks(spikeIndex)) - inData(spikeThreshs(spikeIndex))) / 2, 1, 'first');

            % find the data point that is halfway down
            tempFallLoc = min([find(interpolatedData(riseLoc(spikeIndex) + 1:end) <= inData(spikeThreshs(spikeIndex)) + (inData(spikePeaks(spikeIndex)) - inData(spikeThreshs(spikeIndex))) / 2, 1, 'first') + riseLoc(spikeIndex) + 1 length(interpolatedData)]);

            if ~isempty(tempFallLoc)
                % the last spike descends in the window
                fallLoc(spikeIndex) = tempFallLoc;
                riseVal(spikeIndex) = interpolatedData(riseLoc(spikeIndex));
                fallVal(spikeIndex) = interpolatedData(fallLoc(spikeIndex));
            else
                fallLoc(spikeIndex) = [];
                riseVal(spikeIndex) = [];
                fallVal(spikeIndex) = [];
                riseLoc(spikeIndex) = [];
                spikePeaks(spikeIndex) = [];
                spikeThreshs(spikeIndex) = [];
                spikeIndex = spikeIndex - 1;
            end
            spikeIndex = spikeIndex + 1;
        end

        outData = (fallLoc - riseLoc) / 100; % / 100 is to get us back out of interpolation units
		outData = outData * timePerPoint;

        if ~nargout || (nargin == 4 && ishandle(axisHandle))

            if nargin < 4
                axisHandle = newScope(inData, startTime:timePerPoint:(length(inData) - 1)*timePerPoint - startTime, 'Trace V');
                axisHandle = axisHandle.axes(1);
				set(get(axisHandle, 'parent'), 'name', ['AP Widths at half maximum, Mean Width = ' num2str(mean(outData), '%3.2f') ' ms']);
            end

            set(0, 'currentfigure', get(axisHandle, 'parent'));
            set(gcf, 'currentAxes', axisHandle);

            riseLoc = spikeThreshs(1:end - 1) + riseLoc / 100;
            fallLoc = spikeThreshs(1:end - 1) + fallLoc / 100;
            try
                for i = 1:size(outData, 1)
                    % plot starts
                    line((riseLoc - 1) * timePerPoint + startTime, riseVal, 'color', [1 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP WidthHM = ' sprintf('%6.3f', outData(i) * timePerPoint) ' msec'')']);
                    % plot stops
                    line((fallLoc - 1) * timePerPoint + startTime, fallVal, 'color', [0 0 0], 'linestyle', 'none', 'marker', '+', 'markersize', 12, 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''AP WidthHM = ' sprintf('%6.3f', outData(i) * timePerPoint) ' msec'')']);
                end
            catch
                % at least return something

            end
        end
    end