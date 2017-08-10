function locateCells
% find cells
% reference:  Image Processing Toolbox: Example 2 -- Advanced Topics :: Getting Started: Example 2 -- Advanced Topics

    currentImage = get(findobj('tag', 'image'), 'cdata');
    
    clim = get(findobj('tag', 'imageAxis'), 'clim');

    currentImage = (currentImage - clim(1)) / clim(2);
    
    cellSizeMin = str2double(get(findobj('tag', 'txtCellMin'), 'String'));
    cellSizeMax = str2double(get(findobj('tag', 'txtCellMax'), 'String'));    
    
    %saturate top 20% of image
    currentImage = imadjust(currentImage, stretchlim(currentImage),[0, .8]);
    
    %create a binary version of image
    threshLevel = graythresh(currentImage) * str2double(get(findobj('tag', 'txtCellThresh'), 'String'));
    binaryImage = imextendedmax(currentImage, threshLevel);
    
    %find number of components in the image
    [labeled, numObjects] = bwlabel(binaryImage, 4); %4 is the pixel-connectivity
      
    %find parameters of each cell
    cellProps = regionprops(labeled, 'Area');
    
    %check to see if each region of interest is the right size to be a cell
    for x =1:numObjects    
        if cellProps(x).Area < cellSizeMin || cellProps(x).Area > cellSizeMax
            toRemove = find(labeled == x); %delete items with smaller areas than cellSize
            for y = 1:size(toRemove)
                labeled(toRemove(y))=0;
            end
            numObjects = numObjects -1;
        end
    end

    %remove empty rows of cellProps
    x = 1;
    while x < size(cellProps,1)
        if cellProps(x).Area == 0 
            cellProps(x)= [];
            x=x-1;
        end
        x=x+1;
    end
    
    %shift down to take out gaps
    currentIndex = 1;
    for x = 1:numObjects
        i = 1;
        while size(i,1) < 2    %do until find next number
            [i,j] = find(labeled == currentIndex);
            currentIndex = currentIndex + 1;
        end
        
        for y = 1:size(i, 1)
            labeled(i(y), j(y)) = x;
        end
    end

    ROI = regionprops(labeled,...
        'Centroid',...
        'MajorAxisLength',...
        'MinorAxisLength',...
        'Orientation');    
    info = getappdata(getappdata(0, 'imageBrowser'), 'info');									
                                        
    % determine which pixels are in the ROI
    for i = 1:numel(ROI)
        ROI(i).Centroid = round(ROI(i).Centroid);
        ROI(i).MajorAxisLength = round(ROI(i).MajorAxisLength*.6);
        ROI(i).MinorAxisLength = round(ROI(i).MinorAxisLength*.6);
        ROI(i).Orientation = -ROI(i).Orientation / 180 * pi;
        ROI(i).Shape = 1;											
        ROI(i).Type = 1;
        ROI(i).Lissajous = [];
        ROI(i).NucleusCenter = [];
        ROI(i).NucleusSize = [];
        ROI(i).segments = [];
        ROI(i).ExtendToEdge = false;     
        ROI(i).handle = line(1,1, 'parent', findobj('tag', 'imageAxis'), 'linewidth', 2);
        ROI(i).PointsPerRotation = 200;
        ROI(i).Rotations = 1;
        ROI(i).Frames = 1:info.NumImages;
    end
    ROI = shapeRaster(ROI);
    
    % get data over frames
    ROI = calcROI(ROI);

    if ~isempty(ROI)
        set(findobj('tag', 'cboRoiNumber'), 'string', num2str((1:numel(ROI))'))
    else
        set(findobj('tag', 'cboRoiNumber'), 'string', 'None');
    end
    setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
    setappdata(getappdata(0, 'roiPlot'), 'roiData', [ROI.data]);
    callBack = get(getappdata(getappdata(0, 'roiPlot'), 'roiCommand'), 'callback');
    callBack();    
    
    if ~isempty(ROI)
        drawROI;
    end