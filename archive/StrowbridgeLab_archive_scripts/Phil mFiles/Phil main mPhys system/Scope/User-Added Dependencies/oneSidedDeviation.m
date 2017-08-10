function outData = oneSidedDeviation(inData)
% use an outlier-insensitive deviation measure that assumes a mean of zero
% outValue = oneSidedDeviation(inData);

% make the data into a one-sided distribution that would have been centered
% about 0
deviation = sort(abs(inData - mean(inData(~isnan(inData)))));

if nargout == 0
    figure, hist(deviation, length(inData) / 100);
end

% find the value of the standard deviation
deviation = deviation(round(length(inData) * .6826894921371));

% we want an upper limit that gives us a 50% chance of having a single
% point above it if this distribution were normal
if license('test','Statistics_Toolbox')
    outData = sum(abs(norminv([.5  1 - 1 / length(inData)], 0, deviation)));    
else
    outData = nan;
end

if nargout == 0
    line([deviation deviation], get(gca, 'ylim'), 'color', 'r');
    line([outData outData], get(gca, 'ylim'), 'color', 'g');
    legend({'Data', 'Standard deviation', 'Upper Bound'});
end