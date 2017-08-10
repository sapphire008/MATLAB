function outIntegral = polyIntegral(data, protocol)

stimTimes = findStims(protocol);
whichStim = find(~cellfun('isempty', stimTimes), 1);

% answer is in mV*s
try
    outIntegral = sum(data(stimTimes{whichStim}(end,1) + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint)) - calcMean(data(stimTimes{whichStim}(1,1) + (-1000000/ protocol.timePerPoint:0)))) * (protocol.timePerPoint / 1000) / 1000;
catch
    outIntegral = sum(data(stimTimes{whichStim}(end,1) + (500000 / protocol.timePerPoint:4500000 / protocol.timePerPoint)) - calcMean(data(1:stimTimes{whichStim}(1,1)))) * (protocol.timePerPoint / 1000) / (stimTimes{whichStim}(1,1) * (protocol.timePerPoint / 1000));
end
clipboard('copy', outIntegral);