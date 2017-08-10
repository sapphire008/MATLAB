function outData = fieldFilter(inData, protocol)
% remove the slow drift

% uncomment the next line to see the polynomial fit
% line(.2:.2:2500, polyval(polyfit((1:length(inData))', inData, 5), (1:length(inData))'), 'linewidth', 10); outData = inData; return
outData = inData - polyval(polyfit((1:length(inData))', inData, 5), (1:length(inData))');

outData = combFilter(outData, [59.9957 120.0852 264.1 300.1717 2103.9098 2367.9676 59.7103], 1e6 ./ protocol.timePerPoint);

function outData = combFilter(inData, selectedFrequencies, samplingFreq, whichPart)
% remove sinusoidal noise at selectedFrequencies by finding the phase and
% amplitude of the signal at those frequencies and subtracting a
% complementary sine wave
%
% outData = combFilter(inData, selectedFrequencies, samplingFreq, whichPart)
if nargin < 4
    whichPart = (1000:12500)'; % the samples of inData to fit the sines to
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