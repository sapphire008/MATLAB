function [outNumber pValue] = burstingProbability(inData, timePerPoint, threshTime)
% pValue = burstingProbability(traceData, threshTime);
% pValue = burstingProbability(eventTimes, threshTime);
% defaults:
%   threshTime = mean(interevent_interval);
%
% use the joint distribution (left-handed interevent interval vs right-
% handed interevent interval) to determine whether the events are bursty,
% as defined by more events with one of their nearest neighbors closer by
% in time than an evenly-spaced event distribution would assume

if nargin < 2
    timePerPoint = 0.2; % ms
end

if length(inData) < 500
    spikes = inData; % ms
else
    spikes = detectSpikes(inData) * timePerPoint; % ms
end
ISI = diff(spikes);

if nargin < 3
    threshTime = mean(ISI); % ms
end

outNumber = sum(ISI(1:end - 1) > threshTime & ISI(2:end) > threshTime);
outNumber = (numel(ISI) - outNumber) / numel(ISI);

if license('test','Statistics_Toolbox')
    pValue = 1 - sum(binopdf(0:(outNumber*length(ISI)),length(ISI),.25));
else
    pValue = nan;
end

if nargout == 0
    figure('numbertitle', 'off', 'name', 'Joint Distribution');
    plot(ISI(1:end - 1), ISI(2:end), 'linestyle', 'none', 'marker', '.', 'markersize', 12);    
    line([threshTime max([get(gca, 'xlim') get(gca, 'ylim')])], [threshTime threshTime], 'color', [0 0 0], 'linestyle', ':');
    line([threshTime threshTime], [threshTime max([get(gca, 'xlim') get(gca, 'ylim')])], 'color', [0 0 0], 'linestyle', ':');
    if outNumber/length(ISI) < .25
        title([num2str(outNumber * length(ISI)) ' / ' num2str(length(ISI)) ', p = ' sprintf('%5.3f', pValue)]);
    else
        title([num2str(outNumber * length(ISI)) ' / ' num2str(length(ISI)) ', p = ' sprintf('%5.3f', pValue)], 'color', [1 1 1]);
    end
    xlabel('ms')
    ylabel('ms')
end