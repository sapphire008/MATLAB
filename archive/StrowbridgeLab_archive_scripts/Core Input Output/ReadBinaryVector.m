function outVec = ReadBinaryVector(fileName)
  % revised 17 May 2012
  if nargin == 0 
       fileName = 'r:\tempVector.dat';
  end
  fileInfo = dir(fileName);
  vectorSize = fileInfo.bytes/8;
  fid = fopen(fileName,'r');
  outVec = fread(fid,vectorSize,'float64');
  fclose(fid);
end