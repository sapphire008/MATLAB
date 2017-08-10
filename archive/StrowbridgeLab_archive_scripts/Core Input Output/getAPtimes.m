function outTimes = getAPtimes (inTrace, APthreshMillivolts)
  % returns times of all APs in ms with optional threshold in mV
  if nargin < 2, APthreshMillivolts = -20; end
  msPerPoint = evalin('base', 'zData.protocol.msPerPoint');    
  outTimes = [];
  i = 1;
  while i <= numel(inTrace)
     if inTrace(i) >= APthreshMillivolts
        outTimes = [outTimes ((i - 1) * msPerPoint)]; 
        i = i + (4 * (1  / msPerPoint));
     else
        i = i + 1;
     end
  end
end