function resizeImage
%resize the current image form

    % get the variables that we'll work with
    if isappdata(0, 'imageBrowser') && isstruct(getappdata(getappdata(0, 'imageBrowser'), 'info'))
        info = getappdata(getappdata(0, 'imageBrowser'), 'info');
        frmPosition = get(getappdata(0, 'imageDisplay'), 'Position');
        savedPoint = frmPosition(4);
        
		%determine which dimension is too big and shrink it
        if frmPosition(3)/info.Width > frmPosition(4)/info.Height
			frmPosition(3) = frmPosition(4)/info.Height*info.Width;
		else
			frmPosition(4) = frmPosition(3)/info.Width*info.Height;
        end
        set(findobj('tag', 'imageAxis'), 'Position', [0 0 frmPosition(3) frmPosition(4)]);%, 'xlim', 0.5 + [0 info.Width], 'ylim', 0.5 + [0 info.Height]);
        set(getappdata(0, 'imageDisplay'), 'Position', [frmPosition(1) frmPosition(2) + fix(savedPoint - frmPosition(4)) frmPosition(3) frmPosition(4)]);
        setCursor;
    end