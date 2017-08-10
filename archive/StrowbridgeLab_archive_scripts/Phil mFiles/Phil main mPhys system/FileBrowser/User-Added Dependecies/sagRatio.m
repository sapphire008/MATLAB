function outData = sagRatio(protocol)
firstWindow = [3000 4000] .* 1000;
secondWindow = [5000 5500] .* 1000;
zData = readTrace(protocol.fileName);
outData = (calcMean(zData.traceData(secondWindow(1) / protocol.timePerPoint:secondWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'V'))) - calcMean(zData.traceData(firstWindow(1) / protocol.timePerPoint:firstWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'V')))) / (min(zData.traceData(firstWindow(2) / protocol.timePerPoint:secondWindow(1) / protocol.timePerPoint, whichChannel(protocol, 1, 'V'))) - calcMean(zData.traceData(firstWindow(1) / protocol.timePerPoint:firstWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'V'))));