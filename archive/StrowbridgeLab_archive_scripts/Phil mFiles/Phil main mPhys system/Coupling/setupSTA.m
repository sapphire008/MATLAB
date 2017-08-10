function figHandle = setupSTA(protocol, windowSize, windowDelay)

figHandle = [];
try
    [stims stimLength channels] = findSteps(protocol);
catch
    return
end

samplingRate = 1000 / protocol.timePerPoint; % samples per msec
stims = (stims * samplingRate);
yData = ones(1, 2 * windowSize + windowDelay + 1);

% create display window
figHandle = figure('Name', ['Spike-triggered Average: ' protocol.fileName(1:find(protocol.fileName == 'S', 1, 'last') - 2)], 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0 .07 1 .93]);

for index = 1:length(stims) * length(channels)
    xData(:, index) = stims(mod(index - 1, size(stims, 1)) + 1):stims(mod(index - 1, size(stims, 1)) + 1) + 2 * windowSize + windowDelay;
    axes('buttondownfcn', 'zoomSTA', 'Position', [.02 + mod(index + size(stims, 1) - 1, size(stims, 1)) / (size(stims, 1) / .98) .02 + (size(channels, 2) - 1 - fix((index - 1) / size(stims, 1))) / (size(channels, 2) / .98)  .98 / size(stims, 1) .98 / size(channels, 2)]);
    if index < size(stims, 1) * (size(channels, 2) - 1)
        set(gca, 'xticklabel', '')
    end
    if ~((index + size(stims, 1) - 1) / size(stims, 1) == fix((index + size(channels, 2) * 2 - 1) / size(stims, 1)))
        set(gca, 'yticklabel', '')
    end
    line(xData(:, index) / samplingRate, yData, 'Color', [0 0 0]); % black for pretty
    uicontrol(...
        'Units','normalized',...
        'Position',[.02 + mod(index + size(channels, 2) * 2 - 1, size(stims, 1)) / (size(stims, 1) / .98) .02 + (size(channels, 2) - 1 - fix((index - 1) / size(stims, 1))) / (size(channels, 2) / .98)  .056 .01],...
        'Style','text',...
        'HorizontalAlignment', 'right',...
        'String', '0.0',...
        'ForeGroundColor', [1 0 0]);
    uicontrol(...
        'Units','normalized',...
        'Position',[.08 + mod(index + size(channels, 2) * 2 - 1, size(stims, 1)) / (size(stims, 1) / .98) .02 + (size(channels, 2) - 1 - fix((index - 1) / size(stims, 1))) / (size(channels, 2) / .98)  .056 .01],...
        'Style','text',...
        'HorizontalAlignment', 'right',...
        'String', '0.0',...
        'ForeGroundColor', [0 0 1]);
end

% set userData of figure to include all of our info
set(figHandle, 'userData', {channels, zeros(length(stims), 1), stims, zeros(size(channels, 2), size(stims, 1), length(yData)), stimLength * samplingRate, windowSize * protocol.timePerPoint / 1000, windowDelay * protocol.timePerPoint / 1000});