function outData = pspSlope(protocol)

zData = readTrace(protocol.fileName);

if size(zData.traceData, 1) > 50000
    baseline = mean(zData.traceData(49000:50000, whichChannel(protocol, 1, 'V')));
    if any(zData.traceData(50025:50080, whichChannel(protocol, 1, 'V')) - baseline > 5)
        dataFilt = movingAverage(zData.traceData(50025:50080, whichChannel(protocol, 1, 'V')), 5);

        % filter the derivative
        tempDiff = diff(dataFilt);
        dataDerFilt = sgolayfilt(tempDiff, 2, 5);
        clear tempDiff;

        % filter as per Cohen and Miles 2000
        outData = zeros(size(dataFilt));
        for index = 2:length(dataFilt)
            if dataDerFilt(index - 1) > 0
                outData(index) = outData(index - 1) + dataDerFilt(index - 1);
            end
        end    

        % find where derivative of this function is changing from positive to negative
        functionDer = diff(outData);
        peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) > 0);

        % for each such value greater than derThresh find where the function last
        % began to deviate from 0 and call that an event start
        numStarts = 0;
        whereStarts = ones(length(peaks), 1);
        wherePeaks = whereStarts;
        for index = 1:length(peaks)
            if abs(outData(peaks(index))) > .1
                numStarts = numStarts + 1;
                whereStarts(numStarts) = peaks(index);
                while outData(whereStarts(numStarts)) ~= 0
                    whereStarts(numStarts) = whereStarts(numStarts) - 1;
                end
                wherePeaks(numStarts) = peaks(index);
            end
        end    
        tempData = polyfit(0:.2:1, zData.traceData(whereStarts(1) + 50025 + (2:7), whichChannel(protocol, 1, 'V'))', 1);
        outData = tempData(1);
        
        if ~nargout
            figure, plot(9990:.2:10016, zData.traceData(49950:50080, whichChannel(protocol, 1, 'V')))
            line((whereStarts(1) + 50025 + (2:7))/5, polyval(tempData, 0:.2:1), 'color', 'r');
        end
    end
else
    outData = nan;
end