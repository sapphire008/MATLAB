function displayImage(varargin)

    browserHandles = get(getappdata(0, 'imageBrowser'), 'userData');
	imageHandles = get(getappdata(0, 'imageDisplay'), 'userData');
    info = getappdata(getappdata(0, 'imageBrowser'), 'info');
	ROI = getappdata(imageHandles.frmDisplayImage, 'ROI');
    
    % check to see if scopes are present and if they would like to know
    % where in the trace the image is
	if isappdata(0, 'scopes')
        if isstruct(info)
            tempName = info.Filename;
            tempName = tempName(1:find(tempName == '.', 1, 'last') - 1);
            scopes = getappdata(0, 'scopes');
            for scopeIndex = scopes'
                if ~isempty(strfind(get(scopeIndex, 'name'), tempName))
                    scopeHandles = get(scopeIndex, 'userData');
                    switch get(browserHandles.cboAverageLocation, 'value')
                        case {1 3} % right, left
                            xData = str2double(get(browserHandles.txtFrameDuration, 'string')) * [get(browserHandles.cboFrame, 'value') get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value') - 1];
                        case 2 % center
                            xData = str2double(get(browserHandles.txtFrameDuration, 'string')) * (get(browserHandles.cboAverageNumber, 'value') - 2 + get(browserHandles.cboFrame, 'value'):get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value'));
                    end                    
                    
                    for axisIndex = 1:scopeHandles.axesCount
                        lineHandles = get(scopeHandles.axes(axisIndex), 'children');
                        delete(lineHandles(strcmp(get(lineHandles, 'userData'), 'frameMarker')));
                        line(xData, [min(get(scopeHandles.axes(axisIndex), 'ylim')) min(get(scopeHandles.axes(axisIndex), 'ylim'))], 'linewidth', 3, 'linestyle', '-', 'color', [0 1 0], 'parent', scopeHandles.axes(axisIndex), 'userData', 'frameMarker');
                    end
                end
            end
        end
	end

	switch get(browserHandles.cboImageSet, 'Value')
        case 1
            set(imageHandles.image, 'visible', 'on');
            set(imageHandles.background, 'visible', 'off');
            set(imageHandles.baseline, 'visible', 'off');
			set(imageHandles.codeByDepth, 'visible', 'off');
			set(imageHandles.codeByTime, 'visible', 'off');
            set(imageHandles.fiducials, 'visible', 'off');
            
            % process the image
            currentImage = processImage;

            % Make the image object.
            set(imageHandles.image, 'CData', currentImage');
        case 2
            set(imageHandles.image, 'visible', 'off');
            set(imageHandles.background, 'visible', 'on');
            set(imageHandles.baseline, 'visible', 'off');
			set(imageHandles.codeByDepth, 'visible', 'off');
			set(imageHandles.codeByTime, 'visible', 'off');			
            set(imageHandles.fiducials, 'visible', 'off');
        case 3
            set(imageHandles.image, 'visible', 'off');
            set(imageHandles.background, 'visible', 'off');
            set(imageHandles.baseline, 'visible', 'on');
			set(imageHandles.codeByDepth, 'visible', 'off');
			set(imageHandles.codeByTime, 'visible', 'off');			
            set(imageHandles.fiducials, 'visible', 'off');
        case 4
            set(imageHandles.image, 'visible', 'off');
            set(imageHandles.background, 'visible', 'off');
            set(imageHandles.baseline, 'visible', 'off');
			set(imageHandles.codeByDepth, 'visible', 'on');
			set(imageHandles.codeByTime, 'visible', 'off');			
            set(imageHandles.fiducials, 'visible', 'off');
            % process the image
            currentImage = processImage;

            % Make the image object.
            set(imageHandles.codeByDepth, 'CData', currentImage');			
		case 5
            set(imageHandles.image, 'visible', 'off');
            set(imageHandles.background, 'visible', 'off');
            set(imageHandles.baseline, 'visible', 'off');
			set(imageHandles.codeByDepth, 'visible', 'off');
			set(imageHandles.codeByTime, 'visible', 'on');			
            set(imageHandles.fiducials, 'visible', 'off');		
            % process the image
            currentImage = processImage;

            % Make the image object.
            set(imageHandles.codeByTime, 'CData', currentImage');			
		case 6
            set(imageHandles.image, 'visible', 'off');
            set(imageHandles.background, 'visible', 'off');
            set(imageHandles.baseline, 'visible', 'off');
			set(imageHandles.codeByDepth, 'visible', 'off');
			set(imageHandles.codeByTime, 'visible', 'off');			
            set(imageHandles.fiducials, 'visible', 'on');			
	end
	
    % determine which frames we will be looking at
	switch get(browserHandles.cboAverageLocation, 'value')
        case {1 3} % right, left
            frameNumbers = get(browserHandles.cboFrame, 'value'):get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value') - 1;
        case 2 % center
            frameNumbers = get(browserHandles.cboAverageNumber, 'value') - 2 + get(browserHandles.cboFrame, 'value'):get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value');
	end
	
	for i = 1:numel(ROI)
		if isempty(intersect(ROI(i).Frames, frameNumbers))
			set(ROI(i).handle, 'visible', 'off');
		else
			set(ROI(i).handle, 'visible', 'on');
		end
	end
    
    resizeImage;
    if get(browserHandles.cboAverageNumber, 'value') == 1
		if info.NumImages > 1
			frameData = ['Frame ' num2str(get(browserHandles.cboFrame, 'value'))];
		else
			frameData = 'All data';			
		end
    else
        frameData = get(browserHandles.cboAverageType, 'string');
        frameData = [frameData{get(browserHandles.cboAverageType, 'value')} ' of frames ' num2str(get(browserHandles.cboFrame, 'value')) '-' num2str(get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value') - 1)];
    end
    set(imageHandles.frmDisplayImage, 'name', [frameData ' for ' info.Filename]);