function couplingWindow = checkCoupling(zData, windowSize, windowDelay, options)
% looks for synaptic coupling between cells (output is graphical)
% figHandle = checkCoupling(fileName, [windowSize], [windowDelay], [options])
% figHandle = checkCoupling(zData, [windowSize], [windowDelay], [options])
% if using fitting option -1, no IPSPs are detected

if nargin < 2
    windowSize = 5; % msec
end

if nargin < 3
    windowDelay = .5; % msec
end

if nargin < 4
    % options[fitDecayRise, findPSPs, displayMatches, rezero] as boolean
    options = [0 1 1 1];
end

% define some constants
spikeDelay = 25; % ms after the end of a step that a spike can be detected (should encompass falling side of spike)
numControlWindows = 10; % number of control windows to take before each stimulus pair
maxResponses = 150; % maximum number of post responses to search

if numControlWindows * windowSize > 200
    numControlWindows = fix(200 / windowSize);
    warning(['Too many control windows requested.  Using ' sprintf('%1.0f', numControlWindows) ' instead']);
end

if ischar(zData)   
    zData = readTrace(zData);
else
    if nargin < 1
        error('Must input at least traces and protocol structure')
    end
    if numel(zData.protocol) > 1
        % call this function recursively
        numChannels = numel(zData.protocol(1).channelNames);
        for episodeIndex = 0:numel(zData.protocol) - 1
            switch nargin
                case 1
                    checkCoupling(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)));
                case 2
                    checkCoupling(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)), windowSize);
                case 3
                    checkCoupling(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)), windowSize, windowDelay);
                otherwise
                    checkCoupling(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)), windowSize, windowDelay, options);
            end
        end
        return
    end
end

% transfer these from mSec to points
windowSize = round(1000 / zData.protocol.timePerPoint * windowSize);
windowDelay = round(1000 / zData.protocol.timePerPoint * windowDelay);

rootKids = get(0, 'children');
% make sure that setupCoupling was run
if numel(rootKids) == 1
	couplingWindow = rootKids(strfind(get(rootKids, 'name'), 'Coupling: ')); 
elseif numel(rootKids) > 1
    couplingWindow = rootKids(~cellfun('isempty', strfind(get(rootKids, 'name'), 'Coupling: '))); 
else
    couplingWindow = [];
end
if isempty(couplingWindow)
    couplingWindow = setupCoupling(zData.protocol, windowSize + windowDelay);
    if isempty(couplingWindow)
        return
    end
end

if length(couplingWindow) > 1
    % we have multiple coupling windows going so add this data to the right one only
    for i = 1:length(couplingWindow)
        windowName = get(couplingWindow(i), 'name');
        if strcmp(windowName(11:end), zData.protocol.fileName(1:find(zData.protocol.fileName == 'S', 1, 'last') - 2))
            couplingWindow = couplingWindow(i);
            break
        end
    end
    if length(couplingWindow) > 1 % we didn't find a match so make a new window
        tempHandle = setupCoupling(zData.protocol, windowSize + windowDelay);
        if isempty(tempHandle)
            return
        end        
        couplingWindow = tempHandle;
    end
end

