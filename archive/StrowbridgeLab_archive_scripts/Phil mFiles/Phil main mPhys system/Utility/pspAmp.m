function pspSize = pspAmp(fileName)

zData = readTrace(fileName);
% fast decaying upward deflection
% pspSize = (max(zData.traceData(5000:5250, whichChannel(zData.protocol, 1))) - calcMean(zData.traceData(4900:5020,whichChannel(zData.protocol, 1))));

% slowly decaying upward deflection
pspSize = (max(zData.traceData(5300:5600, whichChannel(zData.protocol, 1))) - calcMean(zData.traceData(4900:5020,whichChannel(zData.protocol, 1))));

% some kind of ratio
% pspSize = (max(zData.traceData(5300:5600, whichChannel(zData.protocol, 1))) - min(zData.traceData(5250:5320,whichChannel(zData.protocol, 1))))/(max(zData.traceData(5000:5250, whichChannel(zData.protocol, 1))) - calcMean(zData.traceData(4900:5020,whichChannel(zData.protocol, 1))));