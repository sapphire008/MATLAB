function outData = besselFilter(inData, samplingFreq, order, cutOff)
s = evalin('base', 'whos');

whichFilter = find(strcmp({s.name}, ['besselFilter_' num2str(order) '_' num2str(cutOff)]));

if isempty(whichFilter)
    [newFilt.b newFilt.a] = besself(order, 2*pi*cutOff);
    [newFilt.b newFilt.a] = bilinear(newFilt.b, newFilt.a, samplingFreq);
    assignin('base', ['besselFilter_' num2str(order) '_' num2str(cutOff)], newFilt);
else
    newFilt = evalin('base', ['besselFilter_' num2str(order) '_' num2str(cutOff)]);
end

outData = filter(newFilt.b,newFilt.a,inData);