tempData = get(couplingWindow, 'userData');
channels = tempData{1};
numProcessed = tempData{2};
stims = tempData{3};
% this is of the format (cell, stim,, [sequence, episode, amp,
% rise, timePostSpike, decay, time since whole cell, drug #, spikeTime], :)
PSPdata = tempData{4};
stimLength = tempData{5};

% if there's no chance that we'll use this information then dump
if any(numProcessed(1:end/1.5) >= maxResponses)
    return
end

% check to make sure we haven't turned off an amp since our last run
if sum(cell2mat(zData.protocol.ampEnable)) < length(channels)
   % an amp was turned off so remake the figure
    newWindow = setupCoupling(zData.protocol, windowSize + windowDelay);
    tempData = get(newWindow, 'userData');
    tempChannels = tempData{1};
    tempStims = tempData{3};
    
    % if an axis was zoomed then unzoom it
    set(couplingWindow, 'currentPoint', [0 0]);
    zoomCoupling(couplingWindow);
    
    % copy the pertinent information from the old figure to the new one
    axesHandles = get(couplingWindow, 'children');
    tempAxesHandles = get(newWindow, 'children');
    newStatus = zeros(size(channels));
    for i = 1:length(tempChannels)
        newStatus(i) = find(stims == tempStims(i * 2))/ 2;
    end
    newStatus = newStatus(newStatus > 0);
    
    for i = 1:length(tempChannels)
        for j = 1:length(tempChannels)
            handles = copyobj(axesHandles(((length(axesHandles) - 2 - ((newStatus(i) - 1) * length(channels) + newStatus(j) - 1) * 6 - 5)):(length(axesHandles) - 2 - ((newStatus(i) - 1) * length(channels) + newStatus(j) - 1) * 6)), newWindow);
            pos = get(tempAxesHandles(((length(tempAxesHandles) - 2 - ((i - 1) * length(tempChannels) + j - 1) * 6) - 5):(length(tempAxesHandles) - 2 - ((i - 1) * length(tempChannels) + j - 1) * 6)), 'position');
            for k = 1:6
               set(handles(k), 'position', pos{k}); 
               if k / 3 == round(k / 3)
                   % set y axis visible or not
                   if j == 1 && k == 6
                       set(handles(k), 'yticklabelmode', 'auto')
                   else
                       set(handles(k), 'yticklabel', '')                       
                   end
                   % set x axis visible or not
                   if i == length(tempChannels)
                       set(handles(k), 'xticklabelmode', 'auto')
                   else
                       set(handles(k), 'xticklabel', '')                       
                   end                   
               end
            end
        end
    end
    % clear out the old stuff and rename our variables
    delete(tempAxesHandles);
    numProcessed = numProcessed(sort([2 * newStatus - 1 2 * newStatus 2 * length(channels) + newStatus]));
    PSPdata = PSPdata(newStatus, [sort([2 * newStatus - 1 2 * newStatus]) end], :, :);
    channels = tempChannels;
    stims = tempStims;
    close(couplingWindow);
    couplingWindow = newWindow;
end

try
    tempStims = findSteps(zData.protocol);
    samplingRate = 1000 / zData.protocol.timePerPoint; % samples per msec
    tempStims = tempStims * samplingRate;    
catch
    % stims probably weren't the same length
    return
end
if ~(numel(tempStims) == numel(stims) && all(all(tempStims == stims))) 
    % this oughtn't to be here
    return
end

% if any(mean(zData.traceData(:,channels)) < -70)
%     return
% end
        
figKids = get(couplingWindow, 'children');
figKids = figKids(cellfun('isempty', strfind(get(figKids, 'type'), 'uimenu')));
% if a trace is zoomed then corret for it
locInfo = getappdata(couplingWindow, 'zoomLocation');
if locInfo(1) > 0 % there is some reording of traces present
    figKids = figKids([4:locInfo(1) 1:3 locInfo(1) + 1:end]);
end

tempTraces = get(figKids, 'children');
j = 1;
for i = length(tempTraces):-1:1
    if ~isempty(tempTraces{i})
        traces(j) = tempTraces{i}(end);
        j = j + 1;
    end
end
xData = (cell2mat(get(traces, 'xData')) * samplingRate)';

% show display
for index = 1:length(stims) * length(channels)
    set(traces(index), 'YData', zData.traceData(xData(:,index), channels(fix((index + size(channels, 2) * 2 - 1) / (size(channels, 2) * 2)))));
end

if options(2)
    % find spikes
    for stimIndex = 1:length(stims)     
        tempSpike = detectSpikes(zData.traceData(stims(stimIndex):stims(stimIndex) + stimLength + spikeDelay, channels(fix((stimIndex + 1) / 2))));
        if length(tempSpike) < 1 || mean(zData.traceData(stims(stimIndex):stims(stimIndex) +  stimLength + spikeDelay, channels(fix((stimIndex + 1) / 2)))) > -10
            % no spikes were detected
            spikes(stimIndex, 1) = length(zData.traceData);
        else
            if length(tempSpike) > 1 && any(tempSpike(2:end) - tempSpike(1) <= windowSize + windowDelay)
                % there is a second spike in the window, so treat as no spike detected
                spikes(stimIndex, 1) = length(zData.traceData);
            else
                spikes(stimIndex, 1) = tempSpike(1);
                numProcessed(stimIndex) = numProcessed(stimIndex) + 1;
            end
        end
    end

    session = regexp(zData.protocol.fileName, 'S[0-9]+.E', 'match');
    session = str2double(session{1}(2:end - 2));
    episode = regexp(zData.protocol.fileName, 'E[0-9]+.', 'match');
    episode = str2double(episode{1}(2:end - 1));
    
    controlWindows = zeros(numControlWindows * numel(stims) / 2, 1);
    for controlIndex = 0:numel(stims) / 2 - 1
        controlWindows(numControlWindows * controlIndex + (1:numControlWindows)) = stims(2*(controlIndex + 1) - 1) - (windowSize:windowSize:windowSize * numControlWindows)';
    end    
    % look for coupling
    for cellIndex = 1:size(channels, 2)
        % look for PSPs
        switch options(1)             
            case 1
                % fit decay time
                PSPs = [detectPSPs(zData.traceData(:, channels(cellIndex)), 1, [stims([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + spikes([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + windowDelay; controlWindows], windowSize, 'alphaFit', 1, 'decayFit', 1, 'derThresh', .1, 'minAmp', -50, 'minTau', 15, 'maxTau', 150, 'maxAmp', -.05, 'minYOffset', mean(zData.traceData(:, channels(cellIndex))) - 5, 'maxYOffset', mean(zData.traceData(:, channels(cellIndex))) + 5); detectPSPs(zData.traceData(:, channels(cellIndex)), 0, [stims([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + spikes([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + windowDelay; controlWindows], windowSize, 'alphaFit', 1, 'decayFit', 1, 'derThresh', .1, 'minAmp', .15, 'minTau', 5, 'maxTau', 75, 'maxAmp', 50, 'minYOffset', mean(zData.traceData(:, channels(cellIndex))) - 15, 'maxYOffset', mean(zData.traceData(:, channels(cellIndex))) + 15)];
            case -1 
                % don't even fit alpha function
                PSPs = detectPSPs(zData.traceData(:, channels(cellIndex)), 0, [stims([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + spikes([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + windowDelay; controlWindows], windowSize, 'errThresh', inf, 'minDecay', -inf, 'maxDecay', inf, 'maxAmp', inf, 'minAmp', -inf, 'minYOffset', -inf, 'maxYOffset', inf, 'minTau', -inf, 'maxTau', inf);
            case 0
                % fit alpha function
                PSPs = [detectPSPs(zData.traceData(:, channels(cellIndex)), 1, [stims([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + spikes([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + windowDelay; controlWindows], windowSize, 'alphaFit', 1, 'derThresh', .1, 'minAmp', -50, 'minTau', 8, 'maxTau', 150, 'maxAmp', -.1, 'minYOffset', mean(zData.traceData(:, channels(cellIndex))) - 15, 'maxYOffset', mean(zData.traceData(:, channels(cellIndex))) + 15); detectPSPs(zData.traceData(:, channels(cellIndex)), 0, [stims([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + spikes([1:cellIndex * 2 - 2 cellIndex * 2 + 1:length(stims)]) + windowDelay; controlWindows], windowSize, 'alphaFit', 1, 'derThresh', .1, 'minAmp', .25, 'minTau', 5, 'maxTau', 40, 'minDecay', -inf, 'maxDecay', inf, 'maxAmp', 5, 'minYOffset', mean(zData.traceData(:, channels(cellIndex))) - 15, 'maxYOffset', mean(zData.traceData(:, channels(cellIndex))) + 15)];            
        end
        % find mean PSPs away from stims
        baselinePSPs = zeros(size(PSPs, 1), 1);
        for controlIndex = 0:numel(stims) / 2 - 1
            baselinePSPs = baselinePSPs | (PSPs(:,3) > controlWindows(numControlWindows * (controlIndex + 1)) & PSPs(:,3) < controlWindows(numControlWindows * controlIndex + 1));
        end
        baselinePSPs = find(baselinePSPs);
        if ~isempty(baselinePSPs)
            PSPdata(cellIndex, end, :, length(find(PSPdata(cellIndex, end, 1, :)) + 1) + 1:length(find(PSPdata(cellIndex, end, 1, :))) + length(baselinePSPs)) = [repmat(session, 1, length(baselinePSPs))' repmat(episode, 1, length(baselinePSPs))' PSPs(baselinePSPs, 1:2) PSPs(baselinePSPs, 3) / samplingRate PSPs(baselinePSPs, 4) repmat(zData.protocol.cellTime, 1, length(baselinePSPs))' repmat(zData.protocol.drug(1), 1, length(baselinePSPs))' repmat(NaN, 1, length(baselinePSPs))']';
        end
        numProcessed(size(stims, 1) + cellIndex) = numProcessed(size(stims, 1) + cellIndex) + 1;
        % sort PSPs into windows
        for stimIndex = 1:size(stims, 1)
            if ~(numProcessed(stimIndex) > maxResponses || stimIndex / cellIndex == 2 || (stimIndex + 1) / cellIndex == 2 || spikes(stimIndex, 1) == length(zData.traceData))% don't look for stimuli onto self
                % check for PSPs
                whenCoupling = find(PSPs(:,3) > stims(stimIndex) + spikes(stimIndex) + windowDelay & PSPs(:,3) < stims(stimIndex) + spikes(stimIndex) + windowSize);
                if size(whenCoupling, 1) > 1
                    [junk, junk] = max(PSPs(whenCoupling, 3)); % if more than one then just use the first I/E
                    whenCoupling = whenCoupling(junk);
                end
                if ~isempty(whenCoupling)
                    PSPdata(cellIndex, stimIndex, :, length(find(PSPdata(cellIndex, stimIndex, 1, :))) + 1:length(find(PSPdata(cellIndex, stimIndex, 1, :))) + length(whenCoupling)) = [session episode PSPs(whenCoupling, 1) PSPs(whenCoupling, 2) / samplingRate (PSPs(whenCoupling, 3) - spikes(stimIndex) - stims(stimIndex)) / samplingRate PSPs(whenCoupling, 4) / samplingRate zData.protocol.cellTime zData.protocol.drug(1) stims(stimIndex) + spikes(stimIndex)];
                    if options(3)
                        if PSPs(whenCoupling, 1) < 0
                            lineColor = [0 0 1];
                        else
                            lineColor = [1 0 0];
                        end
                        line('parent', get(traces(stimIndex + size(stims, 1) * (cellIndex - 1)), 'parent'), 'xData', xData(spikes(stimIndex):size(xData, 1), stimIndex) / samplingRate, 'yData', zData.traceData(xData(spikes(stimIndex):size(xData, 1),stimIndex), channels(cellIndex)), 'Color', lineColor);
                        if options(4)
                            % rezero traces so that scaling stays pretty
                            kids = get(get(traces(stimIndex + size(stims, 1) * (cellIndex - 1)), 'parent'), 'children');
                            referenceYOffset = mean(zData.traceData(xData(spikes(stimIndex):spikes(stimIndex) + 5, stimIndex), channels(cellIndex))); % use current trace as reference
                            for kidIndex = 1:length(kids) - 1
                                tempYData = get(kids(kidIndex), 'yData');
                                tempXData = get(kids(kidIndex), 'xData');
                                set(kids(kidIndex), 'yData', tempYData - mean(tempYData(1:5)) + referenceYOffset, 'xData', (xData(spikes(stimIndex), stimIndex):xData(spikes(stimIndex), stimIndex) + length(tempXData) - 1) / samplingRate);
                            end
                        end
                    end
                end
                
                set(figKids(length(figKids) - (stimIndex + (cellIndex - 1) * size(stims, 1)) * 3 + 2), 'String', [num2str(length(find(PSPdata(cellIndex, stimIndex, 3, :) > 0))) '/' num2str(length(find(PSPdata(cellIndex, end, 3, :) > 0))) ' p = ' num2str(chiTest([length(find(PSPdata(cellIndex, stimIndex, 3, :) > 0)) numProcessed(stimIndex); length(find(PSPdata(cellIndex, end, 3, :) > 0)) numProcessed(size(stims, 1) + cellIndex) * length(controlWindows)]), '%-.4f')]);
                set(figKids(length(figKids) - (stimIndex + (cellIndex - 1) * size(stims, 1)) * 3 + 1), 'String', [num2str(length(find(PSPdata(cellIndex, stimIndex, 3, :) < 0))) '/' num2str(length(find(PSPdata(cellIndex, end, 3, :) < 0))) ' p = ' num2str(chiTest([length(find(PSPdata(cellIndex, stimIndex, 3, :) < 0)) numProcessed(stimIndex); length(find(PSPdata(cellIndex, end, 3, :) < 0)) numProcessed(size(stims, 1) + cellIndex) * length(controlWindows)]), '%-.4f')]);
            end
        end
    end
end

% only remove episodes for coupling, not control traces
numProcessed(1:end / 1.5) = numProcessed(1:end / 1.5) - (numProcessed(1:end / 1.5) > maxResponses);
set(couplingWindow, 'userData', {channels, numProcessed, stims, PSPdata, stimLength, numControlWindows * numel(stims) / 2});