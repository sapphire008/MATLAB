function outData = deltaF(inData, baselineDataEnd)

% returns delta data assuming that the first half of the data is
% baseline

if nargin < 2
    baselineDataEnd = fix(0.5 * length(inData));
end

% subtract the linear bleaching
linearApproximation = polyfit(1:baselineDataEnd, inData(1:baselineDataEnd), 1);
inData = inData - polyval(linearApproximation, 1:length(inData));

% generate the output data
outData = diff(inData);
outData = [outData(1) outData];

if ~nargout
    figure('numberTitle', 'off')
    subplot(2, 1, 1);
    plot(inData);
    title('Bleach-Subtracted');
    subplot(2, 1, 2);
    plot(outData);
    title('\Delta F');
end