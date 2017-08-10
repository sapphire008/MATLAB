function retArray = getStim
  % returns first Volt trace in current zData in base workspace
  retArray = nan;
  zData = evalin('base', 'zData');
  for i = 1:zData.protocol.numTraces
      tempName = zData.protocol.traceNames{i};
      if numel(tempName) > 8 
        if strcmp('Stimulus', tempName(1:8)) == 1 
          break;  
        end
      end
  end
  retArray = evalin('base', ['zData.' tempName]);
end