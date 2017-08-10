function transferCellOutline
% show the current cell's location on the reference image

if isappdata(0, 'referenceImage')
    if ispref('objectives', 'micronPerMit')
        refImage = getappdata(0, 'referenceImage');
        refKid = findobj('tag', 'referenceImageAxis');

        refInfo = getappdata(refImage, 'info');
        currentInfo = getappdata(getappdata(0, 'imageBrowser'), 'info');

        % figure out the index of the objectives we are using
        newCoords = transferPoints(traceCell(get(findobj('tag', 'image'), 'cdata')), currentInfo, refInfo);
        line(newCoords(:,1), newCoords(:,2),...
            'parent', refKid, 'color', [0 0 0], 'linestyle', 'none', 'marker', '.', 'markerSize', .1);
    else
        msgbox('Must first enter calibration data for objectives on this scope');
    end
else
    msgbox('No reference image currently set');
end