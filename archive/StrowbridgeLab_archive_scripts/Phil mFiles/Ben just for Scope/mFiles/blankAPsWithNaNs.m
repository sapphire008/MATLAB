function outData= blankAPsWithNaNs (inData, thresh) 

spikeTimes = find(diff(inData) > thresh);
outData = inData;
for i = spikeTimes'
    outData(i + (-3:7)) = nan;
end