function outData = pulseResponse(protocol)
firstWindow = [8 10] .* 1000;
secondWindow = [80 100] .* 1000; 
zData = readTrace(protocol.fileName);
outData = (calcMean(zData.traceData(secondWindow(1) / protocol.timePerPoint:secondWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'V'))) - calcMean(zData.traceData(firstWindow(1) / protocol.timePerPoint:firstWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'V')))) / (calcMean(zData.traceData(secondWindow(1) / protocol.timePerPoint:secondWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'I'))) - calcMean(zData.traceData(firstWindow(1) / protocol.timePerPoint:firstWindow(2) / protocol.timePerPoint, whichChannel(protocol, 1, 'I')))) * 1000;