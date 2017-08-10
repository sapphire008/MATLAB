function zImage = compressImageStack(matchText)
% takes a pattern or a cell array of full paths and generates a single
% zData structure
	allFormats = imformats;
	if nargin < 1
        if isappdata(0, 'imageBrowser')
            try
                cd(get(findobj('tag', 'mnuOpenZStack'), 'userdata'));
            catch
                warning([get(findobj('tag', 'mnuOpenZStack'), 'userdata') 'is not a directory']);
            end
        end
		allString = '*.';
		for i = 1:numel(allFormats)
			allString = [allString allFormats(i).ext{1} ';*.'];
		end        
        [FileName PathName] = uigetfile({'*.img;*.bmp;*.pic', 'All Lab Files (*.img, *.bmp, *.pic)';'*.img', 'Ben Images (*.img)';'*.bmp', 'Bitmaps (*.bmp)';'*.pic','Biorad Images (*.pic)';allString(1:end - 3), 'Standard Image Formats';' *.*', 'All Files (*.*)'},'Select image', '');  
		if PathName == 0
            return
		end
		if isappdata(0, 'imageBrowser')
			set(findobj('tag', 'mnuOpenZStack'), 'userdata', PathName);
		end
		whereConst = find(FileName == '.', 2, 'last');
		if numel(whereConst) == 2
			matchText = FileName(1:whereConst(1));
		else
			matchText = FileName(end - 3:end);
		end
	else
		if ~iscell(matchText)
			PathName = matchText(1:find(matchText == '\', 1, 'last'));
			matchText = matchText(find(matchText == '\', 1, 'last') + 1:end);
		end
	end
    
    if ~iscell(matchText)
		% open all .img files in folder
		fileList = dir(PathName);
		fileList = {fileList(~[fileList.isdir] & (~cellfun('isempty', strfind({fileList.name}, matchText))) & (~cellfun('isempty', strfind({fileList.name}, FileName(end - 3:end))))).name};
	else
		fileList = matchText;
		PathName = fileList{1}(1:find(fileList{1} == '\', 1, 'last'));
		for i = 1:numel(fileList)
			fileList{i} = fileList{i}(find(fileList{i} == '\', 1, 'last') + 1:end);
		end
		dots = find(fileList{1} == '.', 2, 'first');
		matchText = fileList{1}(1:dots(2));
    end
	    
	if numel(fileList) > 1
		% concatenate the episodes into the standard list format
		% put the data into matrices
		epiData = zeros(numel(fileList), 1);
        if numel(find(fileList{1} == '.')) > 2
            % new style naming cell.location.#.img
            for i = 1:numel(fileList)
                dots = find(fileList{i} == '.', 2, 'last');
                epiData(i) = str2double(fileList{i}(dots(1) + 1:dots(2) - 1));
            end
        else
            % old style naming name.C#.img
            for i = 1:numel(fileList)
                dots = find(fileList{i} == '.', 2, 'last');
                if numel(dots) > 1
                    epiData(i) = str2double(fileList{i}(dots(1) + 2:dots(2) - 1));
                end 
            end            
        end

		% sort the data sets
		[whichEpis indices] = sort(epiData);
		% concatenate consecutive runs
		episodeName = strcat(matchText, sprintf('%0.0f',whichEpis(1)));
		lastEpi = whichEpis(1);
		inRun = 0;
		for j = 2:length(whichEpis)
			if whichEpis(j) - lastEpi == 1
				inRun = 1;
			else
				if inRun
					episodeName = strcat(episodeName, '-', sprintf('%0.0d',lastEpi));
					inRun = 0;
				end
				episodeName = strcat(episodeName, ',', sprintf('%0.0d',whichEpis(j)));
			end
			lastEpi = whichEpis(j);
		end
        if inRun
			episodeName = strcat(episodeName, '-', sprintf('%0.0d',lastEpi));
        end
        fileList = fileList(indices);        
	else
		episodeName = matchText;
	end % numFiles > 1	
    
	% determine what is in the current zImage and just alter it if possible
    if evalin('base', 'exist(''zImage'', ''var'') && isfield(zImage.info, ''fileNames'')')
		oldImage = evalin('base', 'zImage');
		evalin('base', 'clear zImage');

		% pre-allocate the space
		zImage = readImage([PathName fileList{1}]);
		zImage.stack = zeros(zImage.info.Width, zImage.info.Height, numel(fileList), class(zImage.stack));
		
		zImage.info.NumImages = 0;
		% fill it up
		for i = 1:length(fileList)
			whichOld = find(strcmp(oldImage.info.fileNames, fileList{i}));
			if ~isempty(whichOld)
				zImage.info.NumImages = zImage.info.NumImages + 1;   
				zImage.info.fileNames{zImage.info.NumImages} = fileList{i};		
				zImage.stack(:,:,zImage.info.NumImages) = oldImage.stack(:,:,whichOld);			
				zImage.info.sliceDepths(zImage.info.NumImages) = oldImage.info.sliceDepths(whichOld);
			else
				tempImage = readImage([PathName '\' fileList{i}]);
				if zImage.info.Width == tempImage.info.Width &&...
						zImage.info.Height == tempImage.info.Height
					zImage.info.NumImages = zImage.info.NumImages + 1;   
					zImage.info.fileNames{zImage.info.NumImages} = fileList{i};
					zImage.stack(:,:,zImage.info.NumImages) = mean(tempImage.stack, 3);
					if numel(tempImage.info.origin) == 3
						zImage.info.sliceDepths(zImage.info.NumImages) = tempImage.info.origin(3);
					else
						zImage.info.sliceDepths(zImage.info.NumImages) = nan;
					end
				end
			end
		end
		zImage.stack(:,:,zImage.info.NumImages + 1:end) = [];		
	else
		evalin('base', 'clear zImage');

		% pre-allocate the space
		zImage = readImage([PathName fileList{1}]);
		zImage.stack = zeros(zImage.info.Width, zImage.info.Height, numel(fileList), class(zImage.stack));		
		zImage.info.NumImages = 0;
		% fill it up
		for i = 1:length(fileList)
			tempImage = readImage([PathName '\' fileList{i}]);
			if zImage.info.Width == tempImage.info.Width &&...
					zImage.info.Height == tempImage.info.Height
				zImage.info.NumImages = zImage.info.NumImages + 1;   
				zImage.info.fileNames{zImage.info.NumImages} = fileList{i};
				zImage.stack(:,:,zImage.info.NumImages) = mean(tempImage.stack, 3);
				if numel(tempImage.info.origin) == 3
					zImage.info.sliceDepths(zImage.info.NumImages) = tempImage.info.origin(3);
				else
					zImage.info.sliceDepths(zImage.info.NumImages) = nan;
				end
			end
		end
		zImage.stack(:,:,zImage.info.NumImages + 1:end) = [];
    end	
    
    zImage.info.Filename = episodeName;
	
	if exist('tempImage', 'var')
		zImage.info.origin = tempImage.info.origin;
	end
	
	% sort by slice depth
% 	[indices indices] = sort(zImage.info.sliceDepths);
% 	zImage.stack = zImage.stack(:, :, indices);

    if nargout < 1
		set(findobj('tag', 'cboAverageType'), 'value', 3);
		set(findobj('tag', 'cboAverageLocation'), 'value', 1);
		set(findobj('tag', 'cboAverageNumber'), 'value', numel(get(findobj('tag', 'cboAverageNumber'), 'string')));
		imageBrowser(zImage);
		zImage = [];
    else
        % find the maximum projection
        zImage.stack = max(zImage.stack, [], 3);    
		zImage.info.NumImages = 1;
    end    