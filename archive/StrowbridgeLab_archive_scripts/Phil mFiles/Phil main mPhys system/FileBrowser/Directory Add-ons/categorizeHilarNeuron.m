function distanceMetric = categorizeHilarNeuron(src, eventInfo, treeHandle)
persistent planeEquation
% calculates the distance metric of Larimer and Strowbridge 2008
% can be called from a fileBrowser or as:
% distanceMetric = categorizeHilarNeuron(fullPathToCellRoot);
% example: categorizeHilarNeuron('D:\data\Cell A')

if ~nargin
    distanceMetric = 'Categorize Hilar Neuron';
    return
end

if ishandle(src)
    cellRoot = treeHandle.SelectedItem.Key;
else
    cellRoot = src;
end

if isempty(planeEquation)
    load('Y:\Larimer\Analysis\Full 12.18.07\classification FINAL.mat');
end
warning off

% set up some constants
maxAmps = 4;
stepLength = 10; % ms
stepGap = 60; % ms
charStep = 2000; % ms length of cell characterization step   

directory = cellRoot(1:find(cellRoot == filesep, 1, 'last'));
cellRoot = cellRoot(find(cellRoot == filesep, 1, 'last') + 1:end);  
        
%check all files in current directory
tempDir = dir(directory);
fileList = {tempDir(~cat(2, tempDir.isdir) & (cellfun(@(x) ~isempty(x), strfind({tempDir.name}, '.mat')) | cellfun(@(x) ~isempty(x), strfind({tempDir.name}, '.dat'))) & cellfun(@(x) ~isempty(x), strfind({tempDir.name}, cellRoot))).name};
if isempty(fileList)
    error('Error: must pass a cell root to categorizeHilarNeuron');
end

cellINprob = nan(10,maxAmps);
cellMeanSpikeTime = nan(10,maxAmps);
cellFastAHP = nan(10,maxAmps);

for q = 1:numel(fileList)            
    %load file
    zData.protocol = readTrace([directory fileList{q}], 1);
    if isempty(zData.protocol)
        continue
    end

    % check to see if this is a coupling type protocol
    for ampIndex = 1:sum(cell2mat(zData.protocol.ampEnable))
        currentStims = findSteps(zData.protocol, ampIndex);
        if size(currentStims, 1) == 4 && diff(currentStims(1:2,1)) == stepLength && diff(currentStims([1 3], 1)) == stepGap
%                     % looks like a two pulse protocol
        elseif size(currentStims, 1) == 2 && diff(currentStims(1:2,1)) >= charStep
            % looks like a cell characterization protocol
            zData = readTrace([directory fileList{q}]);                    
            if diff(currentStims(1:2,2)) < 0
                % looks like a spike-inducer
                for ampIndex = 1:numel(zData.protocol.ampType)
                    if zData.protocol.ampEnable{ampIndex} && zData.protocol.ampStimEnable{ampIndex}
                        tempSpikes = apHeight(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                        if length(tempSpikes) > 4 %&& min(tempSpikes) > .5 * max(tempSpikes)
                            tempLength = find(~isnan(cellFastAHP(:, ampIndex)), 1, 'last') + 1;
                            if isempty(tempLength)
                                tempLength = 1;
                            end
                            [tempData cellMeanSpikeTime(tempLength, ampIndex) cellIsiSlope(tempLength, ampIndex) cellSlopeSpikes(tempLength, ampIndex) cellSlopeTime(tempLength, ampIndex)] = fastAHPSlope2(zData.traceData(currentStims(1, 1) * 1000 / zData.protocol.timePerPoint:currentStims(2,1) * 1000 / zData.protocol.timePerPoint, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                            cellFastAHP(tempLength, ampIndex) = median(tempData(~isnan(tempData)));
                            cellINprob(tempLength, ampIndex) = burstingProbability(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000, 60);                                        
                        end
                    end
                end
            end
            break
        end
    end
end % for q = 1:numel(fileList)          

% write data
ampCount = 0;
for j = find(logical(cell2mat(zData.protocol.ampEnable)))'
    ampCount = ampCount + 1;                    
    distance = planeEquation * [max(cellINprob(:,j)) median(cellMeanSpikeTime(~isnan(cellMeanSpikeTime(:,j)),j)) max(cellFastAHP(:,j)) 1]' ./ sqrt(sum(planeEquation(1:end - 1).^2));
    distanceMetric(ampCount) = log(abs(distance)) .* sign(distance);                    
end % for cell number     

if ~nargout
    for j = 1:numel(distanceMetric)
        if distanceMetric(j) > 0
            disp(['Amp ' sprintf('%0.0f', j)  ', is a MC (' sprintf('%1.2f', distanceMetric(j)) ')']);
        elseif distanceMetric(j) < 0
            disp(['Amp ' sprintf('%0.0f', j)  ', is an IN (' sprintf('%1.2f', distanceMetric(j)) ')']);            
        else
            disp(['Amp ' sprintf('%0.0f', j)  ', is indeterminate']);
        end
    end
end