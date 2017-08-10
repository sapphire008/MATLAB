function outText = calcBurstProb(varargin)
if ~nargin
    outText = 'Bursting Probability';
else
    events = getappdata(gca, 'events');

    outValue = burstingProbability(events(varargin{5}).data');
    set(get(gca, 'userdata'), 'string', num2str(outValue));
end