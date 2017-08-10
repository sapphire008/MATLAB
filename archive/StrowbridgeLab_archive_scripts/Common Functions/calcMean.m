function meanValue = calcMean(inData)
% find the greatest value of the all points histogram
% meanValue = calcMean(inData);

[n xout] = hist(inData, 1000);
[count index] = max(n);
meanValue = xout(index);

if nargout == 0
   figure('name', 'How good is the fit', 'numbertitle', 'off');
   plot(inData);
   line([1 length(inData)], [meanValue meanValue], 'color', [0 0 0]);
end