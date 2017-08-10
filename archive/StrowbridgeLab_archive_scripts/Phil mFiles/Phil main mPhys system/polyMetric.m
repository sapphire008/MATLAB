function outRatio = polyMetric(data, protocol)

stimTimes = findStims(protocol);
stimTimes = stimTimes{find(cellfun(@(x) ~isempty(x), stimTimes), 1)};
startTime = stimTimes(1,1);
stopTime = stimTimes(end,1);

% get the channel type
channelType = protocol.channelNames{get(findobj(get(get(gca, 'userData'), 'parent'), 'tag', 'channel'), 'value')};

if strcmp(channelType(1:3), 'Amp')
    if channelType(end) == 'I'
        if mean(data(1:round(end/5))) > median(data(1:round(end/5)))
            % IPSCs
            preRate = size(detectPSPs(data(1:startTime), 0, 'minAmp', 5, 'maxAmp', 2000, 'minTau', 10, 'maxTau', 1000, 'minYOffset', -Inf, 'maxYOffset', Inf, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 11, 'derFilterLength', 7, 'debugging', 0, 'dataStart', 1, 'forceDisplay',  1, 'outputAxis', gca, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ (startTime * protocol.timePerPoint / 1000000);
            postRate = size(detectPSPs(data(stopTime + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint)), 0, 'minAmp', 5, 'maxAmp', 2000, 'minTau', 10, 'maxTau', 1000, 'minYOffset', -Inf, 'maxYOffset', Inf, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 11, 'derFilterLength', 7, 'debugging', 0, 'dataStart', stopTime + 500000 / protocol.timePerPoint, 'forceDisplay',  1, 'outputAxis', gca, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ 4;      
        else
            % EPSCs
            preRate = size(detectPSPs(data(1:startTime), 1, 'minAmp', -2000, 'maxAmp', -5, 'minTau', 10, 'maxTau', 1000, 'minYOffset', -Inf, 'maxYOffset', Inf, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 11, 'derFilterLength', 7, 'debugging', 0, 'dataStart', 1, 'forceDisplay',  1, 'outputAxis', gca, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ (startTime * protocol.timePerPoint / 1000000);
            postRate = size(detectPSPs(data(stopTime + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint)), 1, 'minAmp', -2000, 'maxAmp', -10, 'minTau', 10, 'maxTau', 1000, 'minYOffset', -Inf, 'maxYOffset', Inf, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 11, 'derFilterLength', 7, 'debugging', 0, 'dataStart', stopTime + 500000 / protocol.timePerPoint, 'forceDisplay',  1, 'outputAxis', gca, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ 4;
        end
    else
        % EPSPs
        % skip the input resistance check in the first 0.5s
        % preRate = size(detectPSPs(data(500000/protocol.timePerPoint:startTime), 0, 'minAmp', 0.5, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'outputAxis', gca, 'dataStart', 500000 / protocol.timePerPoint, 'forceDisplay',  1, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ (startTime * protocol.timePerPoint / 1000000 - 0.5);
        preRate = size(detectPSPs(data(1:startTime), 0, 'minAmp', 0.5, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'outputAxis', gca, 'dataStart', 1, 'forceDisplay',  1, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ (startTime * protocol.timePerPoint / 1000000);
        postRate = size(detectPSPs(data(stopTime + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint)), 0, 'minAmp', 0.5, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'outputAxis', gca, 'dataStart', stopTime + 500000 / protocol.timePerPoint, 'forceDisplay',  1, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1) ./ 4;
    end
else
    % MUA
    units = MTEO(data, round(1000/protocol.timePerPoint), -1.5)';   
    preRate = sum(units < startTime) ./ (startTime * protocol.timePerPoint / 1000000);
    postRate = sum(units > stopTime + 500000 / protocol.timePerPoint & units <= stopTime + 4500000 / protocol.timePerPoint) ./ 4;
end


% outRatio = postRate - preRate;
% clipboard('copy', [sprintf('%1.2f', preRate) char(9) sprintf('%1.2f', postRate)]);
outRatio = postRate ./ preRate;
clipboard('copy', sprintf('%1.4f', outRatio));