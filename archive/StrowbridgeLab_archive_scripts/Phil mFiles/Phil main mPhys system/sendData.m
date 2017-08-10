function sendData(data, protocol)

% clipboard('copy', [protocol.fileName(find(protocol.fileName == filesep, 1, 'last') + 1:end-4) char(9) sprintf('%0.6f', meanVariance(blankAPsWithConstant(data(5000:45000)), 2500)) char(9) sprintf('%0.6f', meanVariance(blankAPsWithConstant(data(55000:75000)), 2500)) char(9) char(9) char(9) char(9) char(9) sprintf('%0.6f', size(detectPSPs(data(5000:45000), 0, 'minAmp', 0.3, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 3, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', 1000, 'forceDisplay',  0, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1)/8) char(9) char(9) sprintf('%0.6f', size(detectPSPs(data(55000:75000), 0, 'minAmp', 0.3, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 3, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', 1000, 'forceDisplay',  0, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1)/4)]);
% clipboard('copy', [protocol.fileName(find(protocol.fileName == filesep, 1, 'last') + 1:end-4) char(9) num2str((polyIntegral(data, protocol))) char(9)]);


stimTimes = findStims(protocol);
stimTimes = stimTimes{find(cellfun(@(x) ~isempty(x), stimTimes), 1)};
% copyText = '';
% for i = 1:size(stimTimes, 1)
%     copyText = [copyText num2str(max(data(stimTimes(i,1) + (0:50*1000/protocol.timePerPoint))) - min(data(stimTimes(i,1) + (1.6*1000/protocol.timePerPoint:10*1000/protocol.timePerPoint)))) char(9)];
% end
% clipboard('copy', copyText(1:end - 1));

zData = readTrace(protocol.fileName);
copyText = [protocol.fileName(find(protocol.fileName == filesep, 1, 'last') + 1:end-4) char(9)];
for i = 1:numel(zData.protocol.ampEnable)
    if zData.protocol.ampEnable{i}
%         copyText = [copyText sprintf('%0.6f', size(detectPSPs(zData.traceData(1:stimTimes(1,1), whichChannel(protocol, i, 'V')), 0, 'minAmp', 1, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 3, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', 0, 'forceDisplay',  0, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1)/(stimTimes(1,1) * protocol.timePerPoint / 1000000)) char(9) sprintf('%0.6f', size(detectPSPs(zData.traceData(stimTimes(2,1) + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint), whichChannel(protocol, i, 'V')), 0, 'minAmp', 1, 'maxAmp', 30, 'minTau', 25, 'maxTau', 500, 'minYOffset', -100, 'maxYOffset', -30, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 0.1, 'closestEPSPs', 3, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 5, 'derFilterLength', 5, 'debugging', 0, 'dataStart', stimTimes(2,1) + 500000 / protocol.timePerPoint, 'forceDisplay',  0, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0), 1)/4) char(9)];
        try
            copyText = [copyText sprintf('%0.6f', meanVariance(blankAPsWithConstant(zData.traceData(1:stimTimes(1,1), whichChannel(protocol, i, 'V'))), 2500)) char(9) sprintf('%0.6f', meanVariance(blankAPsWithConstant(zData.traceData(stimTimes(2,1) + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint), whichChannel(protocol, i, 'V'))), 2500)) char(9)];        
        catch
            copyText = [copyText char(9) char(9)];
        end
    else
        copyText = [copyText char(9) char(9)];
    end
end
clipboard('copy', copyText(1:end - 1));