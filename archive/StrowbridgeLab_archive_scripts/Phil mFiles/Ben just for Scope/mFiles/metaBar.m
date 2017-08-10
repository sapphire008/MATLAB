function figHandle = metaBar(titles, xData, yData)
% generate mega plot
% figHandle = metaBar(titles, xData, yData)

% find dimensions
xDim = fix(sqrt(size(titles, 1)));
if fix(sqrt(size(titles, 1))) ~= sqrt(size(titles, 1))
    xDim = xDim + 1;
end
if xDim * xDim - xDim >= size(titles, 1)
    yDim = xDim - 1;
else
    yDim = xDim;
end
figHandle = figure('numbertitle', 'off', 'Name', '');
for plotX = 1:xDim
    for plotY = 1:yDim
        if (plotX - 1) * yDim + plotY <= size(titles, 1)
            subplot(xDim, yDim, (plotX - 1) * yDim + plotY);
            if ~any(size(xData) == 1) % check to make sure that they aren't all using the same x data
                bar(xData(:,(plotX - 1) * yDim + plotY), yData(:,(plotX - 1) * yDim + plotY));
            else
                bar(xData, yData(:,(plotX - 1) * yDim + plotY));
            end
            set(gca, 'userdata', titles{(plotX - 1) * yDim + plotY});
            axis tight;
        end
    end
end

% set roll-over function to enlarge
kids = get(figHandle, 'children');
set(figHandle, 'WindowButtonMotionFcn', @growSubplot, 'numbertitle', 'off', 'name', '', 'userData', get(kids(1), 'position'), 'units', 'normalized');

function growSubplot(varargin)
% growSubplot
% this function blows up the plot over which the mouse is hovering when
% many subplots are present

figureZoom = 2;
currentLoc = get(gcf, 'CurrentPoint');

kids = get(gcf, 'children');
whereKids = get(kids, 'position');
for index = 1:4
    for index2 = 1:length(whereKids)
        newKids(index, index2) = whereKids{index2}(index);
    end
end
whichAxis = find(newKids(1,:) < currentLoc(1) & (newKids(1,:) + newKids(3,:)) > currentLoc(1) & newKids(2,:) < currentLoc(2) & (newKids(2,:) + newKids(4,:)) > currentLoc(2));

if whichAxis > 1
    set(kids(1), 'position', get(gcf, 'userData'));
    set(gcf, 'userData', get(kids(whichAxis), 'position'));
    tempPosition = get(kids(whichAxis), 'position') * [1 0 0 0; 0 1 0 0; -0.5 * (figureZoom - 1) 0 figureZoom 0; 0 -0.5 * (figureZoom - 1) 0 figureZoom];
    % check to make sure that we didn't leave the figure
    if tempPosition(1) < .05; tempPosition(1) = .05; end
    if tempPosition(2) < .05; tempPosition(2) = .05; end
    if tempPosition(1) + tempPosition(3) > 1; tempPosition(1) = 1 - tempPosition(3); end
    if tempPosition(2) + tempPosition(4) > 1; tempPosition(2) = 1 - tempPosition(4); end
    
    set(kids(whichAxis), 'position',  tempPosition);
    set(gcf, 'children', [kids(whichAxis); kids(kids ~= whichAxis)]);
    set(gcf, 'name', get(kids(whichAxis), 'userdata'));
else
    if isempty(whichAxis)
        set(kids(1), 'position', get(gcf, 'userData'));
    end
end