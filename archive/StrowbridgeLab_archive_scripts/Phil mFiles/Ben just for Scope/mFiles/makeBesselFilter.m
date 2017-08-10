function retValue = makeBesselFilter(samplingFreq, order, cutOffFreq)
[newFilt.b newFilt.a]=besself(order, 2*pi*cutOffFreq);
[newFilt.b newFilt.a]=bilinear(newFilt.b, newFilt.a, samplingFreq);
assignin('base','FilterParms',newFilt);
retValue=1;
end