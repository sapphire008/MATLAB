function meanVals(data, protocol)

whatVals = nan(5,1);
startTime = 9;

for i = 1:5
    whatVals(i) = mean(data((startTime + i) * 1000000 / protocol.timePerPoint:(startTime + i + 1) * 1000000 / protocol.timePerPoint)) - mean(data(1:(startTime + 1) * 1000000 / protocol.timePerPoint));
end
clipboard('copy', [protocol.fileName(find(protocol.fileName == filesep, 1, 'last') + 1:end) char(9) sprintf('%g\t', whatVals')]);