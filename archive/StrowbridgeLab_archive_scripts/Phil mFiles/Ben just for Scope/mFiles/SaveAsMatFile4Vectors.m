function retValue = SaveAsMatFile4Vectors(inArray, inArray2, inArray3,inArray4, newFileName)
c={inArray,inArray2, inArray3, inArray4};
save(newFileName , 'c');
retValue=1;
