
function figureHandle = plotHistogram(inValues, xAxisBins,  figureName)
 whichFigure = strcmp(get(get(0, 'children'), 'name'), figureName);
        if ~any(whichFigure)
            jitterWindow(figure('numbertitle', 'off', 'name', figureName));
             hist(inValues,xAxisBins);
        else
            figures = get(0, 'children');
            figure(figures(whichFigure));
            hist(inValues,xAxisBins);
        end
  figureHandle=gcf;
end


function jitterWindow(figHandle)    
    tempPos = get(figHandle, 'position') + rand(1,4) .* 50 - 25;
    set(0, 'units', get(figHandle, 'units'));
    screenLims = get(0, 'monitorPosition');
    screenLims = [min(screenLims(:,1:2), [], 1) max(screenLims(:,3:4), [], 1)];
    set(figHandle, 'position', [max([screenLims(1) min([screenLims(3) - tempPos(3) tempPos(1)])]) max([screenLims(2) min([screenLims(4) - tempPos(4) tempPos(2)])]) tempPos(3:4)]);
end