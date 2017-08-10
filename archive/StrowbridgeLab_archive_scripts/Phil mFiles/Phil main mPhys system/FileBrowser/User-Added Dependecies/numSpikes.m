function spikeCount = numSpikes(fileName)
% find the number of action potentials on the first amp

zData = readTrace(fileName);
if zData.protocol.sweepWindow < 10000
    spikeCount = numel(detectSpikes(zData.traceData(:,whichChannel(zData.protocol, 1, 'V'))));
else
    spikeCount = 0;
end