function outData = notchFilter(inData, samplingFreq, values)
% notch filters data
% filteredData = notchFilter(rawData, samplingFrequency, values);
% if values is nan(s) then the function will execute a gradient search of
%   correlation around 60 Hz (and multiples thereof) to find maximum
%   correlation in the input signal.
% defaults:
%   samplingFrequency = 5000 Hz
%   values = 60.023 Hz

    centerFreq = 60; %Hz
    persistent startingPoints
    if isempty(startingPoints)
    	startingPoints = [59.99 120 263.9 299.9 2104 2368];%centerFreq + 60 * (1:10);
    end
    
    % pulls out specified frequencies in the time domain via correlation
    if nargin < 2
        samplingFreq = 20000; % Hz
    end
    if nargin < 3
        values = 300;
    end
    
    outData = inData;
    if nargout == 0
        figure('name', 'Removal', 'numbertitle', 'off');
        xData = (1:length(inData)) / samplingFreq * 1000;
        subplot(numel(values) + 1, 1, 1);
        plot(xData, outData);
        title('Original Data')
    end
    
    if isnan(values(1))
        % determine the most common frequency
        % iterate through sine wave fits around centerFreq Hz (gradient descent) until
        % the correlation plot with the signal is flat (no beat frequency)
        for i = 1:numel(values)
            xData = [];
            startingPoints(i) = fminsearch(@sinAmp, startingPoints(i), optimset('MaxFunEvals', 300, 'Display', 'none', 'TolFun', 0, 'Tolx', 0));            
%             if startingPoints(i) > i * (centerFreq * 1.1) || startingPoints(i) < i * (centerFreq * 0.9)
%                 startingPoints(i) = i * centerFreq;
%             end
            sineData = 2 * mean(-sin(2 * pi * startingPoints(i) / samplingFreq * (1:length(outData))') .* (outData - mean(outData)));
            cosineData = 2 * mean(cos(2 * pi * startingPoints(i) / samplingFreq * (1:length(outData))') .* (outData - mean(outData)));
            outData = outData - sqrt(sineData.*sineData + cosineData.*cosineData) * cos(atan2(sineData, cosineData) + 2*pi*startingPoints(i) / samplingFreq * (1:length(outData))');
            disp(['Filtering at ' num2str(startingPoints(i)) ' Hz']);
            
            if nargout == 0
                subplot(numel(values) + 1, 1, 1 + i);
                plot(xData, outData);
                title(['Data without ' num2str(values(i)) 'Hz component']);
            end
        end        
    else
        for i = 1:numel(values)
            sineData = 2 * mean(-sin(2 * pi * values(i) / samplingFreq * (1:length(outData))') .* (outData - mean(outData)));
            cosineData = 2 * mean(cos(2 * pi * values(i) / samplingFreq * (1:length(outData))') .* (outData - mean(outData)));
            outData = outData - sqrt(sineData.*sineData + cosineData.*cosineData) * cos(atan2(sineData, cosineData) + 2*pi*values(i) / samplingFreq * (1:length(outData))');

            if nargout == 0
                subplot(numel(values) + 1, 1, 1 + i);
                plot(xData, outData);
                title(['Data without ' num2str(values(i)) 'Hz component']);
            end
        end        
    end

    if nargout == 0
        xlabel('Time (msec)');
    end

    function sse = sinAmp(params)
        sineData = 2 * mean(-sin(2 * pi * params / samplingFreq * (1:length(outData))') .* (outData - mean(outData)));
        cosineData = 2 * mean(cos(2 * pi * params / samplingFreq * (1:length(outData))') .* (outData - mean(outData)));
        
        sse = -sqrt(sineData.*sineData + cosineData.*cosineData);
        xData(end + 1) = params;
    end
end