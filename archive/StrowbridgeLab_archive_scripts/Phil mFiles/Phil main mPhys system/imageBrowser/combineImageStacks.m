function zImage = combineImageStacks(matchText)
%reads a .img stack and compresses it
% needs to not be sparse output and also needs to use normxcorr2 to
% correlate image edges
% c = normxcorr2(sub_onion(:,:,1),sub_peppers(:,:,1));
% figure, surf(c), shading flat
% offset found by correlation
% [max_c, imax] = max(abs(c(:)));
% [ypeak, xpeak] = ind2sub(size(c),imax(1));
% corr_offset = [(xpeak-size(sub_onion,2)) (ypeak-size(sub_onion,1))];
% relative offset of position of subimages
% rect_offset = [(rect_peppers(1)-rect_onion(1)) (rect_peppers(2)-rect_onion(2))]; 
% total offset offset = corr_offset + rect_offset;
% xoffset = offset(1);
% yoffset = offset(2);

% for filling the cell use demo on detecting a cell via segmentation
% [junk threshold] = edge(I, 'sobel');
% fudgeFactor = .5;
% BWs = edge(I,'sobel', threshold * fudgeFactor);
% se90 = strel('line', 3, 90);
% se0 = strel('line', 3, 0);
% BWsdil = imdilate(BWs, [se90 se0]);
% BWdfill = imfill(BWsdil, 'holes');
% BWnobord = imclearborder(BWdfill, 4);
% seD = strel('diamond',1);
% BWfinal = imerode(BWnobord,seD);
% BWfinal = imerode(BWfinal,seD);
% BWoutline = bwperim(BWfinal);
% Segout = I;
% Segout(BWoutline) = 255;

    if nargin < 2
		if nargin < 1
			cd(get(findobj('tag', 'mnuCombineZStacks'), 'userdata'))
		else
			cd(PathName);
		end
        [FileName PathName] = uigetfile({'*.img', 'Two Photon Images (*.img)'; '*.*', 'All Files'}, 'Select an image from the cell');  
		if PathName == 0
            return
		end
		if nargin < 1
			set(findobj('tag', 'mnuCombineZStacks'), 'userdata', PathName);
		end
    end
    
    % find the cell name
	whereSep = find(FileName == '.', 3, 'last');		
    fileList = dir(PathName);
    fileList = fileList(~[fileList.isdir] & (~cellfun('isempty', strfind({fileList.name}, '.img'))) & (~cellfun('isempty', strfind({fileList.name}, FileName(1:whereSep(1))))));	
    
	% find the unique stack names
    matches = {};
	stacks = regexp({fileList.name}, '\w*\.\w*\.(?=\d*\.img)', 'match');
	for i = 1:numel(stacks)
        if ~isempty(stacks{i})
            matches{end + 1} = stacks{i}{1};
        end
	end
	matches = unique(matches);
	
    % pre-allocate the space
    zImage = readImage([PathName '\' FileName], 'infoOnly');
%     tempStack = double(zeros(zImage.info.Width, zImage.info.Height, numel(matches)));    
    
    % create a compressed zStack for each image
	numHits = 0;
    rowIndices = zeros(zImage.info.Width * zImage.info.Height * numel(matches), 1);
    columnIndices = zeros(zImage.info.Width * zImage.info.Height * numel(matches), 1);
    imageData = zeros(zImage.info.Width * zImage.info.Height * numel(matches), 1);
    rowSeed = reshape(repmat((0:zImage.info.Width - 1)', 1, zImage.info.Height), [], 1);
    columnSeed = reshape(repmat(0:zImage.info.Height - 1, zImage.info.Width, 1), [], 1);    
    for i = 1:length(matches)
        tempImage = compressImageStack([PathName matches{i}]);
        if zImage.info.Width == tempImage.info.Width &&...
                zImage.info.Height == tempImage.info.Height &&...
                strcmp(zImage.info.SizeOnSource, tempImage.info.SizeOnSource)
%             tempStack(:,:,i - numSkipped) = tempImage.stack;
            tempInfo(numHits + 1) = tempImage.info;
            newLoc = round(transferPoints([1 1], tempImage.info, zImage.info));
            rowIndices(numHits * zImage.info.Width * zImage.info.Height + 1:(numHits + 1) * zImage.info.Width * zImage.info.Height) = rowSeed + newLoc(1);
            columnIndices(numHits * zImage.info.Width * zImage.info.Height + 1:(numHits + 1) * zImage.info.Width * zImage.info.Height) = columnSeed + newLoc(2);
            imageData(numHits * zImage.info.Width * zImage.info.Height + 1:(numHits + 1) * zImage.info.Width * zImage.info.Height) = reshape(tempImage.stack, [], 1);
            
            numHits = numHits + 1;
        end
    end
    if numel(rowIndices) > numHits * zImage.info.Width * zImage.info.Height
        rowIndices(numHits * zImage.info.Width * zImage.info.Height + 1:end) = [];
        columnIndices(numHits * zImage.info.Width * zImage.info.Height + 1:end) = [];
        imageData(numHits * zImage.info.Width * zImage.info.Height + 1:end) = [];
    end
    zImage.info.Width = range(rowIndices) + 1;
    zImage.info.Height = range(columnIndices) + 1;
    zImage.stack = nan(zImage.info.Width, zImage.info.Height);
    rowIndices = rowIndices - min(rowIndices) + 1;
    columnIndices = columnIndices - min(columnIndices) + 1;
    zImage.stack(sub2ind(size(zImage.stack), rowIndices, columnIndices)) = imageData;
    % combine the images into one large image, resampling and correlating
    % to achieve a precise colocation
%     for i = 1:length(tempInfo)
%         % select as set points all points within 20 pixels of the shared
%         % edge using traceCell, then pass these from both images to
%         % cp2tform allowing only 'linear transformational' alignment
%         % then add the imtransform of the image to the growing composite
%         % image
%         
%     end
    
    zImage.info.origin = min(cat(1, tempInfo.origin));
    if nargout < 1
        assignin('base', 'zImage', zImage);
        imageBrowser(zImage);            
    end