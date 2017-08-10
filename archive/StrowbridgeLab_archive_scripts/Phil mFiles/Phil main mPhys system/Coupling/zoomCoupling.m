function zoomCoupling(varargin)
% this function blows up the plot over which the mouse is hovering when
% many subplots are present
figureZoom = 2;
currentLoc = get(varargin{1}, 'CurrentPoint');
axesHandles = get(varargin{1}, 'children');
userData = get(varargin{1}, 'userData');
locInfo = getappdata(varargin{1}, 'zoomLocation');
shouldZoom = findobj(axesHandles(end), 'Label', 'Active Zoom');

if strcmp(get(shouldZoom, 'checked'), 'on')
    if currentLoc(1) > .02 && currentLoc(2) > .03
        whichAxis = length(axesHandles) + 1 - 3 * (fix((1 - currentLoc(2) * .97) * length(userData{1})) * length(userData{3}) + fix((currentLoc(1) - .02) / .98 * length(userData{3}) + 1));
        if whichAxis ~= locInfo(1)
            % if there was a previous zoom
            if locInfo(1) > 0
                % unzoom it
                unZoom;
            end

            % zoom the current
            setappdata(varargin{1}, 'zoomLocation', [whichAxis get(axesHandles(whichAxis), 'position')]);
            tempPosition = get(axesHandles(whichAxis), 'position') * [1 0 0 0; 0 1 0 0; -0.5 * (figureZoom - 1) 0 figureZoom 0; 0 -0.5 * (figureZoom - 1) 0 figureZoom];
            % check to make sure that we didn't leave the figure
            if tempPosition(1) < 0; tempPosition(1) = 0; end
            if tempPosition(2) < 0; tempPosition(2) = 0; end
            if tempPosition(1) + tempPosition(3) > 1; tempPosition(1) = 1 - tempPosition(3); end
            if tempPosition(2) + tempPosition(4) > 1; tempPosition(2) = 1 - tempPosition(4); end

            set(axesHandles(whichAxis - 1), 'position', [tempPosition(1)  tempPosition(2) .056 * figureZoom .01 * figureZoom], 'fontSize', 8 * figureZoom * .8);
            set(axesHandles(whichAxis - 2), 'position', [tempPosition(1) + 0.5 * tempPosition(3)  tempPosition(2) .056 * figureZoom .01 * figureZoom], 'fontSize', 8 * figureZoom * .8);    
            set(axesHandles(whichAxis), 'position',  tempPosition, 'xTickLabelMode', 'auto', 'yTickLabelMode', 'auto');
            set(varargin{1}, 'children', axesHandles([whichAxis - 2:whichAxis 1:whichAxis - 3 whichAxis + 1:end]));        
        end
    else
        if locInfo(1) > 0
            unZoom;
            set(varargin{1}, 'children', axesHandles);        
            setappdata(varargin{1}, 'zoomLocation', 0);    
        end
    end
end

    function unZoom
        set(axesHandles(2), 'position', [locInfo(2) locInfo(3) .056 .01], 'fontSize', 8);
        set(axesHandles(1), 'position', [locInfo(2) + 0.5 * locInfo(4) locInfo(3) .056 .01], 'fontSize', 8);
        set(axesHandles(3), 'position', locInfo(2:5));
        if locInfo(1) > 3 * length(userData{3})
            set(axesHandles(3), 'xTickLabel', '');
        end
        if ~mod(locInfo(1) / 3 - 1, length(userData{3}))
            set(axesHandles(3), 'yTickLabel', '');
        end
        axesHandles = axesHandles([4:locInfo(1) 1:3 locInfo(1) + 1:end]);        
    end
end