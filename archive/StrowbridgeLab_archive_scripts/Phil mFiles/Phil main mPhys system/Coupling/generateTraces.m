function [dataVals importantFiles] = generateTraces(resultData, fileNames, matchName, cell, stim, pspType, timeWindow, rezero)
% [dataVals indices]  = generateTraces(resultData, fileNames, matchName, cell, stim, pspType, timeWindow, rezero)

if nargin < 8
    rezero = 0;
end

tempData = strfind(fileNames, matchName);
importantFiles = find(~cellfun('isempty', tempData));
importantFiles = importantFiles(resultData(importantFiles, 1) == cell & resultData(importantFiles, 2) == stim);
if pspType == 0
    importantFiles = importantFiles(resultData(importantFiles, 3) > 0);
else
    importantFiles = importantFiles(resultData(importantFiles, 3) < 0);  
end
if nargout == 0
    % create output window
    figure('Name', [matchName ' Cell ' num2str(cell) ' Stim ' num2str(stim)],...
        'NumberTitle', 'off',...
        'Units', 'normalized',...
        'position', [.1 .1 .8 .8],...
        'toolbar', 'none',...
        'menubar', 'none');
end

dataVals = zeros(length(importantFiles), max(timeWindow) - min(timeWindow) + 1);

traceIndex = 1;
% open the files and add their plots
for i = importantFiles
    zData = readTrace(fileNames{i});
    if ~isnan(resultData(i,9))
        if rezero
            dataVals(traceIndex,:) = zData.traceData(resultData(i,9) + timeWindow, whichChannel(zData.protocol, cell)) - mean(zData.traceData(resultData(i, 9) - 10:resultData(i,9), whichChannel(zData.protocol, cell)));
        else
            dataVals(traceIndex,:) = zData.traceData(resultData(i,9) + timeWindow, whichChannel(zData.protocol, cell));
        end
    else
        if rezero
            dataVals(traceIndex,:) = zData.traceData(round(resultData(i,3)*1000/zData.protocol.timePerPoint) + timeWindow, whichChannel(zData.protocol, cell)) - mean(zData.traceData(round(resultData(i,3)*1000/zData.protocol.timePerPoint) - 10:round(resultData(i,3)*1000/zData.protocol.timePerPoint), whichChannel(zData.protocol, cell)));
        else
            dataVals(traceIndex,:) = zData.traceData(round(resultData(i,3)*1000/zData.protocol.timePerPoint) + timeWindow, whichChannel(zData.protocol, cell));
        end        
    end
    if nargout == 0
        line(((0:size(dataVals, 2) - 1) + timeWindow(1)) * zData.protocol.timePerPoint / 1000, dataVals(traceIndex, :), 'color', [0 0 0]);
    end
    traceIndex = traceIndex + 1;
end

if nargout == 0
    % plot the mean
    line(((0:size(dataVals, 2) - 1) + timeWindow(1)) * zData.protocol.timePerPoint / 1000, mean(dataVals, 1), 'linewidth', 5);
end