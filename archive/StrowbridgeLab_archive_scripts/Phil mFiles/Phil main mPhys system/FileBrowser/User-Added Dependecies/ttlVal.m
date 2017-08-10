function outData = ttlVal(protocol, ttlNum)
if protocol.ttlEnable{ttlNum + 1}
    outData = protocol.ttlIntensity{ttlNum + 1};
else
    outData = 0;
end