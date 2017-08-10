function outText = displayProtocol(fileName)
if ~nargin
    outText = 'Display Protocol';
    return
end

    compType = computer;
    if ~strcmp(compType(end - 1:end), '64') && strcmp(fileName{1}(end - 3:end), '.dat')
        benProtocolViewer(fileName{1});
    else
        loadProtocol(fileName{1});
    end