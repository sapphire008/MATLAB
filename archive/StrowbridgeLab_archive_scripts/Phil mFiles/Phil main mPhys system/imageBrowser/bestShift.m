function lagValue = bestShift(zImage)

if nargin < 1
    zImage = evalin('base', 'zImage');
end

zImage.stack = double(zImage.stack - mean(mean(zImage.stack)));

savedCorr = nan(size(zImage.stack, 1) / 2, 1);
for i = 1:size(zImage.stack, 1) / 2
    % only compare the parts of the image that are shared
    savedCorr(i) = max([mean(mean((zImage.stack(1:end - i, 1:2:end) .* zImage.stack(i + 1:end, 2:2:end)).^2))...
        mean(mean((zImage.stack(i + 1:end, 1:2:end) .* zImage.stack(1:end - i, 2:2:end)).^2))]);
end

[lagValue lagValue] = max(savedCorr);
lagValue = lagValue / 2;

if ~nargout
    figure, plot((1:length(savedCorr)) ./ 2, savedCorr)
    line(lagValue, savedCorr(lagValue * 2), 'marker', '*', 'markerEdge', 'r');
    title(['Maximum similarity at a shift of ' num2str(round(lagValue)) ' pixels for even rows']);        
    xlabel('Shift (pixels)');
    ylabel('Correlation');
end

lagValue = round(lagValue);