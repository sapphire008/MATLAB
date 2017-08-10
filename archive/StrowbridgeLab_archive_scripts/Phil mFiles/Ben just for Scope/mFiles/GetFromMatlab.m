function retValue = GetFromMatlab(oldVarName)
retValue=evalin('base',oldVarName);
end
