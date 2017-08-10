function  [spikeTimes title coincidentEvents] = crossCorr(data, corrVals, coincidenceInterval)
spikeTimes = [];
coincidentEvents = [];

switch nargin
    case 0
        error('Must specify data on which to operate')
    case 1
        minCor = -100; %msec
        maxCor = 100; %msec
        coincidenceInterval = [-1 1];     
    case 2
        minCor = corrVals(1);
        maxCor = corrVals(2);
        coincidenceInterval = [-1 1];     
    case 3
        minCor = corrVals(1);
        maxCor = corrVals(2);
end

title = 'Trace one with respect to trace two';
% determine if we're doing an autocorrelogram
if size(data, 2) == 1
    title = 'Autocorrelogram of trace';
    data = [data, data];
elseif size(data, 2) > 2 % run this one time for each combination
    %generate the cross-correlograms and the list of titles for plots
    plotCount = 1;
    for callIndex = 1:size(data, 2) - 1
        for counterIndex = callIndex + 1: size(data, 2)
            title(plotCount,:) = ['Trace ', num2str(callIndex), ' with respect to trace ', num2str(counterIndex)];
            [tempSpikes junk] = crossCorr([data(:, callIndex) data(:, counterIndex)], [minCor maxCor]);
            numSpikes(plotCount) = size(tempSpikes, 2);
            spikeTimes(1:numSpikes(plotCount), plotCount) = tempSpikes;
            plotCount = plotCount + 1;
        end
    end
    if nargout == 0
        % plot histogram
        for i = 1:size(data, 2)
            [count(:,i) whereBins] = hist(spikeTimes(1:numSpikes(i), i));
        end
        metaBar(title, whereBins, count);
        xlabel('Time (msec)');
        ylabel('Number of spikes');
        
        % plot raster
        figure('numbertitle', 'off', 'Name', title);
        colors = lines(size(data, 2));
        for i = 1:size(data, 2)
            line(spikeTimes(1:numSpikes(i), i), i * ones([1 numSpikes(i)]), 'linestyle', 'none', 'marker', '+', 'markersize', 6, 'color', colors(i, :));
        end
        legend(title)
        xlabel('Time (msec)')
    end
    return
end

% detect spikes
spikes = data(data(:,1)>0,1)';
otherSpikes = data(data(:,2)>0,2)';

% generate a crosscorelogram
eventNum = 1;
coincidentEvents = [];
for spikeIndex = 1:size(otherSpikes, 2)
    foundSpikes = find(spikes >= otherSpikes(spikeIndex) + minCor & spikes <= otherSpikes(spikeIndex) + maxCor);
    if ~isempty(foundSpikes)
        spikeTimes(eventNum:eventNum + length(foundSpikes) - 1) = otherSpikes(spikeIndex) - spikes(foundSpikes);
        if any(otherSpikes(spikeIndex) - spikes(foundSpikes) >= coincidenceInterval(1) & otherSpikes(spikeIndex) - spikes(foundSpikes) <= coincidenceInterval(2))
            coincidentEvents(end + 1) = otherSpikes(spikeIndex);
        end
        eventNum = eventNum + length(foundSpikes);
    end
end

if nargout == 0
    % plot histogram
    figure('numbertitle', 'off', 'Name', title);
    if strcmp(title, 'Autocorrelogram of trace')
       spikeTimes = spikeTimes(spikeTimes ~= 0); 
    end
    [count whereBins] = hist(spikeTimes, min([round(length(spikeTimes) / 5) 300]));
    bar(whereBins, count);
    smoothData = hist(spikeTimes, maxCor - minCor + 1);
    smoothData = movingAverage(smoothData, (maxCor - minCor + 1) / 10);
    line(minCor:maxCor, smoothData / sum(smoothData) * length(spikeTimes), 'color', [1 0 0]);
    xlabel('Time (msec)');
    ylabel('Number of spikes');
    
    % plot raster
    if numel(spikeTimes) < 100
        figure('numbertitle', 'off', 'Name', title);
        plot(spikeTimes, ones([1 length(spikeTimes)]), 'linestyle', 'none', 'marker', '+', 'markersize', 6, 'color', [0 0 0]);
        xlabel('Time (msec)');
    end
end