function outData = variance(inData)
% actually calculates the variance-to-mean ratio
% varianceData = variance(rawData)

outData = (inData - polyval(polyfit((1:length(inData))', inData, 1), (1:length(inData))')).^2;
% outData = (inData - mean(inData)) .^ 2 ./ abs(mean(inData));