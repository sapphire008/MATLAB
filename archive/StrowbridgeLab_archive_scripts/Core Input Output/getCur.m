function retArray = getCur
  % returns first Volt trace in current zData in base workspace
  retArray = nan;
  zData = evalin('base', 'zData');
  for i = 1:zData.protocol.numTraces
      tempName = zData.protocol.traceNames{i};
      if numel(tempName) > 3 
        if strcmp('Cur', tempName(1:3)) == 1 
          break;  
        end
      end
  end
  retArray = evalin('base', ['zData.' tempName]);
end