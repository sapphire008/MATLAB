function [data info] = readPic(filename)
% adapted from:
% http://www.bu.edu/cism/cismdx/ref/dx.Samples/util/biorad-pic/PIC2dx.c
% http://rsb.info.nih.gov/ij/plugins/download/Biorad_Reader.java

% constants
HEADER_LEN  = 76;
NOTE_LEN    = 96;

NOTE_TYPE_LIVE = 1;         % Information about live collection
NOTE_TYPE_FILE1 = 2;        % Note from image #1					
NOTE_TYPE_NUMBER = 3;       % Number in multiple image file		
NOTE_TYPE_USER = 4;         % User notes generated notes			
NOTE_TYPE_LINE = 5;         % Line mode info						
NOTE_TYPE_COLLECT = 6;      % Collect mode info					
NOTE_TYPE_FILE2 = 7;        % Note from image #2					
NOTE_TYPE_SCALEBAR = 8;     % Scale bar info						
NOTE_TYPE_MERGE = 9;        % Merge Info							
NOTE_TYPE_THRUVIEW = 10;    % Thruview Info							
NOTE_TYPE_ARROW = 11;       % Arrow info								
NOTE_TYPE_VARIABLE = 20;    % Again internal variable ,except held as  
NOTE_TYPE_STRUCTURE = 21;   % a structure.

AXT_D = 1;                  % distance in microns  		
AXT_T = 2;                  % time in sec					
AXT_A = 3;                  % angle in degrees				
AXT_I = 4;                  % intensity in grey levels		
AXT_M4 = 5;                 % 4-bit merged image			
AXT_R = 6;                  % Ratio						
AXT_LR = 7;                 % Log Ratio					
AXT_P = 8;                  % Product						
AXT_C = 9;                  % Calibrated					
AXT_PHOTON = 10;			% intensity in photons/sec		
AXT_RGB = 11;               % RGB type                     
AXT_SEQ = 12;               % SEQ type (eg 'experiments')	
AXT_6D = 13;                % 6th level of axis			
AXT_TC = 14;				% Time Course axis				
AXT_S = 15;                 % Intensity signoid cal		
AXT_LS = 16;				% Intensity log signoid cal	
AXT_BASE = base2dec('FF', 16);	% mask for axis TYPE			
AXT_XY = base2dec('100', 16);	% axis is XY, needs updating by LENS 
AXT_WORD = base2dec('200', 16);  % axis is word. only corresponds to axis[0] 

% structures
info = struct(...           offset  size    info
	'Width', 0,...
	'Height', 0,...         0       2*2     image width and height in pixels
	'NumImages', 0,...      4       2       number of images in file
	'ramp1Min', 0,... 
    'ramp1Max', 255,...     6       2*2     LUT1 ramp min. and max.
	'notes', 0,...          10      4       no notes=0; has notes=non zero
	'byteFormat', 0,...     14      2       bytes=TRUE(1); words=FALSE(0)
	'n', 0,...              16      2       image number within file
	'name', '',...          18      32      file name
	'merged', 0,...         50      2       merged format
	'color1', 0,...         52      2       LUT1 color status
	'fileID', 0,...         54      2       valid .PIC file=12345
	'ramp2_min', 0,...
    'ramp2_max', 255,...    56      2*2     LUT2 ramp min. and max.
	'color2', 0,...         60      2       LUT2 color status
	'edited', 0,...         62      2       image has been edited=TRUE(1)
	'lens', 0,...           64      2       Integer part of lens magnification
	'mag_factor', 0,...     66      4       4 byte real mag. factor (old ver.)
	'dummy', 0,...          70      6       6 byte filler now, (older versions stored a 4 byte real lens mag here.) 
    'imageSize', 0,...      in bytes
    'notesOffset', 0,...    in bytes
    'fileSize', 0,...       in bytes
    'origin', [0 0 0],...   3D origin X,Y,Z, in microns
    'delta', [1 1 1],...    3D voxel spacings X,Y,Z
    'mixerNum', -1,...      A=0,B=1,C=2  (-1 = N/A)
    'numChannelFiles', 1);  % One channel per file

% display file box if no file given
if nargin == 0
    [FileName,PathName] = uigetfile({'*.pic','Biorad Files (*.pic)'}, 'Select file to open');
    if FileName == 0
        return
    end
    filename = strcat(PathName, FileName)
end

% read header
fid = fopen(filename, 'r');

