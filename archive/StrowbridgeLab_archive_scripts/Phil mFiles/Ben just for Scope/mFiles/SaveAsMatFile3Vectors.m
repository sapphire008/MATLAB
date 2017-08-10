function retValue = SaveAsMatFile3Vectors(inArray, inArray2, inArray3, newFileName)
c={inArray,inArray2, inArray3};
save(newFileName , 'c');
retValue=1;
