function fileName = writeBiorad(fileName, imageLocation, objectiveIndex)
% write a biorad format file
% fileName = writeBiorad(fileName, location of bitmap data, objectiveIndex);

if fileName(end - 3) == '.'
	fileName = [fileName(1:end - 4) '.pic'];
else
	fileName = [fileName '.pic'];
end

% make sure the file name isn't taken
fileInfo = dir(fileName);
if numel(fileInfo) ~=0
	whereDot = find(fileName == '.', 2, 'last');
	tries = 1;
	while numel(fileInfo) > 0 && tries < 100
		tries = tries + 1;		
		fileName = [fileName(1:whereDot(1)) sprintf('%0.0f', tries) '.pic'];
		fileInfo = dir(fileName);
	end
end

fid = fopen(fileName, 'w');

	info = imfinfo(imageLocation);
	imageData = imread(imageLocation, 'bmp');	
	% write header data
	fwrite(fid, info.Width, 'int16');
	fwrite(fid, info.Height, 'int16');
	fwrite(fid, 1, 'int16');

	fwrite(fid, [0 255], 'int16');
	fwrite(fid, -1, 'int32');
	fwrite(fid, [1 0], 'int16');
    tempFileName = fileName(find(fileName == '\', 1, 'last') + 1:end)';
	fwrite(fid, [tempFileName(1:min([end 32])); zeros(32 - length(tempFileName), 1)], 'char');
	fwrite(fid, [0 7 12345 0 255 7 0], 'int16');
	fwrite(fid, 1, 'int16');
	fwrite(fid, 1, 'int16');
	fwrite(fid, [0 0 0], 'int16');
            
	% write image data
	fwrite(fid, imageData(:,:,1)', 'uchar');	

	fwrite(fid, 0, 'int16');

	% write notes
	objectiveNames = getpref('objectives', 'nominalMagnification');
	objectiveDeltas = getpref('objectives', 'deltas');
	objectiveOrigins = getpref('objectives', 'origins');
    micronsPerMit = getpref('objectives', 'micronPerMit');

	if ispref('mitutoyo', 'xComm')
		% read the coordinates from there
		currentPosition = nan(3,1);
        numTries = 1;
        while numTries < 10 && isnan(currentPosition(1))
            currentPosition = readMitutoyo;
            numTries = numTries + 1;
        end
        
	elseif ispref('asi', 'commPort')
		currentPosition = readASI;
	else
		currentPosition = [0 0];
	end
	
	xCoord = num2str(currentPosition(1) * micronsPerMit(1) + objectiveOrigins(objectiveIndex, 1) + -1.05 * objectiveDeltas(objectiveIndex));
	yCoord = num2str(currentPosition(2) * micronsPerMit(2) + objectiveOrigins(objectiveIndex, 2) + -0.62 * objectiveDeltas(objectiveIndex));

	writeComment(fid, 'SCALE_FACTOR = 20.000000')
	writeComment(fid, ['LENS_MAGNIFICATION = ' objectiveNames{objectiveIndex}(find(objectiveNames{objectiveIndex} == ' ', 1, 'first') + 1:find(objectiveNames{objectiveIndex} == 'x', 1, 'first') - 1)])
	writeComment(fid, 'PIXEL_BIT_DEPTH = 8')
	writeComment(fid, 'Z_CORRECT_FACTOR = 1.000000 1.000000')
	writeComment(fid, 'PIC_FF_VERSION = 4.5')
	writeComment(fid, 'RAMP1_MIN = 0')
	writeComment(fid, 'RAMP1_MAX = 255')
	writeComment(fid, 'RAMP_GAMMA1 = 1')

	writeComment(fid, ['AXIS_2 001 ' xCoord ' ' sprintf('%1.4f', objectiveDeltas(objectiveIndex)) ' Microns'])
	writeComment(fid, ['AXIS_3 001 ' yCoord ' ' sprintf('%1.4f', objectiveDeltas(objectiveIndex)) ' Microns'])

	writeComment(fid, ['INFO_OBJECTIVE_NAME = ' objectiveNames{objectiveIndex}])
	writeComment(fid, ['INFO_OBJECTIVE_MAGNIFICATION = ' objectiveNames{objectiveIndex}(find(objectiveNames{objectiveIndex} == ' ', 1, 'first') + 1:find(objectiveNames{objectiveIndex} == 'x', 1, 'first') - 1)])		
	writeComment(fid, 'INFO_OBJECTIVE_ZOOM = 1')
	writeComment(fid, 'INFO_PAN_COORDS_X = 0')
	writeComment(fid, 'INFO_PAN_COORDS_Y = 0')
	writeComment(fid, 'INFO_SCAN_ROTATE = 0')				

	writeComment(fid, 'INFO_RASTER_RATE = 0')
	writeComment(fid, 'INFO_FRAME_RATE = 1')
	writeComment(fid, 'INFO_PIXEL_DWELL = 0')
	
	fwrite(fid, zeros(640, 1), 'char');

fclose(fid);

function writeComment(fid, comment)

	fwrite(fid, -1, 'int16');
	fwrite(fid, 1, 'int32');
	fwrite(fid, [0 1 20 0 0],  'int16');
	
    % pad the comment up to 80 characters
    if numel(comment) > 80
        % must truncate the comment or the file will be corrupted, but
        % should never get to here
        comment = comment(1:80);
    end
	fwrite(fid,  [comment  zeros(1, 80 - length(comment))], 'char');
	
	
% 	http://rsb.info.nih.gov/ij/plugins/download/Biorad_Reader.java
%   The header of Bio-Rad .PIC files is fixed in size, and is 76 bytes.
% 
%   ------------------------------------------------------------------------------
%   'C' Definition              byte    size    Information
%   (bytes)   
%   ------------------------------------------------------------------------------
%   int nx, ny;                 0       2*2     image width and height in pixels
%   int npic;                   4       2       number of images in file
%   int ramp1_min, ramp1_max;   6       2*2     LUT1 ramp min. and max.
%   NOTE *notes;                10      4       no notes=0; has notes=non zero
%   BOOL byte_format;           14      2       bytes=TRUE(1); words=FALSE(0)
%   int n;                      16      2       image number within file
%   char name[32];              18      32      file name
%   int merged;                 50      2       merged format
%   unsigned color1;            52      2       LUT1 color status
%   unsigned file_id;           54      2       valid .PIC file=12345
%   int ramp2_min, ramp2_max;   56      2*2     LUT2 ramp min. and max.
%   unsigned color2;            60      2       LUT2 color status
%   BOOL edited;                62      2       image has been edited=TRUE(1)
%   int _lens;                  64      2       Integer part of lens magnification
%   float mag_factor;           66      4       4 byte real mag. factor (old ver.)
%   unsigned dummy[3];          70      6       NOT USED (old ver.=real lens mag.)	