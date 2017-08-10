function riseStart = analysisFun(data)
% sampled at 10 kHz
% starts at 900 ms

startPoint = find(data(1:1100) < mean(data(100:1000)), 1, 'last');
stopPoint =  find(data > mean(data(1100:1500)), 1, 'first');

coefficients = polyfit(startPoint:stopPoint, data(startPoint:stopPoint)', 1);
riseStart = (mean(data(100:1000)) - coefficients(2)) / coefficients(1)/10+900;

if ~nargout
    line([910 1000], mean(data(100:1000)) + [0 0]);
    line([1010 1050], mean(data(1100:1500)) + [0 0]);
    line([(mean(data(100:1000)) - coefficients(2)) / coefficients(1) (mean(data(1100:1500)) - coefficients(2)) / coefficients(1)] ./ 10 + 900, polyval(coefficients, [(mean(data(100:1000)) - coefficients(2)) / coefficients(1) (mean(data(1100:1500)) - coefficients(2)) / coefficients(1)]));
    line((mean(data(100:1000)) - coefficients(2)) / coefficients(1)/10+900, mean(data(100:1000)), 'linewidth', 10, 'marker', '+', 'markerSize', 40, 'markerEdgeColor', 'r');
end