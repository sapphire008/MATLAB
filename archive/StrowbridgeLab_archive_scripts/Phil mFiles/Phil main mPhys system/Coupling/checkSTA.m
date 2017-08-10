function couplingWindow = checkSTA(zData, windowSize, windowDelay)
% used to find possible coupling via a spike-triggered average across cells.
% The significance statistic uses a Z-test to assess whether the points
% occuring in the triggered window are likely to have been drawn from a
% random distribution with the same mean and standard deviation of the
% control window (both windows are averages over all successes).  There
% ought to be a more power way to use all of the data.

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
                    checkSTA(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)));
                case 2
                    checkSTA(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)), windowSize);
                case 3
                    checkSTA(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)), windowSize, windowDelay);
                otherwise
                    checkSTA(struct('traceData', zData.traceData(:, episodeIndex * numChannels + (1:numChannels)), 'protocol', zData.protocol(episodeIndex + 1)), windowSize, windowDelay, options);
            end
        end
        return
    end
end

if nargin < 2
    windowSize = 5; % msec
end

if nargin < 3
    windowDelay = .5; % msec
end

% transfer these from mSec to points
windowSize = round(1000 / zData.protocol.timePerPoint * windowSize);
windowDelay = round(1000 / zData.protocol.timePerPoint * windowDelay);

rootKids = get(0, 'children');
% make sure that setupCoupling was run
if numel(rootKids) == 1
	couplingWindow = rootKids(strfind(get(rootKids, 'name'), 'Spike-triggered Average: ')); 
elseif numel(rootKids) > 1
    couplingWindow = rootKids(~cellfun('isempty', strfind(get(rootKids, 'name'), 'Spike-triggered Average: '))); 
else
    couplingWindow = [];
end
if isempty(couplingWindow)
    couplingWindow = setupSTA(zData.protocol, windowSize, windowDelay);
    if isempty(couplingWindow)
        return
    end
end

if length(couplingWindow) > 1
    % we have multiple coupling windows going so add this data to the right one only
    for i = 1:length(couplingWindow)
        windowName = get(couplingWindow(i), 'name');
        if strcmp(windowName(26:end), zData.protocol.fileName(1:find(zData.protocol.fileName == 'S', 1, 'last') - 2))
            couplingWindow = couplingWindow(i);
            break
        end
    end
    if length(couplingWindow) > 1 % we didn't find a match so make a new window
        tempHandle = setupSTA(zData.protocol, windowSize, windowDelay);
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

% check to make sure we haven't turned off an amp since our last run
if numel(zData.protocol.ampType) < length(channels)
   % an amp was turned off so remake the figure
    newWindow = setupSTA(zData.protocol, windowSize, windowDelay);
    tempData = get(newWindow, 'userData');
    tempChannels = tempData{1};
    tempStims = tempData{3};
    
    % copy the pertinent information from the old figure to the new one
    axesHandles = get(couplingWindow, 'children');
    tempAxesHandles = get(newWindow, 'children');
    newStatus = zeros(size(channels));
    for i = 1:length(channels)
        newStatus(i) = length(find(tempStims == stims(i * 2)));
    end
    newStatus = find(newStatus);
    
    for i = 1:length(tempChannels)
        for j = 1:length(tempChannels)
            handles = copyobj(axesHandles(((length(axesHandles) - ((newStatus(i) - 1) * length(channels) + newStatus(j) - 1) * 6 - 5)):(length(axesHandles) - ((newStatus(i) - 1) * length(channels) + newStatus(j) - 1) * 6)), newWindow);
            pos = get(tempAxesHandles(((length(tempAxesHandles) - ((i - 1) * length(tempChannels) + j - 1) * 6) - 5):(length(tempAxesHandles) - ((i - 1) * length(tempChannels) + j - 1) * 6)), 'position');
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
    numProcessed = numProcessed(newStatus);
    PSPdata = PSPdata(newStatus, [sort([2 * newStatus - 1 2 * newStatus]) end], :);
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

if ~(numel(tempStims) == numel(stims) && all(tempStims == stims)) 
    % this oughtn't to be here
    return
