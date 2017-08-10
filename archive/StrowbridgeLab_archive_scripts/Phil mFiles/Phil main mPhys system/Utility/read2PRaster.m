function zImage = read2PRaster(FileName, infoOnly)
%reads a .img file
% zImage = read2PRaster(filename)
% zImage = read2PRaster
% zImage = read2PRaster(filename, 'infoOnly')

    if nargin < 1
		if isappdata(0, 'imageBrowser')
			handleList = get(getappdata(0, 'imageBrowser'), 'userData');
			cd(get(handleList.mnuOpen, 'userdata'));
		end
		
        [FileName PathName] = uigetfile({'*.img', 'Image Stacks (*.img)';' *.*', 'All Files (*.*)'},'Select image stack', '');  
		if length(FileName) == 1 && FileName == 0
            return
		end
		if isappdata(0, 'imageBrowser')
			set(handleList.mnuOpen, 'userdata', PathName);
		end
        FileName = [PathName FileName];
    end
	if nargin < 2
		infoOnly = false;
	end
    
    % read header info into structure
    fid = fopen(FileName, 'r');
    zImage.info = struct( 'Filename', '','ProgramNumber',(0),'ProgramMode',(0),'DataOffset',(0),'Width',(0),...
        'Height',(0),'NumImages',(0),'NumChannels',(0),'Comment','', 'MiscInfo','',...
        'ImageSource','','PixelMicrons',(0), 'MillisecondPerFrame',(0),'Objective','',...
        'AdditionalMagnification','', 'SizeOnSource','','SourceProcessing','');
    
    zImage.info.Filename = FileName;
	zImage.info.BitDepth = 12;
    
    zImage.info.ProgramNumber           = fread(fid, 1, 'int32');
    if zImage.info.ProgramNumber == 2
        % we have a quantix file
        fclose(fid);
        zImage = readImage(FileName);
        return 
    end
    zImage.info.ProgramMode             = fread(fid, 1, 'int32');
    zImage.info.DataOffset              = fread(fid, 1, 'int32');
    zImage.info.Width                   = fread(fid, 1, 'int32');
    zImage.info.Height                  = fread(fid, 1, 'int32');
    zImage.info.NumImages               = fread(fid, 1, 'int32');
    zImage.info.NumChannels             = fread(fid, 1, 'int32');
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.Comment(j)          = fread(fid, 1, 'char');
    end   

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.MiscInfo(j)         = fread(fid, 1, 'char');
    end 
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.ImageSource(j)      = fread(fid, 1, 'char');
    end

    zImage.info.PixelMicrons            = fread(fid, 1, 'float32');
    zImage.info.MillisecondPerFrame     = fread(fid, 1, 'float32');
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.Objective(j) = fread(fid, 1, 'char');
    end     
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.AdditionalInformation(j) = fread(fid, 1, 'char');
    end  

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.SizeOnSource(j) = fread(fid, 1, 'char');
    end      

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.SourceProcessing(j) = fread(fid, 1, 'char');
    end     
    
    if isnan(zImage.info.PixelMicrons) || zImage.info.PixelMicrons == 0
        switch upper(zImage.info.Objective)
          case 'OLYMPUS 60X/0.9'
            zImage.info.PixelMicrons = 103.8 / sscanf(zImage.info.SourceProcessing, 'Zoom = %d') / zImage.info.Width;
          case 'OLYMPUS 40X/0.8'
            zImage.info.PixelMicrons = 163 / sscanf(zImage.info.SourceProcessing, 'Zoom = %d') / zImage.info.Width;
        end
    end
    
    zImage.info.origin = [str2double(regexp(zImage.info.MiscInfo, '(?<=X = )[\d.-]*', 'match')) str2double(regexp(zImage.info.MiscInfo, '(?<=Y = )[\d.-]*', 'match'))];
    zLoc = str2double(regexp(zImage.info.MiscInfo, '(?<=Z = )[\d.-]*', 'match'));
    if ~isempty(zLoc)
        zImage.info.origin(3) = zLoc;
    end
    zImage.info.delta = [zImage.info.PixelMicrons zImage.info.PixelMicrons zImage.info.PixelMicrons];
    
    if ~infoOnly
        % read data
        fseek(fid, zImage.info.DataOffset - 1, 'bof');
        zImage.stack = zeros(zImage.info.Width, zImage.info.Height, zImage.info.NumImages, 'int16');
        for x = 1:zImage.info.NumImages
            zImage.stack(:,:,x) = fread(fid, [zImage.info.Width, zImage.info.Height], '*int16');% / 4096;
        end     
        zImage.stack = zImage.stack(:, end:-1:1, :);
		if nargout < 1
			assignin('base', 'zImage', zImage);
		end
    else
        zImage.stack = -1;
    end
    fclose(fid);   