if fid ~= -1
    info.Filename = filename;
  
    % check to make sure that the file isn't zero length
    fseek(fid, 0, 'eof');   
    info.endOfFile = ftell(fid);
    if info.endOfFile > HEADER_LEN
        % read header
        fseek(fid, 0, 'bof');
        info.Width = fread(fid, 1, 'int16');
        info.Height = fread(fid, 1, 'int16');
        info.NumImages = fread(fid, 1, 'int16');
        info.ramp1Min = fread(fid, 1, 'int16');
        info.ramp1Max = fread(fid, 1, 'int16');
        info.notes = fread(fid, 1, 'int32');
        info.byteFormat = fread(fid, 1, 'int16');
        info.n = fread(fid, 1, 'int16');
        
        fread(fid, 32, 'char');
        
        info.merged = fread(fid, 1, 'int16');
        if info.merged
            info.infoBytes = -1;
            return
        end
        
        info.color1 = fread(fid, 1, 'int16');
        info.fileID = fread(fid, 1, 'int16');
        if info.fileID ~= 12345
            info.infoBytes = -1;
            return
        end
        
        info.ramp2Min = fread(fid, 1, 'int16');
        info.ramp2Max = fread(fid, 1, 'int16');
        info.color2 = fread(fid, 1, 'int16');
        info.edited = fread(fid, 1, 'int16');
        info.lens = fread(fid, 1, 'int16');
        info.magFactor = fread(fid, 1, 'float32');
        info.dummy = fread(fid, 3, 'int16');
        
        % read data
        if info.byteFormat == 1
            % 8 bit
            for x = 1:info.NumImages
                data(:,:,x) = fliplr(double(fread(fid, [info.Width, info.Height], 'uchar')) / 255);
            end
            info.BitDepth = 8;            
        else
            try
                data = zeros(info.Height, info.Width, info.NumImages, 'uint16');
            catch
                evalin('base', 'clear zImage ans');
                data = zeros(info.Height, info.Width, info.NumImages, 'uint16');
            end
            % 16 bit
            for x = 1:info.NumImages
                data(:,:,x) = fliplr(fread(fid, [info.Width, info.Height], 'uint16'));
            end            
            if exist([filename(1:find(filename == filesep, 1, 'last')) 'TimeStamps.csv'], 'file')
                [A B C] = textread([filename(1:find(filename == filesep, 1, 'last')) 'TimeStamps.csv'], '%f, %f, %f', 'headerlines', 2);
                handle = findobj('tag', 'txtFrameDuration');
                if ~isempty(handle)
                    set(handle, 'string', sprintf('%1.0f', mean(C)*1000));
                end
            end
            info.BitDepth = 16;            
        end
        
        % read notes
        info.notesOffset = ftell(fid);
        getAxisInfo;
        fclose(fid);
    else
        info.infoBytes = -1; %tell calling subroutine that the file was zero length
    end
else
    info.infoBytes = -1; %tell calling subroutine that no file was found
end

if nargin == 2
    data = info;
end
        
    function getAxisInfo
        % read all of the notes
        fseek(fid, info.notesOffset, 'bof');
        noteIndex = 1;
        
        while info.notesOffset + NOTE_LEN * (noteIndex - 1) <= info.endOfFile
            info.note{noteIndex} = readNote(noteIndex);
            
            if info.note{noteIndex}.type == NOTE_TYPE_VARIABLE
                if length(info.note{noteIndex}.text) > 5 && strcmp(info.note{noteIndex}.text(1:6), 'AXIS_2')
                    axisNum = 0; % horizontal axis
                    tempData = sscanf(info.note{noteIndex}.text(7:end), ' %d %g %g %s');
                    axisType = tempData(1);
                    info.origin(axisNum + 1) = tempData(2);
                    info.delta(axisNum + 1) = tempData(3);
                    info.units{axisNum + 1} = char(tempData(4:end)');
                    if axisType ~= AXT_D
                        info.infoBytes = -1;
%                         return
                    end
                elseif length(info.note{noteIndex}.text) > 5 && strcmp(info.note{noteIndex}.text(1:6), 'AXIS_3')
                    axisNum = 1; % vertical axis
                    tempData = sscanf(info.note{noteIndex}.text(7:end), ' %d %g %g %s');
                    axisType = tempData(1);
                    info.origin(axisNum + 1) = tempData(2);
                    info.delta(axisNum + 1) = tempData(3);
                    info.units{axisNum + 1} = char(tempData(4:end)');
                    if axisType ~= AXT_D
                        info.infoBytes = -1;
%                         return
                    end
                elseif length(info.note{noteIndex}.text) > 5 && strcmp(info.note{noteIndex}.text(1:6), 'AXIS_4')
                    axisNum = 2; % z axis
                    axisType = sscanf(info.note{noteIndex}.text(7:end), ' %d');
                    if axisType == AXT_D
                        tempData = sscanf(info.note{noteIndex}.text(7:end), ' %d %g %g %s');
                        info.origin(axisNum + 1) = tempData(2);
                        info.delta(axisNum + 1) = tempData(3);
                        info.units{axisNum + 1} = char(tempData(4:end)');
                    else
                        info.infoBytes = -1;
%                         return
                    end
                elseif length(info.note{noteIndex}.text) > 5 && strcmp(info.note{noteIndex}.text(1:6), 'AXIS_9')
                    tempData = sscanf(info.note{noteIndex}.text(7:end), ' %d %g %g %s');
                    axisType = tempData(1);
                    info.origin(axisNum + 1) = tempData(2);
                    info.delta(axisNum + 1) = tempData(3);
                    info.units{axisNum + 1} = char(tempData(4:end)');
                    if axisType ~= AXT_RGB
                        info.origin(3) = [];
                        info.delta(3) = [];
                        info.units(3) = [];
                    end
                elseif length(info.note{noteIndex}.text) > 13 && strcmp(info.note{noteIndex}.text(1:6), 'INFO_FRAME_RATE')
                    info.framesPerSecond = sscanf(info.note{noteIndex}.text(14:end), ' %d');
                elseif length(info.note{noteIndex}.text) > 22 && strcmp(info.note{noteIndex}.text(1:22), 'INFO_OBJECTIVE_NAME = ')
                    info.Objective = info.note{noteIndex}.text(23:end);
                    info.Objective = info.Objective(info.Objective ~= char(0));
                else
%                     disp(info.note{noteIndex}.text)
                end
            else
%                 disp(length(info.note{noteIndex}.text))
            end

            noteIndex = noteIndex + 1;
        end
    end

    function note = readNote(index)
        fseek(fid, info.notesOffset + (index - 1) * NOTE_LEN, 'bof');
        note.level = fread(fid, 1, 'int16');
        note.next = fread(fid, 1, 'int32');
        note.num = fread(fid, 1, 'int16');
        note.status = fread(fid, 1, 'int16');
        note.type = fread(fid, 1, 'int16');
        note.x = fread(fid, 1, 'int16');
        note.y = fread(fid, 1, 'int16');
        note.text = char(fread(fid, 80, 'char')');
%         note.text
    end
end