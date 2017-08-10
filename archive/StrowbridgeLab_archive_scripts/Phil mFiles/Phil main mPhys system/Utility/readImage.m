function zImage = readImage(FileName, infoOnly)
%reads a quantix image file
% zImage = readImage(filename)
% zImage = readImage;
% info = readImage(filename, 'infoOnly')

	allFormats = imformats;
	if nargin < 1
        try
            cd(get(findobj('tag', 'mnuOpen'), 'userdata'));           
        end
		allString = '*.';
		for i = 1:numel(allFormats)
			allString = [allString allFormats(i).ext{1} ';*.'];
		end
        [FileName PathName] = uigetfile({'*.img;*.bmp;*.pic', 'All Lab Files (*.img, *.bmp, *.pic)';'*.img', 'Ben Images (*.img)';'*.bmp', 'Bitmaps (*.bmp)';'*.pic','Biorad Images (*.pic)';allString(1:end - 3), 'Standard Image Formats';' *.*', 'All Files (*.*)'},'Select image', '');  
        if length(FileName) == 1 && FileName == 0
            return
        end
        set(findobj('tag', 'mnuOpen'), 'userdata', PathName);   
        FileName = [PathName FileName];
	end
	
	if nargin < 2
		infoOnly = 0;
	end
	
    % read header info into structure
    fid = fopen(FileName, 'r');
    if fid < 0
        return
    end
		zImage.info = struct('ProgramNumber',(0),'ProgramMode',(0),'origin',[0 0 0],'delta',[1 1 1],'DataOffset',(0),'Width',(0),'Height',(0),'NumImages',(0),'NumChannels',(0),'PixelMicrons',(0), 'Comment',(0), 'MiscInfo',(0));
		if is2Praster(fid);
			% we have a raster file
			fclose(fid);
			zImage = read2PRaster(FileName, infoOnly);
		elseif isBiorad(fid)
			% this looks like a biorad file
			fclose(fid);
			[zImage.stack zImage.info] = readBiorad(FileName);            
		elseif isBmp(fid)
			% this looks like a bmp file
			fclose(fid);
			zImage.stack = imread(FileName);
			zImage.stack = double(fliplr(zImage.stack(:,:,1)')) / 255;
			zImage.info.ProgramNumber = 42;
			zImage.info.ProgramMode    =   0;
			zImage.info.DataOffset     =   54;
			zImage.info.Width          =   size(zImage.stack, 1);
			zImage.info.Height         =   size(zImage.stack, 2);
			zImage.info.BitDepth       =   8;
			zImage.info.NumImages      =   1;
			zImage.info.NumChannels    =   1;
			zImage.info.PixelMicrons   =   1;
			zImage.info.Filename = FileName;
		elseif ismember(FileName(end - 2:end), [allFormats.ext])
			% handle non-lab formats			
			fclose(fid);
			zImage.info = imfinfo(FileName);
			if ~infoOnly
				zImage.stack = imread(FileName);
                if size(zImage.info, 2) > 1
					zImage.info = zImage.info(1,1);
                end
                if isappdata(0, 'imageBrowser')
                    cmap = get(getappdata(0, 'imageDisplay'), 'colormap');
                else
                    cmap = colormap;
                end
				if strcmp(zImage.info.ColorType, 'truecolor')
					zImage.stack = fliplr(double(rgb2ind(zImage.stack, cmap, 'nodither'))' ./ size(cmap,1));
				end
				zImage.info.NumImages = size(zImage.stack, 3);	
                zImage.info.origin = [0 0 0];
			end
        else	
            % try the loci formats
%             zImage = bfopen(FileName);
%             zImage.NumImages = size(zImage, 3);
%             zImage.origin = [0 0 0];
            
% 			% must be a quantix file
% 			fseek(fid, 4, 'bof');
% 			zImage.info.ProgramMode    =   fread(fid, 1, 'int32');
% 			zImage.info.DataOffset     =   fread(fid, 1, 'int32');
% 			zImage.info.Width          =   fread(fid, 1, 'int32');
% 			zImage.info.Height         =   fread(fid, 1, 'int32');
% 			zImage.info.NumImages      =   fread(fid, 1, 'int32');
% 			zImage.info.NumChannels    =   fread(fid, 1, 'int32');
% 			zImage.info.PixelMicrons   =   fread(fid, 1, 'float32');
% 			zImage.info.delta = [zImage.info.PixelMicrons zImage.info.PixelMicrons zImage.info.PixelMicrons];
% 			zImage.info.Filename = FileName;
% 			zImage.info.BitDepth = 14;
% 
% 			if ~infoOnly
% 				% move file pointer to beginning of image data
% 				fseek(fid, 2999, 'bof');  
% 
% 				% read image data into array
% 				zImage.stack = double(zeros(zImage.info.Width, zImage.info.Height, zImage.info.NumImages));
% 
% 				for x = 1:zImage.info.NumImages-1
% 					zImage.stack(:,:,x) = fread(fid, [zImage.info.Width, zImage.info.Height], 'int16') / 4096;
% 				end 	
% 				fclose(fid);
% 			end
            zImage = [];
		end
% 		zImage.info.fileName = FileName;
      
	if isappdata(0, 'imageBrowser') && ((isprop(gcbo, 'type') && strcmp(get(gcbo, 'type'), 'uimenu') && strcmp(get(gcbo, 'Label'), 'Open...'))  || (nargin > 1 && strcmp(infoOnly, 'focus')))
        imageBrowser(zImage);
	end       
	
	function boolValue = is2Praster(fid)
		fseek(fid, 0, 'bof');
		boolValue = fread(fid, 1, 'int32') == 3;
		
	function boolValue = isBmp(fid)
		fseek(fid, 0, 'bof');
		boolValue = fread(fid, 1, 'int16') == 19778;	
		
	function boolValue = isBiorad(fid)
		fseek(fid, 54, 'bof');
		boolValue = fread(fid, 1, 'int16') == 12345;			