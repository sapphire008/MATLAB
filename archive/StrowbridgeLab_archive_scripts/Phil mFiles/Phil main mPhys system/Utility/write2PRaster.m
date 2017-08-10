function zImage = write2PRaster(zImage, FileName)
%writes a .img file
% FileName = read2PRaster(zImage)

persistent lastDir

    if nargin < 2
        if ~isempty(lastDir)
			cd(lastDir);
        end
        filenameValid = 0;
        suggestedName = '';
        PathName = [];
        while ~filenameValid
            if ~isempty(PathName)
                cd(PathName);
                msgTitle = 'Invalid name.  Must be Cell.part.#.img format';
            else
                msgTitle = 'Cell.part.#.img';
            end            
            [FileName PathName] = uiputfile({'*.img', 'Image Stacks (*.img)';' *.*', 'All Files (*.*)'}, msgTitle, suggestedName);  
            if length(FileName) == 1 && FileName == 0
                return
            end
            if numel(FileName) < 4 || ~strcmp(FileName(end - 3:end), '.img')
                FileName = [FileName '.img'];
            end
%             if numel(find(FileName == '.')) < 3
%                 whereDots = find(FileName == '.');
%                 if numel(whereDots) == 2
%                     if all(FileName(whereDots(end - 1) + 1:whereDots(end) - 1) > 47 & FileName(whereDots(end - 1) + 1:whereDots(end) - 1) < 58)
%                         suggestedName = [FileName(1:whereDots(1)) 'main' FileName(whereDots(1):end)];
%                     else
%                         suggestedName = [FileName(1:whereDots(2)) '1' FileName(whereDots(2):end)];
%                     end
%                 else
%                     suggestedName = [FileName(1:whereDots(1)) 'main.1' FileName(whereDots(1):end)];
%                 end
%             else
                filenameValid = 1;
%             end
        end
        FileName = [PathName FileName];
        whichHandle = findobj('tag', 'frmDisplayImage');
        if ~isempty(whichHandle)
            set(whichHandle, 'name', FileName);
        end
		lastDir = PathName;
    end
    
% write header info into structure
fid = fopen(FileName, 'w');
    
    zImage.info.Filename = FileName;
    
    fwrite(fid, zImage.info.ProgramNumber , 'int32');

	fwrite(fid, zImage.info.ProgramMode, 'int32');
    fwrite(fid, zImage.info.DataOffset, 'int32');
    fwrite(fid, zImage.info.Width, 'int32');
    fwrite(fid, zImage.info.Height , 'int32');
    fwrite(fid, zImage.info.NumImages, 'int32');
    fwrite(fid, zImage.info.NumChannels, 'int32');
    
    fwrite(fid, length(zImage.info.Comment), 'int16');
    fwrite(fid, zImage.info.Comment, 'char');

    zImage.info.MiscInfo = [zImage.info.MiscInfo sprintf(', X = %g, Y = %g, Z = %g', zImage.info.origin)];
    fwrite(fid, length(zImage.info.MiscInfo), 'int16');
    fwrite(fid, zImage.info.MiscInfo, 'char');
    
    fwrite(fid, length(zImage.info.ImageSource), 'int16');
	fwrite(fid, zImage.info.ImageSource, 'char');

    fwrite(fid, zImage.info.PixelMicrons, 'float32');
    fwrite(fid, zImage.info.MillisecondPerFrame, 'float32');
    
	fwrite(fid, length(zImage.info.Objective), 'int16');
    fwrite(fid, zImage.info.Objective, 'char');
    
    fwrite(fid, length(zImage.info.AdditionalInformation), 'int16');
    fwrite(fid, zImage.info.AdditionalInformation, 'char');

    fwrite(fid, length(zImage.info.SizeOnSource), 'int16');
    fwrite(fid, zImage.info.SizeOnSource, 'char');

    fwrite(fid, length(zImage.info.SourceProcessing), 'int16');
    fwrite(fid, zImage.info.SourceProcessing, 'char'); 

	fwrite(fid, zeros(zImage.info.DataOffset - 1 - ftell(fid), 1), 'char');
	for x = 1:zImage.info.NumImages
		 fwrite(fid, zImage.stack(:,end:-1:1,x), 'int16');
	end     

fclose(fid);   