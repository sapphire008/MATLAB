function outData= blankAPsWithConstant (inData, thresh) 

if nargin < 2
    thresh = 10; % good
end

spikeTimes = find(diff(inData) > thresh);
outData = inData;
for i = spikeTimes'
    outData(i + (-3:7)) = mean(outData(i + (-5:-3)));
end