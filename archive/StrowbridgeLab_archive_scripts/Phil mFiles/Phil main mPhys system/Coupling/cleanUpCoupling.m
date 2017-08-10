function cleanUpCoupling
    % rezero traces so that scaling stays pretty
    axesHandles = get(gcf, 'children');
    for axesIndex = 3:3:length(axesHandles)
        lineHandles = get(axesHandles(axesIndex), 'children');
        if numel(lineHandles) > 1
            delete(lineHandles(length(lineHandles)));
        end
    end