function retCode = scopeReplaceTrace(newVector, traceKey)
  % This function from 2 March 2012
   WriteBinaryVector(newVector);
   retCode = system(['d:\SendMessageToSynapse.exe Replace ' traceKey]);
   if retCode ~= 0 
      msgbox 'Check existance of D:\SendMessageToSynapse.exe'
  end
end