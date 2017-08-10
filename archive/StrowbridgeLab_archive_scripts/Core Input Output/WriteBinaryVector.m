function WriteBinaryVector(inVec) 
  fileName = 'r:\tempVector.dat';
  fid = fopen(fileName,'w');
  fwrite(fid, inVec, 'float64');
  fclose(fid);
end