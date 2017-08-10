function retArray = getTraceByKey(keyStr)
  % returns first Volt trace in current zData in base workspace
  retArray = nan;
  okay = 0;
  zData = evalin('base', 'zData');
  for i = 1:zData.protocol.numTraces
      tempName = zData.protocol.traceNames{i};
      if strcmp(keyStr, tempName) == 1
          okay = 1;
         break; 
      end
  end
  if okay == 1 
    retArray = evalin('base', ['zData.' tempName]);
  end
end