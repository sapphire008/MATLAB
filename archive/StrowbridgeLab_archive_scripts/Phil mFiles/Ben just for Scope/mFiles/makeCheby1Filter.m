function retValue = makeCheby1Filter(samplingFreq, order, PassBandRipple, cutOffFreq, typeCode)
if typeCode == 0 
    [newFilt.b newFilt.a]=cheby1(order, PassBandRipple, 2*pi*cutOffFreq,'low','s');
else
    [newFilt.b newFilt.a]=cheby1(order, PassBandRipple, 2*pi*cutOffFreq,'high','s');
end
[newFilt.b newFilt.a]=bilinear(newFilt.b, newFilt.a, samplingFreq);
assignin('base','FilterParms',newFilt);
retValue=1;
end