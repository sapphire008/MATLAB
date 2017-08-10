function stringOut = readVBString(fid)
% this function takes a handle to an open file and reads a VB encoded
% string.  It assumes the file position is correct
stringLength = fread(fid, 1, 'int16');
if stringLength==0
    stringOut='';
else
    stringOut =(fread(fid, stringLength, '*char'))'; % last prime is to transpose string 
end
