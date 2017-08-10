function outData = meanVariance(inData, windowLength, overlapRatio, outputAxis)
% outValue = meanVariance(inData, windowLength, overlapRatio, outputAxis);

switch nargin
    case 1
        outData = nanmean(variance(inData));
    case 2
        counter = 1;
        for i = 1:windowLength:length(inData) - windowLength
            outData(counter) = mean(variance(inData(i:i + windowLength)));
            counter = counter + 1;
        end
        outData = mean(outData);
    case 3
        counter = 1;
        for i = 1:round(windowLength * overlapRatio):length(inData) - windowLength
            outData(counter) = mean(variance(inData(i:i + windowLength)));
            counter = counter + 1;
        end
        outData = mean(outData);
    case 4
        counter = 1;
        for i = 1:round(windowLength * overlapRatio):length(inData) - windowLength
            outData(counter) = mean(variance(inData(i:i + windowLength)));
            counter = counter + 1;
        end
        handles = get(ancestor(outputAxis, 'figure'), 'userData');
        set(ancestor(outputAxis, 'figure'), 'currentAxes', outputAxis)
        outputAxis = analysisAxis('meanVariance');
        line(((1:round(windowLength * overlapRatio):length(inData) - windowLength) + windowLength / 2) * handles.xStep(get(handles.channelControl(handles.axes == gca).channel, 'value')) + handles.minX, outData, 'color', [0 .5 0], 'userData', 'meanVariance', 'parent', outputAxis);
        set(outputAxis, 'ycolor', [0 .5 0]);
        ylabel(outputAxis, 'Variance');
        outData = mean(outData);          
end

% megaData = [];
% for windowLength = 1:length(inData)
%         counter = 1;
%         for i = 1:round(windowLength * overlapRatio):length(inData) - windowLength
%             outData(counter) = mean(variance(inData(i:i + windowLength)));
%             counter = counter + 1;
%         end
%         megaData(end + 1) = mean(outData);
% end
% figure, plot(1:length(inData), megaData);
% xlabel('Window');
% ylabel('Variance');