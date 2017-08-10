function currentImage = processImage
% used to update the current image

    % get data
    browserHandles = get(getappdata(0, 'imageBrowser'), 'userData');
    info = getappdata(browserHandles.frmImageBrowser, 'info');
	ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
    
    % determine which frames we will be looking at
    switch get(browserHandles.cboAverageLocation, 'value')
        case {1 3} % right, left
            frameNumbers = get(browserHandles.cboFrame, 'value'):get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value') - 1;
        case 2 % center
            frameNumbers = get(browserHandles.cboAverageNumber, 'value') - 2 + get(browserHandles.cboFrame, 'value'):get(browserHandles.cboFrame, 'value') + get(browserHandles.cboAverageNumber, 'value');
    end
    
	% set aside space
    info.Width = evalin('base', 'size(zImage.stack, 1)');
    info.Height = evalin('base', 'size(zImage.stack, 2)');
	currentImage = zeros(info.Width, info.Height, length(frameNumbers), evalin('base', 'class(zImage.stack)'));

	% get all involved images
	frameIndex = 1;
	for x = frameNumbers
        currentImage(:,:,frameIndex) = evalin('base', ['zImage.stack(:,:,' sprintf('%0.0f', x) ')']);			
		frameIndex = frameIndex + 1;
	end
	
	% clear data hidden under clearing ROI
    if strcmp(get(browserHandles.mnuMogClearing, 'checked'), 'off')
        for i = 1:numel(ROI)
            if ROI(i).Type == 2
                [indices indices] = intersect(frameNumbers, ROI(i).Frames);
                for j = 1:size(ROI(i).points, 1)
                    currentImage(ROI(i).points(j, 1), ROI(i).points(j, 2), indices) = 0;
                end
            end
        end
    else
        maskData = zeros(size(currentImage, 1)* size(currentImage, 2), 1);
        [X(1,:) X(2,:)] = ind2sub([size(currentImage, 1) size(currentImage, 2)], 1:size(currentImage, 1) * size(currentImage, 2));        
        for k = 1:size(currentImage, 3)
            hasMask = 0;
            for i = 1:numel(ROI)
                if ROI(i).Type == 2 && ~isempty(intersect(frameNumbers, ROI(i).Frames))
                    hasMask = 1;
                    R = [cos(-ROI(i).Orientation) -sin(-ROI(i).Orientation); sin(-ROI(i).Orientation) cos(-ROI(i).Orientation)];        
                    maskData = maskData + mvnpdf(X',ROI(i).Centroid, R^-1 * [1000 * ROI(i).MajorAxisLength 0; 0 1000 * ROI(i).MinorAxisLength] * R);
                end
            end
            if hasMask
                currentImage(:,:, k) = reshape(reshape(currentImage(:,:, k), [], 1) .* (maskData./ (max(max(maskData)))), size(currentImage, 1), size(currentImage, 2)) ;            
                maskData = zeros(size(currentImage, 1)* size(currentImage, 2), 1);
            end
        end
    end
    
    switch get(browserHandles.cboImageSet, 'value')
		case 1 % None
			% render all involved images into one
				switch get(browserHandles.cboAverageType, 'value')
					case 1 % Mean
						currentImage = double(mean(currentImage, 3));
					case 2 % Median
						currentImage = double(median(currentImage, 3));
					case 3 % Maximum
						currentImage = double(max(currentImage, [], 3));
					case 4 % Minimum
						currentImage = double(min(currentImage, [], 3));
				end
		case 4 % Depth
            [maxImage imageColor] = max(currentImage, [], 3);
			[currentImage newmap] = rgb2ind(hsv2rgb(cat(3, 1 - (info.sliceDepths(imageColor) - min(info.sliceDepths)) / range(info.sliceDepths), ones(info.Width, info.Height), double(maxImage))), 4096);
			currentImage = double(currentImage);			
            set(getappdata(0, 'imageDisplay'), 'Colormap', newmap)
			showScaleBar;
		case 5 % Time
            [maxImage imageColor] = max(currentImage, [], 3);
			[currentImage newmap] = rgb2ind(hsv2rgb(cat(3, 1 - imageColor / info.NumImages, ones(info.Width, info.Height), double(imadjust(maxImage, stretchlim(maxImage), [0 .9])))), 4096);
			currentImage = double(currentImage);
            set(getappdata(0, 'imageDisplay'), 'Colormap', newmap)
			showScaleBar;
    end    
    
    % run any command in the text box
    imageCommand = get(browserHandles.txtCommand, 'string');
    if numel(imageCommand) > 0
        try
            if iscell(imageCommand)
                imageCommand = imageCommand{1};
            end
            eval(imageCommand);
        catch
%             msgbox('Error evaluating text command');
        end 
    end
    
    % median filter the image if requested
    if get(browserHandles.chkMedianFilter, 'Value') == 1
        currentImage = medfilt2(currentImage, [str2double(get(browserHandles.txtMedianFilter, 'String')), str2double(get(browserHandles.txtMedianFilter, 'String'))]);
    end
    
    % low pass filter if requested
    if get(browserHandles.chkLowPassFilter, 'Value') == 1
        %for spatial decomposition of (image,...) with cutoff (...,cutOff)

        % Get the rect info and call roipoly to create the mask
        lowPassCutoff = str2double(get(browserHandles.txtLowPassFilter, 'String'));
        mask = ones(size(currentImage));
        order = 15;
        [f1, f2] = freqspace(order, 'meshgrid');
        Hd = zeros(order);
        Hd(f1.^2 + f2.^2 < lowPassCutoff^2) = 1;
        h = fwind1(Hd, chebwin(15,20)); %boxcar(15)); %hanning(15));
        currentImage = roifilt2(h, currentImage, mask);
    end

    % subtract background if requested
    if get(browserHandles.chkSubtractBackground, 'Value') == 1
        %estimate background
        backGround = imopen(currentImage, strel('disk', str2double(get(browserHandles.txtSubtractBackground, 'String'))));

        %subtract out background
        currentImage = imsubtract(currentImage, backGround);
        set(findobj('tag', 'background'),...
            'XData', 1,...
            'YData', 1,...
            'CData', backGround'); 
    end

    % weiner filter if requested
	if get(browserHandles.chkWiener2DFilter, 'Value') == 1
        currentImage = wiener2(currentImage, [str2double(get(browserHandles.txtWiener2DFilter, 'String')), str2double(get(browserHandles.txtWiener2DFilter, 'String'))]);
	end
	
	if get(browserHandles.chkHistogramEqualization, 'value') == 1
        if max(max(currentImage)) > 1
            currentImage = histeq((currentImage - min(min(currentImage))) ./ (max(max(currentImage)) - min(min(currentImage))));
        else
            currentImage = histeq(currentImage);
        end
	end

    % subtract baseline image if present
    if strcmp(get(browserHandles.cmdSetAsBaseline, 'String'), 'Remove Baseline')
        currentImage = currentImage - get(findobj('tag', 'baseline'), 'cdata')';
    end

    setappdata(browserHandles.frmImageBrowser, 'info', info);
    resizeImage;    