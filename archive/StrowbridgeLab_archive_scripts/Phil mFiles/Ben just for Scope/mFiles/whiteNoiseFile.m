function whiteNoiseFile(samplingRate, duration, peakToPeak, cutoff, fileName)
% whiteNoiseFile(5000, 10, 1500, [100 1000], 'R:\whiteNoise.txt');
% sampling rate in Hz
% duration in seconds
% peakToPeak in pA before low pass filtering
% cutoff is two element cutoff [passStart blockStart] 

fid = fopen(fileName, 'w');
    fprintf(fid, '%g\n', lowPass(rand(samplingRate * duration,1).*peakToPeak-peakToPeak./2, cutoff));
fclose(fid);