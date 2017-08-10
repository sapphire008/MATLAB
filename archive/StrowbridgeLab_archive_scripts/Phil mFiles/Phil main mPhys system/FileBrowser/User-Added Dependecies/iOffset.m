function outData = iOffset(protocol, ampNum)
ampNum = 2;
outData = protocol.startingValues(cellfun(@(x) x(end) == 'I' &&...
    ~isempty(strfind(x, ['Amp ' char(64 + ampNum)])) &&...
    isempty(strfind(x, 'Stim')), protocol.channelNames));