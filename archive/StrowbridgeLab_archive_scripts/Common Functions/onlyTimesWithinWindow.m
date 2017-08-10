function outTimes = onlyTimesWithinWindow (inTimes, startTimeMs, stopTimeMs)
  % returns subset of input times in ms that are within bounds
  outTimes = inTimes(inTimes >= startTimeMs);
  outTimes = outTimes(outTimes < stopTimeMs);
end