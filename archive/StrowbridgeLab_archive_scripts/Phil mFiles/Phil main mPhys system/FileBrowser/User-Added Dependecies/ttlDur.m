function outData = ttlDur(protocol, ttlNum)
if protocol.ttlEnable{ttlNum + 1}
    outData = protocol.ttlTrainInterval{ttlNum + 1};
else
    outData = 0;
end