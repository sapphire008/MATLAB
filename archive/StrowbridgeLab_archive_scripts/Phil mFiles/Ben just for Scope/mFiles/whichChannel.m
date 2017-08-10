function channelNum = whichChannel(protocol, ampNum, channelType)
% determine which channel a given amp is using
try
    if nargin < 3
    % try to figure out which channel is important
    channelType = protocol.ampTypeName{ampNum}(end - 1);
    if channelType == 'V'
        channelType = 'I';
    else
        channelType = 'V';
    end
    end
% try to figure out which channel is important
if channelType(1) == 'V'
    % curent clamp
    channelNum = find(cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, ['Amp ' char(64 + ampNum)])) & cellfun(@(x) x(end) == 'V', protocol.channelNames), 1);
elseif channelType(1) == 'I'
    % voltage clamp
    channelNum = find(cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, ['Amp ' char(64 + ampNum)])) & cellfun(@(x) x(end) == 'I', protocol.channelNames), 1);
elseif channelType(1) == 'S'
    % stimulus data
    channelNum = find(cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, ['Amp ' char(64 + ampNum)])) & cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, 'Stim')), 1);
else
    channelNum = nan;
    
end
catch
    channelNum = nan;
end


end