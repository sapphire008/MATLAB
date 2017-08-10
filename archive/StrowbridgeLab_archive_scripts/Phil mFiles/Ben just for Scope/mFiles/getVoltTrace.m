function voltageTrace=getVoltTrace(zData,varargin)
% [ApTimesinMs] = getVoltTrace(zData, TraceNumberFrom1toxx as optional);
% this routine gets the first voltage trace in the episode with no optional
% arguments
if nargin>1
    traceNum=varargin{1};
else
    traceNum=1; % to get first voltage trace by default
end
temp = zData.traceData(:, whichChannel(zData.protocol, traceNum, 'V'));
voltageTrace=temp{1}; 