function loadROI(roiData)
%loads a ROI set from a file
    
    if ~nargin
        cd(get(findobj('tag', 'mnuLoadRoi'), 'userdata'));
        [FileName PathName] = uigetfile('*.mat','Choose ROI set to use');
        if numel(PathName) > 1
            set(findobj('tag', 'mnuLoadRoi'), 'userdata', PathName);
            roiData = [PathName FileName];
        else
            return
        end        
    end

    % put the new data in its home
    if ischar(roiData)
        load(roiData);
        if ~exist('ROI', 'var')
            error('Not a valid ROI file');
        end
    else
        ROI = roiData;
    end

    for i = 1:numel(ROI)
        ROI(i).handle = line(nan, nan, 'parent', findobj('tag', 'imageAxis'));
    end                       
    setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
    set(findobj('tag', 'cboRoiNumber'), 'string', num2str((1:length(ROI))'), 'value', length(ROI));                                                                              

    if exist('fiducials', 'var')
        setappdata(getappdata(0, 'imageDisplay'), 'fiducials', fiducials);
    end

    %update the current image to show ROI
    drawROI;
    displayImage;