function outData = runGeneralFilter(inData)
newFilt=evalin('base','FilterParms');
outData = filter(newFilt.b,newFilt.a,inData);
end