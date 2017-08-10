function retCode = scopePlotFunction(xyPairData, traceKey, traceColor)
  % This function from 2 March 2012
  WriteBinaryVector(xyPairData);
  retCode = system(['d:\SendMessageToSynapse.exe FunctionPlot ' traceKey ' ' traceColor]);
  if retCode ~= 0 
      msgbox 'Check existance of D:\SendMessageToSynapse.exe'
  end
end