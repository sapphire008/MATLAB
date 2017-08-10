function retValue = makeButterFilter(samplingFreq, order, cutOffFreq, typeCode)
if typeCode == 0 
  [newFilt.b newFilt.a]=butter(order, 2*pi*cutOffFreq,'low','s');
else
    [newFilt.b newFilt.a]=butter(order, 2*pi*cutOffFreq,'high','s');
end
[newFilt.b newFilt.a]=bilinear(newFilt.b, newFilt.a, samplingFreq);
assignin('base','FilterParms',newFilt);
retValue=1;
end