function numStims = covarianceAnalysisGeneral(zData, pairedGap)
xData = -10:.2:100; % in ms
xIndices = int32(xData .* (1000 / zData.protocol(1).timePerPoint));
dataChannel = 2; % channel on which data is to be used
apThresh = 0; % mV for rejecting traces as having an AP in the window

% find stim times for all combinations of 4
if nargin < 2
    error('Second arguement must be a paired stim spacing in ms');
end
pairedGap = 1000 / zData.protocol(1).timePerPoint * pairedGap; % ms

stimData = cell(4, 4);
for i = 1:4
    for j = 1:4
        stimData{i,j} = nan(100, numel(xIndices));
    end
end
numStims = ones(4);

% collect data
for i = 1:numel(zData.protocol)
    tempStims = findStims(zData.protocol(i));
    for j = 1:4
        for k = 1:size(tempStims{j}, 1)
            pairedStim = 0;
            for l = [1:j-1 j+1:4]
                for m = 1:size(tempStims{l}, 1)
                    stimGap = tempStims{l}(m, 1) - tempStims{j}(k, 1);
                    if  stimGap == pairedGap && ~any(zData.traceData{dataChannel}(tempStims{j}(k, 1) + xIndices, i) > apThresh)
                        stimData{j, l}(numStims(j,l), :) = zData.traceData{dataChannel}(tempStims{j}(k, 1) + xIndices, i);
                        numStims(j,l) = numStims(j,l) + 1;
                    end
                    if abs(stimGap) == pairedGap    
                        pairedStim = 1;
                    end
                end
            end
            if ~pairedStim && ~any(zData.traceData{dataChannel}(tempStims{j}(k, 1) + xIndices, i) > apThresh)
               stimData{j, j}(numStims(j,j), :) = zData.traceData{dataChannel}(tempStims{j}(k, 1) + xIndices, i);
               numStims(j,j) = numStims(j,j) + 1;
            end
        end
    end
end

% generate means and SEs
meanData = nan(4,4,numel(xIndices));
errData = meanData;
for i = 1:4
    for j = 1:4
        meanData(i,j,:) = nanmean(stimData{i,j});
        errData(i,j,:) = nanstd(stimData{i,j}) ./ sqrt(numStims(i,j) - 2) * 1.96;
    end
end

% plot raw covariance matrix (with estimated covariances)
figHandle = figure('numbertitle', 'off', 'name', 'Actual combinations in red, linear combinations in black');
minVal = inf;
maxVal = -inf;
for i = 1:4
    for j = 1:4
        subplot(4,4,(i - 1) * 4 + j);
        
        tempMean = squeeze(meanData(i,j,:));
        tempErr = squeeze(errData(i,j,:));
        line(xData, tempMean, 'color', 'r', 'lineWidth', 2);
        line(xData, tempMean - tempErr, 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
        line(xData, tempMean + tempErr, 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
        
        if i ~=j
            linMean = squeeze(meanData(i,i,:) + circshift(meanData(j,j,:), [0 0 pairedGap]) - mean(meanData(j,j,1:5)));
            linErr = sqrt(squeeze(errData(i,i,:)).^2 + squeeze(circshift(errData(j,j,:), [0 0 pairedGap])).^2);
            line(xData, linMean, 'color', 'k', 'lineWidth', 2);
            line(xData, linMean - linErr, 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
            line(xData, linMean + linErr, 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');   
        end
        set(gca, 'xlim', [xData(1) xData(end)]);
        if exist('linMean', 'var')
            minVal = min([minVal min(tempMean - tempErr) min(linMean - linErr)]);
            maxVal = max([maxVal max(tempMean + tempErr) max(linMean + linErr)]);     
        else
            minVal = min([minVal min(tempMean - tempErr)]);
            maxVal = max([maxVal max(tempMean + tempErr)]);     
        end
    end
end
kids = get(figHandle, 'children');
set(kids, 'ylim', [-75 maxVal]);
set(figHandle, 'WindowButtonMotionFcn', @growSubplot, 'userData', get(kids(1), 'position'), 'units', 'normalized');
subplot(4,4,1)
title('Second Stim');
ylabel('First Stim');

% plot orderings
figHandle = figure('numbertitle','off', 'name','Black is stated ordering, red is reversed');
minVal = inf;
maxVal = -inf;
for i = 1:4
    for j = 1:4
        if i > j
            subplot(3,3,(i - 2) * 3 + j);
            tempMean = squeeze(meanData(i,j,:));
            tempErr = squeeze(errData(i,j,:));  
            
            line(xData, tempMean, 'color', 'k', 'lineWidth', 2);
            line(xData, tempMean - tempErr, 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
            line(xData, tempMean + tempErr, 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');   
            minVal = min([minVal min(tempMean - tempErr)]);
            maxVal = max([maxVal max(tempMean + tempErr)]);            

            tempMean = squeeze(meanData(j,i,:));
            tempErr = squeeze(errData(j,i,:));  
            line(xData, tempMean, 'color', 'r', 'lineWidth', 2);
            line(xData, tempMean - tempErr, 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
            line(xData, tempMean + tempErr, 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');   
            
            set(gca, 'xlim', [xData(1) xData(end)]);
            minVal = min([minVal min(tempMean - tempErr)]);
            maxVal = max([maxVal max(tempMean + tempErr)]);
        end
    end
end
subplot(3,3,1)
title('Second Stim');
ylabel('First Stim');
kids = get(figHandle, 'children');
set(kids, 'ylim', [-75 maxVal]);
set(figHandle, 'WindowButtonMotionFcn', @growSubplot, 'userData', get(kids(1), 'position'), 'units', 'normalized');

function growSubplot(varargin)
% growSubplot
% this function blows up the plot over which the mouse is hovering when
% many subplots are present

figureZoom = 2;
currentLoc = get(gcf, 'CurrentPoint');

kids = get(gcf, 'children');
whereKids = get(kids, 'position');
for index = 1:4
    for index2 = 1:length(whereKids)
        newKids(index, index2) = whereKids{index2}(index);
    end
end
whichAxis = find(newKids(1,:) < currentLoc(1) & (newKids(1,:) + newKids(3,:)) > currentLoc(1) & newKids(2,:) < currentLoc(2) & (newKids(2,:) + newKids(4,:)) > currentLoc(2), 1);

if whichAxis > 1
    set(kids(1), 'position', get(gcf, 'userData'));
    set(gcf, 'userData', get(kids(whichAxis), 'position'));
    tempPosition = get(kids(whichAxis), 'position') * [1 0 0 0; 0 1 0 0; -0.5 * (figureZoom - 1) 0 figureZoom 0; 0 -0.5 * (figureZoom - 1) 0 figureZoom];
    % check to make sure that we didn't leave the figure
    if tempPosition(1) < .05; tempPosition(1) = .05; end
    if tempPosition(2) < .05; tempPosition(2) = .05; end
    if tempPosition(1) + tempPosition(3) > 1; tempPosition(1) = 1 - tempPosition(3); end
    if tempPosition(2) + tempPosition(4) > 1; tempPosition(2) = 1 - tempPosition(4); end
    
    set(kids(whichAxis), 'position',  tempPosition);
    set(gcf, 'children', [kids(whichAxis); kids(kids ~= whichAxis)]);
%     set(gcf, 'name', get(kids(whichAxis), 'userdata'));
else
    if isempty(whichAxis)
        set(kids(1), 'position', get(gcf, 'userData'));
    end
end