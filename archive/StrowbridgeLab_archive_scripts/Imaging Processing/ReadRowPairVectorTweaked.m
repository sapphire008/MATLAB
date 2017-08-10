function outVec = ReadRowPairVectorTweaked
  % revised 25 May 2012
  fileName = 'r:\RowPairVectorTweaked.dat';
  fileInfo = dir(fileName);
  vectorSize = fileInfo.bytes/8;
  fid = fopen(fileName,'r');
  outVec = fread(fid,vectorSize,'float64');
  fclose(fid);
end