function channelNum = whichChannel(protocol, ampNum, channelType)
% determine which channel a given amp is using

if nargin < 3
    % try to figure out which channel is important
    channelType = 'V';
end
% try to figure out which channel is important
if channelType(1) == 'V'
    % curent clamp
    channelNum = find(cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, ['Vo' char(48 + ampNum)])), 1);
elseif channelType(1) == 'I'
    % voltage clamp
    channelNum = find(cellfun(@(x) ~isempty(x), strfind(protocol.channelNames, ['Cu ' char(48 + ampNum)])), 1);
elseif channelType(1) == 'S'
    % stimulus data
    channelNum = [];
else
    channelNum = nan;
end