end

figKids = get(couplingWindow, 'children');
figKids = figKids(cellfun('isempty', strfind(get(figKids, 'type'), 'uimenu')));
tempTraces = get(figKids, 'children');
j = 1;
for i = length(tempTraces):-1:1
    if ~isempty(tempTraces{i})
        traces(j) = tempTraces{i}(end);
        j = j + 1;
    end
end

% find spikes
for stimIndex = 1:length(stims)
    tempSpike = detectSpikes(zData.traceData(stims(stimIndex):stims(stimIndex) + stimLength + windowSize, channels(fix((stimIndex + 1) / 2))));
    if length(tempSpike) < 1 || mean(zData.traceData(stims(stimIndex):stims(stimIndex) + stimLength + windowSize, channels(fix((stimIndex + 1) / 2)))) > -10
        % no spikes were detected
        spikes(stimIndex, 1) = nan;
    else
        spikes(stimIndex, 1) = tempSpike(1);
    end
end

% look for coupling
for cellIndex = 1:size(channels, 2)
    % sort PSPs into windows
    for stimIndex = 1:size(stims, 1)
        if ~((stimIndex / cellIndex == 2 || (stimIndex + 1) / cellIndex == 2) || isnan(spikes(stimIndex, 1))) % don't look for stimuli onto self
            % if a spike is present in the window then skip
            if isempty(detectSpikes(zData.traceData(stims(stimIndex) + spikes(stimIndex) - windowSize:stims(stimIndex) + spikes(stimIndex) + windowDelay + windowSize, channels(cellIndex))) + samplingRate)
            
                % increment the number of episodes
                numProcessed(stimIndex) = numProcessed(stimIndex) + 1;

                % set pre/post-spike data
                PSPdata(cellIndex, stimIndex, :) = (numProcessed(stimIndex) - 1) / numProcessed(stimIndex) * squeeze(PSPdata(cellIndex, stimIndex, :)) + zData.traceData(stims(stimIndex) + spikes(stimIndex) - windowSize:stims(stimIndex) + spikes(stimIndex) + windowDelay + windowSize, channels(cellIndex)) / numProcessed(stimIndex);

                % test for a significant difference
                % [h,significance,ci] = ttest2(PSPdata(cellIndex, stimIndex, 1:windowSize), PSPdata(cellIndex, stimIndex, windowSize + windowDelay + 1:end), 0.01);
                [h,significance] = ztest(mean(PSPdata(cellIndex, stimIndex, windowSize + windowDelay + 1:end)), mean(PSPdata(cellIndex, stimIndex, 1:windowSize)), std(PSPdata(cellIndex, stimIndex, 1:windowSize)), 0.01, 'both');
                delta = mean(PSPdata(cellIndex, stimIndex, windowSize + windowDelay + 1:end)) - mean(PSPdata(cellIndex, stimIndex, 1:windowSize));

                % redraw the line
                if h == 1
                    if delta > 0
                        set(traces((cellIndex - 1) * length(stims) + stimIndex), 'ydata', PSPdata(cellIndex, stimIndex, :), 'color', [1 0 0]);
                    else
                        set(traces((cellIndex - 1) * length(stims) + stimIndex), 'ydata', PSPdata(cellIndex, stimIndex, :), 'color', [0 0 1]);
                    end
                else
                    set(traces((cellIndex - 1) * length(stims) + stimIndex), 'ydata', PSPdata(cellIndex, stimIndex, :), 'color', [0 0 0]);
                end

                kids = get(couplingWindow, 'children');
                set(kids(length(kids) - (stimIndex + (cellIndex - 1) * size(stims, 1)) * 3 + 2), 'String', ['Post-Pre = ' sprintf('%-1.2f', delta)]);
                set(kids(length(kids) - (stimIndex + (cellIndex - 1) * size(stims, 1)) * 3 + 1), 'String', ['p = ' sprintf('%-.4f', significance)]);
            end
        end
    end
end

set(couplingWindow, 'userData', {channels, numProcessed, stims, PSPdata, stimLength, windowSize, windowDelay});