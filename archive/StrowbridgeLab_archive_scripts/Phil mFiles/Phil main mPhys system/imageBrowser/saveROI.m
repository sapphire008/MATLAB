function saveROI
%this file saves the current regions of interest as well as the fiducials
%for the image and a copy of the image for fiducial realignment to a file
%that the user specifies for later use

    fiducials = getappdata(getappdata(0, 'imageDisplay'), 'fiducials');
    ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');

    cd(get(findobj('tag', 'mnuSaveRoiToFile'), 'userdata'));

    [FileName PathName] = uiputfile('*.mat','Choose name and location for file');
    if numel(PathName) > 1
        set(findobj('tag', 'mnuSaveRoi'), 'userdata', PathName);

        if fiducials.set == 1
            save([PathName FileName], 'ROI', 'fiducials');
        else
            save([PathName FileName], 'ROI');    
        end
    end