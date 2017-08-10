function markerVector = timesToMarkers (inTimes, bottomValue, topValue)
  % this returns triplets of timeInMs/bottom value/top values for markers
  markerVector = [inTimes inTimes inTimes];
  count = 1;
  for i = 1:3:numel(markerVector)
     markerVector(i) = inTimes(count);
     markerVector(i + 1) = bottomValue;
     markerVector(i + 2) = topValue;
     count = count + 1;
  end
end