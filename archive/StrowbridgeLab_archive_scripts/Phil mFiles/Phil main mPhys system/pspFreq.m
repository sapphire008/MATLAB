function outData = pspFreq(protocol)
zData = readTrace(protocol.fileName);

tempData = detectPSPs(zData.traceData(:, whichChannel(protocol, 1, 'V')), 0, 'minAmp', 0.2, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 3, 'errThresh', 0.01, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', 0.2, 'alphaFit', 1, 'decayFit', 0, 'riseFit', 0);
disp([protocol.fileName char(9) sprintf('%0.0f', sum(tempData(:,3) < 50000)/10) char(9) sprintf('%0.0f', sum(tempData(:,3) >= 55000 & tempData(:,3) < 65000)/2) char(9) sprintf('%0.0f', sum(tempData(:,3) >= 65000 & tempData(:,3) < 75000)/2) char(9) sprintf('%0.0f', sum(tempData(:,3) >= 55000 & tempData(:,3) < 75000) /4)]);
