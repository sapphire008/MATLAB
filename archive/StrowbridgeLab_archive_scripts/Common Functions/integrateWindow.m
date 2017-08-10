function intOut = integrateWindow(traceIn, startMs, stopMs)
% last revised 17 April 2012 BWS

 zData = evalin('base', 'zData');
 secPerPoint = zData.protocol.msPerPoint / 1000;
 intOut = 0;
 factor = .0000266;
 winTrace = traceWindow(traceIn, startMs, stopMs);
 for i = 1:numel(winTrace)
    intOut = intOut + (factor * (winTrace(i) * secPerPoint));
 end
end
