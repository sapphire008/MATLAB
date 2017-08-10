function rIn = stepResponse(protocol)

if protocol.ampStep1Amplitude{1} == -50
    zData = readTrace(protocol.fileName);
    rIn = (calcMean(zData.traceData(10000:15000, whichChannel(protocol, 1, 'V'))) - calcMean(zData.traceData(1:5000, whichChannel(protocol, 1, 'V')))) / -.05;
else
    rIn = 0;
end
