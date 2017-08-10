function retCode = scopeHighlightTrace(oldVector, traceKey, startTimeMs, stopTimeMs)
  % This function from 2 March 2012
   msPerPoint = evalin('base', 'zData.protocol.msPerPoint');   
   pointsPerMs = 1 / msPerPoint;
   newVector = oldVector;
   startIndex = (startTimeMs * pointsPerMs) - 1;
   if startIndex < 1
     startIndex = 1;
   end
   newVector(1:startIndex) = nan;
   newVector(stopTimeMs * pointsPerMs):end) = nan;
   WriteBinaryVector(newVector);
   retCode = system(['d:\SendMessageToSynapse.exe Highlight ' traceKey]);
   if retCode ~= 0 
      msgbox 'Check existance of D:\SendMessageToSynapse.exe'
  end
end