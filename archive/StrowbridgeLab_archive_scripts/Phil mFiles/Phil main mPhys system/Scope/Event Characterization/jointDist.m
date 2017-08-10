function figureHandle = jointDist(varargin)
% show a joint distribution

if nargin == 0
    figureHandle = 'Joint Distribution';
else
    events = getappdata(gca, 'events');
    
    figureHandle = figure('numbertitle', 'off', 'name', 'Joint Distribution');
    ISI = diff(events(varargin{5}).data);
    plot(ISI(1:end - 1), ISI(2:end), 'linestyle', 'none', 'marker', '.', 'markersize', 12);    
    title('Joint Distribution');
    xlabel('Time (ms)');
    ylabel('Time (ms)');
end