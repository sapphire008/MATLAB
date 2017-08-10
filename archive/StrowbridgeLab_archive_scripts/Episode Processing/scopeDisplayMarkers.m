function retCode = scopeDisplayMarkers(traceKey, times, markerBottom, markerTop, markerColor)
  % this function from 2 March 2012 BWS
  mTimes = timesToMarkers(times, markerBottom, markerTop);
  WriteBinaryVector(mTimes);
  retCode = system(['d:\LabWorld\MessagePassing\SendMessageToSynapse.exe Markers ' traceKey ' ' markerColor]);
  if retCode ~= 0 
      msgbox 'Check existance of D:\LabWorld\MessagePassing\SendMessageToSynapse.exe'
  end
end