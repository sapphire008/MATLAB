function figureHandle = intervalHist(varargin)
% show an interval histogram

if nargin == 0
    figureHandle = 'Interval Histogram';
else
    events = getappdata(gca, 'events');

    figureHandle = figure('numbertitle', 'off', 'name', 'Interval Histogram');
    ISI = diff(events(varargin{5}).data);
    hist(ISI, round(length(ISI) / 5));    
end