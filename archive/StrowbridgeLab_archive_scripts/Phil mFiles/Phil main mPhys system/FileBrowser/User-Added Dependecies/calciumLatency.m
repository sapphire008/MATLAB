function latency = calciumLatency(protocol)

if ~nargin
    latency = 'Calcium latency';
    return
end

zData = readTrace(protocol.fileName);
if isfield(zData, 'photometry')
%     stimTimes = findStims(protocol, 1); % determine when the photometry started
%     calciumLag = fitBoltzmann(zData.photometry(800:1200,1)', zData.protocol.imageDuration / size(zData.photometry, 1), round(stimTimes{1}(:,1) + zData.roiDelay(1)) + 80, gca, '');
    calciumLag = analysisFun(zData.photometry(:,1));    
    spikeLag = detectWCAPs(zData.traceData(20000:30000, whichChannel(protocol, 1, 'V'))', 0.05) * 0.05 + 0.05;
%     latency = str2double(calciumLag(1:end - 2)) - spikeLag - 1000;       
    latency = calciumLag - spikeLag - 1000;           
else
    latency = nan;
end
