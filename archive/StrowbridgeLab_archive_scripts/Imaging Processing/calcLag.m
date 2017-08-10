function lagOut = calcLag(positionIn, preMoviePoints, xPixels)
  % revised 25 May 2012
  realPos = positionIn;
  realPos(1:(3*preMoviePoints)) = nan;
  totalExpectedPoints = preMoviePoints + (10 * xPixels);
  realPos(totalExpectedPoints:end) = nan;
  center = (max(realPos) + min(realPos)) / 2;
  thresh = 2;
  mainVector = 1:numel(realPos);
  centerIndexes = mainVector((abs(realPos - center)) < thresh);
  lagOut = centerIndexes;
end