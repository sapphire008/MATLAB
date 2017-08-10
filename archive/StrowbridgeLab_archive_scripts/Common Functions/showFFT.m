function Y = showFFT(dataIn, samplingRate)
% displays power spectrum of data
% coefficients = showFFT(data, samplingFreq in Hz);
% defaults:
%   samplingFreq = 5000 Hz

if nargin < 2
    samplingRate = 5000; % Hz
end

if length(dataIn) > samplingRate
    answer = questdlg('The data vector is long, so this may take awhile', 'Uh oh', 'Do it anyway', 'Use first second', 'Cancel', 'Use first second');
    switch answer
        case 'Use first second'
            dataIn = dataIn(1:samplingRate);
        case 'Do it anyway'
            
        otherwise
            Y = [];
            return
    end
end

resolution = length(dataIn);

figure
Y = fft(dataIn, resolution);

Pyy = Y.* conj(Y) / resolution;

f = samplingRate * (1:round(resolution / 2)) / resolution;
plot(f, Pyy(2:int32(resolution / 2 + 1)))
title('Frequency content of y')
xlabel('frequency (Hz)')
set(gca, 'Xlim', [1 samplingRate / 2]);
%set(gca, 'Ylim', [0 1]);