function Y = showFFT(dataIn, samplingRate,figureName)
% displays power spectrum of data
% coefficients = showFFT(data, samplingFreq in Hz);
% defaults:
%   samplingFreq = 5000 Hz

  whichFigure = strcmp(get(get(0, 'children'), 'name'), figureName);
        if ~any(whichFigure)
            sfigure('numbertitle', 'off', 'name', figureName);
          
        else
            figures = get(0, 'children');
            sfigure(figures(whichFigure));
          
        end

resolution = length(dataIn);

Y = fft(dataIn, resolution);

Pyy = Y.* conj(Y) / resolution;

f = samplingRate * (1:round(resolution / 2)) / resolution;
plot(f, Pyy(2:int32(resolution / 2 + 1)))
title('Frequency content of y')
xlabel('frequency (Hz)')
set(gca, 'Xlim', [1 samplingRate / 2]);
%set(gca, 'Ylim', [0 1]);