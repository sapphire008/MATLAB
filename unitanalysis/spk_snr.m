function SNR = spk_snr(Vs, method)
% Quantify signal to noise ratio
if nargin<2 || isempty(method), method = 'mean2std'; end
switch method
    case 'mean2std'
        SNR = mean(Vs) / std(Vs);
    case 'rms'
        rms = @(x) sqrt(mean(x.^2));
        SNR = (max(Vs) - min(Vs)) / rms(Vs);
end
end