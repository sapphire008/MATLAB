function traceOut = traceWindow(traceIn, startMs, stopMs)
% last revised 17 April 2012 BWS

 zData = evalin('base', 'zData');
 pointsPerMs = 1/zData.protocol.msPerPoint;
 traceOut = traceIn(startMs * pointsPerMs:((stopMs * pointsPerMs) -1 ));
end
