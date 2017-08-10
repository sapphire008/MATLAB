function retValue = SaveAsMatFile2Vectors(inArray, inArray2, newFileName)
c={inArray,inArray2};
save(newFileName , 'c');
retValue=1;
