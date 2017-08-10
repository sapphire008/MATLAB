function outPixels = traceCell(inImage)
% find cells
% reference:  Image Processing Toolbox: Example 2 -- Advanced Topics :: Getting Started: Example 2 -- Advanced Topics
    
    % median filter the image
    currentImage = medfilt2(normalizeMatrix(inImage), [5 5]);
    
    % saturate top of image
    currentImage = imadjust(currentImage, stretchlim(currentImage),[0, 1 - str2double(get(findobj('tag', 'txtCellThresh'), 'String'))]);
    
    % dilate image to fill in gaps
    currentImage = imdilate(currentImage, strel('disk', 2));
    
    %create a binary version of image
    binaryImage = im2bw(currentImage, median(currentImage(:)) + std(currentImage(:)));
    
    %find number of components in the image
    [labeled, numObjects] = bwlabel(binaryImage, 4); %4 is the pixel-connectivity
    if numObjects == 0
        error('No objects detected.')
    end
      
    %find parameters of each cell
    regionAreas = regionprops(labeled, 'Area');
    
    % determine which objects are the cell
    whichObjects = find([regionAreas.Area] > (str2double(get(findobj('tag', 'txtCellMin'), 'String')) / 2)^2 * pi);
    if numel(whichObjects) == 0
        error('No objects detected. Try reducing minimum cell size.')
    end    
    
    % use this as a mask
    labeled(~ismember(labeled, whichObjects)) = 0;
    
    % erode image to original proportions
    labeled = imerode(labeled, strel('disk', 2));
    
    % display as a solid
%     figure, imshow(labeled);
    
    % display on a reference image
    outPixels = regionprops(labeled, 'PixelList');
    outPixels = cat(1, outPixels.PixelList);
    
%     % display as an outline
%     perim = bwperim(labeled);
%     inImage(perim > 0) = 255;
%     figure, imshow(inImage);