function outRatio = polyMUA(protocol, data)
outRatio = -inf;

stimTimes = findStims(protocol);
try
    stimTimes = stimTimes{find(cellfun(@(x) ~isempty(x), stimTimes), 1)};
catch
    return
end

startTime = stimTimes(1,1);
stopTime = stimTimes(end,1);

if nargin < 2
    data = readTrace(protocol.fileName);
    
%     data = data.traceData(:, find(cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, 'Field')), 1, 'first'));
%     data(startTime:stopTime) = nan;
    data = data.traceData(:, whichChannel(protocol, 1, 'V'));
end

% events = MTEO(data, round(1000 / protocol.timePerPoint), -1.5)';
% preRate = sum(events < startTime) ./ (startTime * protocol.timePerPoint / 1000000);
% postRate = sum(events > stopTime + 500000 / protocol.timePerPoint & events <= stopTime + 4500000 / protocol.timePerPoint) ./ 4;
preRate = size(detectPSPs(data(1:startTime), 0, 'minAmp', 0.2, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', 1, 'alphaFit', 1, 'decayFit', 0, 'riseFit', 0), 1) ./ (startTime * protocol.timePerPoint / 1000000);
postRate = size(detectPSPs(data(stopTime + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint)), 0, 'minAmp', 0.2, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', stopTime + 500000 / protocol.timePerPoint, 'alphaFit', 1, 'decayFit', 0, 'riseFit', 0), 1) ./ 4;


outRatio = preRate;
setappdata(0, 'stim2', postRate);
% clipboard('copy', [sprintf('%1.2f', preRate) char(9) sprintf('%1.2f', postRate)]);
% outRatio = postRate ./ preRate;