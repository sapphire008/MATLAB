function outData = ampStep(protocol, ampNum)

if protocol.ampStep1Enable{1} && protocol.ampStepEnable{1} && protocol.ampStimEnable{1}
    outData = protocol.ampStep1Amplitude{ampNum};
else 
    outData = 0;
end