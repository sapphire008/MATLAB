function retValue = SaveAsMatFile3VectorsUnique(inArray, inArray2, inArray3, newFileName, newVarName)
UniqueVarName=genvarname(newVarName);
eval([UniqueVarName ' = {inArray,inArray2, inArray3, newFileName};']);
save(newFileName , UniqueVarName);
retValue=1;