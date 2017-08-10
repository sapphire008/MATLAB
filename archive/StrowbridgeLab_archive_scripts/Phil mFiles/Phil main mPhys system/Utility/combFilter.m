function outData = combFilter(inData, selectedFrequencies, samplingFreq, whichPart)
% remove sinusoidal noise at selectedFrequencies by finding the phase and
% amplitude of the signal at those frequencies and subtracting a
% complementary sine wave
%
% outData = combFilter(inData, selectedFrequencies, samplingFreq, whichPart)
if nargin < 4
%     whichPart = (1:250)'; % the samples of inData to fit the sines to
% it seemed to work best originally to fit to a part of the data without
% other things going on (since the frequency is fixed so all we need to
% determine is the phase), but the more points the better the estimate, so
% I changed it to look at the whole trace
    whichPart = (1:length(inData))'; % the samples of inData to fit the sines to    
end

if numel(inData) < numel(whichPart)
    whichPart = 1:numel(inData);
end

outData = inData;
for i = 1:numel(selectedFrequencies)
    sineData = 2 * mean(-sin(2 * pi * selectedFrequencies(i) / samplingFreq * whichPart) .* (outData(whichPart) - mean(outData(whichPart))));
    cosineData = 2 * mean(cos(2 * pi * selectedFrequencies(i) / samplingFreq * whichPart) .* (outData(whichPart) - mean(outData(whichPart))));
    outData = outData - sqrt(sineData.*sineData + cosineData.*cosineData) * cos(atan2(sineData, cosineData) + 2*pi*selectedFrequencies(i) / samplingFreq * (1:length(outData))');
end