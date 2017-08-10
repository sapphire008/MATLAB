function [zReal zImag] = fourier(yData, fs, frequencies)

zReal = nan(size(frequencies));
zImag = zReal;
xData = (1:length(yData))/fs;

for i = 1:numel(frequencies)
    sinComp = 2*sum(((yData-mean(yData)).*-sin(2*pi*frequencies(i)*xData)).^2)/length(xData);
    cosComp = 2*sum(((yData-mean(yData)).*cos(2*pi*frequencies(i)*xData)).^2)/length(xData);
    zReal(i) = sqrt(sinComp^2+cosComp^2);
    zImag(i) = unwrap(atan2(sinComp, cosComp)) - pi/2;
end