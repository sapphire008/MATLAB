function addMarkersToTrace(traceName, eventTimesMs, lowerB, upperB, colorString)
  % last revised 16 April 2012
  % use traceName like VoltA or CurB
  mTimes = timesToMarkers(eventTimesMs, lowerB, upperB);
  WriteBinaryVector(mTimes);
  s = system(['d:\LabWorld\MessagePassing\SendMessageToSynapse.exe Markers ' traceName colorString]);
end