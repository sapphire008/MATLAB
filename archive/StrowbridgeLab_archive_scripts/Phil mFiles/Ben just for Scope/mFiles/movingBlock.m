function inData = movingBlock(inData, windowSize)
% use a boxcar filter of length windowSize points on inData
% filteredData = movingAverage(rawData, windowSize);
% defaults:
%   windowSize = 10 points

if nargin < 2
    windowSize = 10;
end

for i = 0:windowSize:length(inData) - windowSize
    inData(i + (1:windowSize)) = mean(inData(i + (1:windowSize)));
end
inData(i + windowSize + 1:end) = mean(inData(i + windowSize + 1:end));