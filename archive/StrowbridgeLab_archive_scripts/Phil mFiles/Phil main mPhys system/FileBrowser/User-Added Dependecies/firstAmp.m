function amplitude = firstAmp(fileName)

zData = readTrace(fileName);
outData = detectPSPs(zData.traceData(:, whichChannel(zData.protocol,1,'V')), 0, 995, 50, 'minAmp', 0.2, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', .2, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', 0.2, 'alphaFit', 1, 'decayFit', 0, 'riseFit', 0);
amplitude = outData(1,1);
if amplitude == 0
    amplitude = nan;
end