function showScaleBar

    info = getappdata(getappdata(0, 'imageBrowser'), 'info');
	currentFigure = gcf;
    % find the range and put 5 markers in it that occur and
    % nice round values
    imagePos = get(getappdata(0, 'imageDisplay'), 'position');
	switch get(findobj('tag', 'cboImageSet'), 'value')
		case 4
			if isappdata(0, 'scaleBar')
				figHandle = figure(getappdata(0, 'scaleBar'));
			else
				figHandle = figure('closeRequestFcn', 'rmappdata(0, ''scaleBar''); delete(gcf)', 'menu', 'none', 'colormap', hsv(256), 'numbertitle', 'off', 'name', '', 'units', 'pixel', 'position', [imagePos(1) + 10 + imagePos(3) imagePos(2) 50 imagePos(4)]);
			end
			axes('parent', figHandle, 'units', 'norm', 'position', [0 0 .5 1]);
			image((1:256)', 'cdatamapping', 'scaled');
			howManyDigits = floor(log10(range(info.sliceDepths) / 5));
			if howManyDigits < 0
				howManyDigits = floor(log10(range(info.sliceDepths)) / 2.5);
			end
			minValue = round(min(info.sliceDepths)/10^howManyDigits) * 10^howManyDigits;
			stepSize = round((range(info.sliceDepths)/(5*10^howManyDigits)))*10^howManyDigits;
			if minValue < min(info.sliceDepths)
				set(gca, 'ytick', 256 .* ((minValue + stepSize:stepSize:minValue + 5 * stepSize) - min(info.sliceDepths)) ./ range(info.sliceDepths) + 1);
				labels = num2str((minValue + stepSize:stepSize:minValue + 5 * stepSize)');
			else
				set(gca, 'ytick', 256 .* ((minValue:stepSize:minValue + 4 * stepSize) - min(info.sliceDepths)) ./ range(info.sliceDepths) + 1);
				labels = num2str((minValue:stepSize:minValue + 4 * stepSize)');		
			end
			labels = [labels repmat([' ' char(181) 'm'], size(labels, 1), 1)];
			set(gca, 'yticklabel', labels);
			set(gca, 'yAxisLocation', 'right', 'ydir', 'normal');
		case 5
			if isappdata(0, 'scaleBar')
				figHandle = figure(getappdata(0, 'scaleBar'));
			else
				figHandle = figure('closeRequestFcn', 'rmappdata(0, ''scaleBar''); delete(gcf)', 'menu', 'none', 'colormap', hsv(256), 'numbertitle', 'off', 'name', '', 'units', 'pixel', 'position', [imagePos(1) + 10 + imagePos(3) imagePos(2) 50 imagePos(4)]);
			end
			axes('parent', figHandle, 'units', 'norm', 'position', [0 0 .5 1]);
			image((1:256)', 'cdatamapping', 'scaled');
			msPerFrame = str2double(get(findobj('tag', 'txtFrameDuration'), 'string'));
			howManyDigits = floor(log10((info.NumImages - 1) * msPerFrame / 5));
			if howManyDigits < 0
				howManyDigits = floor(log10((info.NumImages - 1) * msPerFrame) / 2.5);
			end
			minValue = round(0.5 * msPerFrame /10^howManyDigits) * 10^howManyDigits;
			stepSize = round(((info.NumImages - .5) * msPerFrame /(5*10^howManyDigits)))*10^howManyDigits;
			if minValue < 0.5 * msPerFrame
				set(gca, 'ytick', 256 .* ((minValue + stepSize:stepSize:minValue + 5 * stepSize) - 0.5 * msPerFrame) ./ ((info.NumImages - 1) * msPerFrame) + 1);
				labels = num2str((minValue + stepSize:stepSize:minValue + 5 * stepSize)');
			else
				set(gca, 'ytick', 256 .* ((minValue:stepSize:minValue + 4 * stepSize) - 0.5 * msPerFrame) ./ ((info.NumImages - 1) * msPerFrame) + 1);
				labels = num2str((minValue:stepSize:minValue + 4 * stepSize)');		
			end
			labels = [labels repmat(' ms', size(labels, 1), 1)];
			set(gca, 'yticklabel', labels);
			set(gca, 'yAxisLocation', 'right', 'ydir', 'normal');			
	end
	setappdata(0, 'scaleBar', figHandle);
	figure(currentFigure);