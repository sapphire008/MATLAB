function retValue = makeEllipFilter(samplingFreq, order, PassBandRipple, StopBandAttenuation, cutOffFreq, typeCode)
if typeCode == 0
    [newFilt.b newFilt.a]=ellip(order, PassBandRipple, StopBandAttenuation, 2*pi*cutOffFreq,'low','s');
else
    [newFilt.b newFilt.a]=ellip(order, PassBandRipple, StopBandAttenuation, 2*pi*cutOffFreq,'high','s');
end
[newFilt.b newFilt.a]=bilinear(newFilt.b, newFilt.a, samplingFreq);
assignin('base','FilterParms',newFilt);
retValue=1;
end