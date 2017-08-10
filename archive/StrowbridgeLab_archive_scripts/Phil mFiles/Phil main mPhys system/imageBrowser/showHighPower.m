function showHighPower
% show the current images location on the reference image

if isappdata(0, 'referenceImage')
    if ispref('objectives', 'micronPerMit')
        refImage = getappdata(0, 'referenceImage');
        refKid = findobj('tag', 'referenceImageAxis');

        refInfo = getappdata(refImage, 'info');
        currentInfo = getappdata(getappdata(0, 'imageBrowser'), 'info');

        % draw a box on the reference image representing the currentImage boundaries
        newCoords = transferPoints([1 1; currentInfo.Width 1; currentInfo.Width currentInfo.Height; 1 currentInfo.Height; 1 1], currentInfo, refInfo);
        line(newCoords(:,1), newCoords(:,2),...
            'parent', refKid, 'color', [0 0 0], 'linewidth', 3);
    else
        msgbox('Must first enter calibration data for objectives on this scope');
    end
else
    msgbox('No reference image currently set');
end