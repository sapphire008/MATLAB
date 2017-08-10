function corrVal = signalCorrelation(sigA, sigB, timeVector)
% sigA = highPass(sigA, [0.5 1.5]);
% sigB = highPass(sigB, [0.5 1.5]);
sigA = sigA - mean(sigA);
sigB = sigB - mean(sigB);

corrVal = nan(size(timeVector));
denom = sqrt(sum(sigA.^2)*sum(sigB.^2));
for i = 1:numel(timeVector)
    corrVal(i) = (sigA' * circshift(sigB, timeVector(i))) / denom;
end

if ~nargout
    figure('name', 'Crosscorrelation', 'numbertitle', 'off');
    plot(timeVector, corrVal, 'linestyle', 'none', 'marker', '+');
    xlabel('Time (data points)');
    ylabel('Correlation (normalized)');
end