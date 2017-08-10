function retArray = getCurTraceName
  % returns first Volt traceName in current zData in base workspace
  retArray = nan;
  zData = evalin('base', 'zData');
  for i = 1:zData.protocol.numTraces
      tempName = zData.protocol.traceNames{i};
      if numel(tempName) > 3 
        if strcmp('Cur', tempName(1:4)) == 1 
          break;  
        end
      end
  end
  retArray = tempName;
end