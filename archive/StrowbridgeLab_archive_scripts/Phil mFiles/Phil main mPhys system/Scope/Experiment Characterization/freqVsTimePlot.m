function stringData = freqVsTimePlot(traceData, protocol, ampNum, axisHandle)
% plot short time fft vs time in colors as a surface
% outData = freqVsTimePlot(traceData, windowLength, overlapRatio, samplingRate)
persistent windowLength
persistent overlapRatio

if ~nargin
    stringData = 'Frequencies vs. Time Plot';
    return
end

if isempty(windowLength)
    windowLength = 1000; % ms
    overlapRatio = 0.5;
end    

stringData = '';

outData = inputdlg({'Window Length (ms)', 'Window Overlap (normalized)'}, '', 1, {num2str(windowLength), num2str(overlapRatio)});

if ~isempty(outData)
    if str2double(outData{1}) > 0
        windowLength = str2double(outData{1});
    else
        error('Window Length must be positive');
    end
    if str2double(outData{2}) < 0 || str2double(outData{2}) > 1
        error('Window Overlap must be on the interval [0 1]');
    else
        overlapRatio = str2double(outData{2});
    end
end

resolution = windowLength * 1000 / protocol.timePerPoint;
surfaceData = nan(int32(resolution / 2 + 1) - 1, numel(1:round(windowLength * 1000 / protocol.timePerPoint * overlapRatio):length(traceData) - windowLength * 1000 / protocol.timePerPoint));
f = 0.001 / protocol.timePerPoint * (1:round(resolution / 2)) / resolution;
timeData = ((1:round(windowLength * 1000 / protocol.timePerPoint * overlapRatio):length(traceData) - windowLength * 1000 / protocol.timePerPoint) + windowLength * 1000 / protocol.timePerPoint / 2)  / (0.001 / protocol.timePerPoint);

counter = 1;
for i = 1:round(windowLength * 1000 / protocol.timePerPoint * overlapRatio):length(traceData) - windowLength * 1000 / protocol.timePerPoint
	Y = fft(traceData(i:i + windowLength * 1000 / protocol.timePerPoint - 1), resolution);
	Pyy = Y.* conj(Y) / resolution;
	surfaceData(:,counter) = Pyy(2:int32(resolution / 2 + 1))';
	counter = counter + 1;
end

% saturate the top and bottom 5% of the data
surfaceData = surfaceData(1:125, :);
[indices indices] = sort(reshape(surfaceData, [], 1));
cutPoint = find(surfaceData(indices) > .05*mean(surfaceData(indices(round(end*.9):end))), 1, 'first');
surfaceData(indices) = 1:length(indices);
surfaceData(indices(1:cutPoint)) = cutPoint;

% create the figure
figure('name', 'Frequency vs Time', 'numbertitle', 'off')
surface(timeData, f(1:125), surfaceData) %reshape(indices, size(surfaceData)), 'cDataMapping', 'direct');
xlabel('Time (s)')
ylabel('Freq (Hz)')
zlabel('Power')