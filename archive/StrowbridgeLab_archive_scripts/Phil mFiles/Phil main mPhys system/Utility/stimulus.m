function stimData = stimulus(protocol, ampNum)
% generate the stimulus that a protocol would have used (assuming it is
% possible)

[digOut stimData] = generateStim(protocol, protocol);
whichStims = find(cell2mat(protocol.ampEnable) & (cell2mat(protocol.ampTpEnable) | cell2mat(protocol.ampMonitorRin) | (cell2mat(protocol.ampStimEnable) & (cell2mat(protocol.ampStepEnable) | cell2mat(protocol.ampPspEnable) | cell2mat(protocol.ampSineEnable) | cell2mat(protocol.ampRampEnable) | cell2mat(protocol.ampTrainEnable) | cell2mat(protocol.ampPulseEnable) | ~cellfun('isempty', protocol.ampMatlabStim))) | ~cellfun('isempty', protocol.ampMatlabCommand)));
if ~isempty(whichStims)
    stimData = stimData([1 1 1 1:end - 3], whichStims == ampNum);
else
    stimData = zeros(size(stimData, 1), 1);
end