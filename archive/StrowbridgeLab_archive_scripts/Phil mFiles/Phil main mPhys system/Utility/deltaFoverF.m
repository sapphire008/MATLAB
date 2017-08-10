function outData = deltaFoverF(inData, filterLength, baselineDataEnd)
% pass baselineDataEnd as nan to avoid bleach subtraction
% returns deltaF / F data assuming that the first half of the data is
% baseline

if nargin < 2
    if length(inData) > 2000
        filterLength = 100;
    else
        filterLength = 50;
    end
end

if nargin < 3
    baselineDataEnd = fix(0.1 * length(inData));
end

if any(isnan(inData))
    nanPadded = [find(~isnan(inData), 1, 'first') - 1 length(inData) - find(~isnan(inData), 1, 'last')];
    inData = inData(~isnan(inData));
else
    nanPadded = 0;
end

% subtract the linear bleaching
% linearApproximation = polyfit((1:baselineDataEnd)', inData(1:baselineDataEnd), 1);
% inData = inData - polyval([linearApproximation(1) 0], 1:length(inData))';

% subtract for exponential bleaching
% if ~isnan(baselineDataEnd)
%     [decayTau1 FittedCurve estimates] = fitDecaySingle(inData(1:baselineDataEnd), 1);
%     inData = inData - (estimates(1) + estimates(2) .* exp((1:numel(inData))./estimates(3)))';
% end

% generate the output data
outData = movingAverage(inData - mean(inData(1:baselineDataEnd)), filterLength) ./ abs(mean(inData(1:baselineDataEnd)));

if any(nanPadded)
    outData = [nan(nanPadded(1), 1); outData; nan(nanPadded(2), 1)];
    outData(1:20) = nan;
end

if ~nargout
    figure('numberTitle', 'off')
    subplot(2, 1, 1);
    plot(inData);
    title('Bleach-Subtracted');
    subplot(2, 1, 2);
    plot(outData);
    title('\Delta F / F');
end