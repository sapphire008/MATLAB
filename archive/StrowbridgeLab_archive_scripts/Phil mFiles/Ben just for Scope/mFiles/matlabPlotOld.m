function figureHandle = matlabPlotOld(x, y, figureName, parameterString)

switch nargin
    case 1
        msgbox('Error in matlabPlot.m. Must pass an X and Y vector as first two arguements.')
        return;
    case 2
        set(sfigure(1), 'numbertitle', 'off',  'name', 'Matlab Plot');
        plot(x,y);
        success = 1;
    case 3
        whichFigure = strcmp(get(get(0, 'children'), 'name'), figureName);
        if ~any(whichFigure)
            jitterWindow(figure('numbertitle', 'off', 'name', figureName));
            plot(x,y);
        else
            figures = get(0, 'children');
            figure(figures(whichFigure));
            plot(x,y);
        end
        success = 1;
    case 4
        whichFigure = strcmp(get(get(0, 'children'), 'name'), figureName);
        try
            if ~any(whichFigure)
                jitterWindow(figure('numbertitle', 'off', 'name', figureName));
                eval(['plot(x,y, ' parameterString ');'])
            else
                figures = get(0, 'children');
                figure(figures(whichFigure));
                eval(['plot(x,y, ' parameterString ');'])
            end
            success = 1;
        catch
            msgbox(['Error in matlabPlot.m. ' lasterr]);
        end
end
figureHandle=gcf;

function jitterWindow(figHandle)    
    tempPos = get(figHandle, 'position') + rand(1,4) .* 50 - 25;
    set(0, 'units', get(figHandle, 'units'));
    screenLims = get(0, 'monitorPosition');
    screenLims = [min(screenLims(:,1:2), [], 1) max(screenLims(:,3:4), [], 1)];
    set(figHandle, 'position', [max([screenLims(1) min([screenLims(3) - tempPos(3) tempPos(1)])]) max([screenLims(2) min([screenLims(4) - tempPos(4) tempPos(2)])]) tempPos(3:4)]);    