function [startTimes, peakTimes,amps] = findEventsJeff(inData, threshold, eventsDown1or0, msPerPoint)
       % revised 2 Feb 2015 BWS
       % part of Jeff neocortical poly/code/mFiles core
       % inputs are: raw data vector, 1 or 0 to indicate to look for down
       % events, a detection threshold value (eg, 0.6) and msPerPoint (typically 0.2)
       % output are event times in ms for onset and peak of each event and
       % event amplitudes
    
      startTimeMs = 0; % to trigger
      endTimeMs = 0;
      
      PSPsDown = eventsDown1or0;
      dataFilterLength = 5;
      derFilterLength = 7;
      cumulativeDerThresh = abs(threshold);
      if PSPsDown 
          cumulativeDerThresh = 1 * cumulativeDerThresh;
      end
      pointsPerMs = fix(1/msPerPoint);
      
      % make sure that the filter length is odd
      if dataFilterLength / 2 == fix(dataFilterLength / 2)
          dataFilterLength = dataFilterLength + 1;
      end
      if derFilterLength / 2 == fix(derFilterLength / 2)
          derFilterLength = derFilterLength + 1;
      end
      
      if startTimeMs == 0 
         startIndex = 1; 
      else
         startIndex = fix(startTimeMs * pointsPerMs);
      end
      correctionTime = startIndex * msPerPoint;
      if endTimeMs == 0
          endIndex = numel(inData);
      else
          endIndex = (endTimeMs * pointsPerMs) - 1;
      end
      data = inData(startIndex:endIndex);
      
      % filter the trace
     % dataFilt = sgolayfilt(data, 2, dataFilterLength);
       dataFilt = movingAverage(data, dataFilterLength);
      % dataFilt = medfilt1(data, dataFilterLength);
      
      % filter the derivative
      tempDiff = diff(dataFilt);
      dataDerFilt = sgolayfilt(tempDiff, 2, derFilterLength);
      clear tempDiff;
      
      % filter as per Cohen and Miles 2000
      outData = zeros(size(dataFilt));
      if PSPsDown
          for index = 2:length(dataFilt)
              if dataDerFilt(index - 1) < 0
                  outData(index) = outData(index - 1) + dataDerFilt(index - 1);
              end
          end
      else
          for index = 2:length(dataFilt)
              if dataDerFilt(index - 1) > 0
                  outData(index) = outData(index - 1) + dataDerFilt(index - 1);
              end
          end
      end
      
      if PSPsDown
          % find where derivative of this function is changing from negative to positive
          functionDer = diff(outData);
          peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) < 0);
      else
          % find where derivative of this function is changing from positive to negative
          functionDer = diff(outData);
          peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) > 0);
      end
      
      % for each such value greater than derThresh find where the function last
      % began to deviate from 0 and call that an event start
      numStarts = 0;
      whereStarts = ones(length(peaks), 1); % pre-allocate space for speed
      wherePeaks = whereStarts;
      % new baseline detection routine 26 July 2013 BWS
%       whereStarts(:) = nan;
%       wherePeaks(:) = nan;
%       for index = 1:length(peaks)
%          if abs(outData(peaks(index))) > cumulativeDerThresh
%              numStarts = numStarts + 1;
%              wherePeaks(numStarts) = peaks(index);
%              for revIndex = index:-1:2
%                 if outData(revIndex) == 0 
%                    break; 
%                 end
%              end
%              whereStarts(numStarts) = revIndex;
%          end
%       end
%       whereStarts = whereStarts(~isnan(whereStarts));
%       wherePeaks = wherePeaks(~isnan(wherePeaks));
      
      for index = 1:length(peaks)
          if abs(outData(peaks(index))) > cumulativeDerThresh
              numStarts = numStarts + 1;
              whereStarts(numStarts) = peaks(index);
              while outData(whereStarts(numStarts)) ~= 0
                  whereStarts(numStarts) = whereStarts(numStarts) - 1;
              end
              wherePeaks(numStarts) = peaks(index);
          end
      end
      wherePeaks = wherePeaks(whereStarts>3);
      whereStarts = whereStarts(whereStarts>3);
      startTimes = ((whereStarts + 1) .* msPerPoint) + correctionTime;
      peakTimes = ((wherePeaks - 1) .* msPerPoint) + correctionTime;
      
      % new part from 2 Feb 2015 BWS
      amps = startTimes .* 0;
      for ii = 1:numel(startTimes)
         startIndex = fix(pointsPerMs * (startTimes(ii) - 1)); % start 1 ms before
         if startIndex < 1, startIndex = 1; end
         peakIndex = fix(pointsPerMs * peakTimes(ii)) + 1;
         if peakIndex > numel(inData), peakIndex = numel(inData); end
         startDither = (0:1)';
         peakDither = (-1:0)';
         amps(ii) = mean(inData(peakIndex + peakDither)) - mean(inData(startIndex + startDither));
      end
      
%       startTimes = (whereStarts .* msPerPoint) + correctionTime;
%       peakTimes = (wherePeaks .* msPerPoint) + correctionTime;
     
end