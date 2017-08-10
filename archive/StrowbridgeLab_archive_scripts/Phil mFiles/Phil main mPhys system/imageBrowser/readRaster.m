function zImage = readRaster(FileName)
%reads a .img file

    handleList = getappdata(0, 'imageBrowser');

    if nargin < 1
        cd(get(handleList.mnu.file.open, 'userdata'));

        [FileName PathName] = uigetfile({'*.img', 'Image Stacks (*.img)';' *.*', 'All Files (*.*)'},'Select image stack', '');  
        if length(FileName) == 1 && FileName == 0
            return
        end
        set(handleList.mnu.file.open, 'userdata', PathName);   
        FileName = [PathName FileName];
    end
    
    % read header info into structure
    fid = fopen(FileName, 'r');
    zImage.info = struct('SVX0',(0),'SVY0',(0),'SVXInc',(0),'SVYInc',(0),...
        'Width',(0),'Height',(0),'XCenter',(0),'YCenter',(0), 'Rotation',(0),...
        'DisplayScale',(0),'frames',(0),'Channels',(0),'FileName','',...
        'DataFolder','','DataFolderWriteOkay',(0),'OutputFolder','',...
        'FileRoot','','ContainsData',(0),'ImageSource','','PixelMicrons',(0),...
        'MillisecondPerFrame',(0),'Objective','','AdditionalMagnification','',...
        'SizeOnSource','','Comment','','MiscInfo','');
    
    zImage.info.SVX0            = fread(fid, 1, 'float32');
    zImage.info.SVY0            = fread(fid, 1, 'float32');
    zImage.info.SVXInc          = fread(fid, 1, 'float32');
    zImage.info.SVYInc          = fread(fid, 1, 'float32');
    zImage.info.Width           = fread(fid, 1, 'int32');
    zImage.info.Height           = fread(fid, 1, 'int32');
    zImage.info.XCenter         = fread(fid, 1, 'int32');
    zImage.info.YCenter         = fread(fid, 1, 'int32');
    zImage.info.Rotation        = fread(fid, 1, 'float32');
    zImage.info.DisplayScale    = fread(fid, 1, 'float32');
    zImage.info.frames          = fread(fid, 1, 'int32');
    zImage.info.Channels        = fread(fid, 1, 'int32');
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.Filename(j) = fread(fid, 1, 'char');
    end   

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.DataFolder(j) = fread(fid, 1, 'char');
    end 
    
    zImage.info.DataFolderWriteOkay = fread(fid, 1, 'int16');
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.OutputFolder(j) = fread(fid, 1, 'char');
    end

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.FileRoot(j) = fread(fid, 1, 'char');
    end     
    
    % read data
    for x = 1:zImage.info.NumImages-1
        zImage.stack(:,:,x) = fread(fid, [zImage.info.Width, zImage.info.Height, zImage.info.frames], 'int16') / 4096;
    end     
    
    % finish header
     zImage.info.ContainsData = fread(fid, 1, 'int16');

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.ImageSource(j) = fread(fid, 1, 'char');
    end  
    
    zImage.info.PixelMicrons    = fread(fid, 1, 'float32');
    zImage.info.MillisecondsPerFrame = fread(fid, 1, 'float32');
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.Objective(j) = fread(fid, 1, 'char');
    end      

    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.AdditionalMagnification(j) = fread(fid, 1, 'char');
    end     
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.SizeOnSource(j) = fread(fid, 1, 'char');
    end      
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.SourceProcessing(j) = fread(fid, 1, 'char');
    end      
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.Comment(j) = fread(fid, 1, 'char');
    end      
    
    stringLen = fread(fid, 1, 'int16');
    for j = 1:stringLen
        zImage.info.MiscInfo(j) = fread(fid, 1, 'char');
    end      
    
    zImage.info.Filename = FileName;
    assignin('base', 'zImage', zImage);
    fclose(fid);
    
    handleList = getappdata(0, 'imageBrowser');
    setappdata(handleList.frmDisplayImage, 'info', zImage.info);    
    
    updateAverage
    displayImage;