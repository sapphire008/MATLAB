function outData = MTEO(inData, kData, threshold, windows)
% after Choi and Kim, Electronics Letters, 38(12) 2002, 541-3 and
% Choi, Jung, and Kim, IEEE Transactions on Biomedical Engineering, 53(4), 2006, 738-746
%
% spikeLocations = MTEO(rawData, k-teo values, threshold, windows);
% filteredData = MTEO(rawData, k-teo values);
% for multiple windows (as rows) the output data is a column vector of
%    number of spikes in each window
% defaults:
%    k-teo values = 14;
%    threshold = 0: 3 * gaussian estimate of noise maximum
%    threshold < 0: threshold * gaussian estimate of noise maximum
%    threshold > 0: threshold
%    windows is [1 length(rawData)];

if nargin < 2
    kData = 14;
end

if size(inData, 1) > size(inData, 2)
    inData = inData';
end

% make it zero mean
inData = inData - mean(inData(10:1000));

% set aside space for results
outData = zeros(size(inData, 2), length(kData));
for kIndex = 1:length(kData)
    % k-teo
    outData(:, kIndex) = inData.^2 - circshift(inData, [0, -kData(kIndex)]) .* circshift(inData, [0, kData(kIndex)]);
    
    % smoothing window
    outData(:, kIndex) = circshift(filter(hamming(4 * kData(kIndex) + 1), 1, outData(:, kIndex)), [-3 * kData(kIndex) 1]);
    
    % normalizing the output noise power
%     outData(:, kIndex) = outData(:, kIndex) / sqrt(3 * sum(outData(:, kIndex).^2) + sum(outData(:, kIndex)).^2);
end

% maximum filter
outData = max(outData, [], 2);

% thresholding if requested
if nargin > 2
    if threshold == 0
        threshold = mean(outData(~isnan(outData(1:round(end * .2))))) + oneSidedDeviation(outData(1:round(end * .2))) * 3;
    elseif threshold < 0
        threshold = mean(outData(~isnan(outData(1:round(end * .2))))) + oneSidedDeviation(outData(1:round(end * .2))) * -threshold;
    end

    dataDerivative = diff(outData);
    spikes = find(outData(2:length(outData)-1) > threshold & (dataDerivative(2:size(dataDerivative, 1)) ./ dataDerivative(1:size(dataDerivative, 1) -1) < 0 | dataDerivative(2:size(dataDerivative, 1)) == 0) & dataDerivative(1:size(dataDerivative, 1) - 1) > 0) + 1;
    % remove any that are too close together
    if ~isempty(spikes)
        spikes = spikes([diff(spikes) > 10; 1] & [1; diff(spikes) > 10]);
    end
	
    outData = spikes;
%     return
    
    if nargin < 4
%         tempOut = zeros(size(outData));
%         tempOut(spikes) = outData(spikes);
%         outData = tempOut;
    else
        outData = [];
        for i = 1:size(windows, 1)
            outData(end + 1) = sum(spikes >= windows(i,1) & spikes <= windows(i,2));
        end
    end
end

%text('interpreter', 'latex', 'string', '$$\mu V^2\over mSec^2$$', 'position', [.1 .5])