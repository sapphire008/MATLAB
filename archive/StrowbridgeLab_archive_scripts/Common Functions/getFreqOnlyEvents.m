function [allEvents cleanEventsStart cleanEventsPeak] = getFreqOnlyEvents(inData, startTimes, peakTimes, gapThresh, parmList)
  % revised 1 May 2012 BWS
  %  gapThresh is how low the diff value has to get during inflexions;
  %  typical is 0.05 for c-clamp
  % returns allEvents time list in ms; cleanEvents are only events without
  % inflexions in rising phase
  
  allEvents = [];
  cleanEventsStart = [];
  cleanEventsPeak = [];
  zData = evalin('base', 'zData');
  PSPsDown = parmList(1); % 1 for down events like IPSPs and EPSCs
  dataFilterLength = parmList(2);
  derFilterLength = parmList(3);
  cumulativeDerThresh = abs(parmList(4));
  pointsPerMs = 1 / zData.protocol.msPerPoint;
  gapThresh = abs(gapThresh);
  startLooking = 5 * pointsPerMs; % 2 ms pre-data plus 3 ms min delay
  dither = [-1 0 1];
  
  for i = 1:numel(startTimes)
      curState = 0;
      index1 = fix((startTimes(i) - 2) * pointsPerMs);
      index2 = fix((peakTimes(i) + 1) * pointsPerMs);
      segment = inData(index1:index2);
      if PSPsDown
         segment = segment .* -1; 
      end
      dataFilt = movingAverage(segment, dataFilterLength);
      tempDiff = diff(dataFilt);
      dataDerFilt = sgolayfilt(tempDiff, 2, derFilterLength);
      subEventTimes = startTimes(i);
    
      for j = startLooking:(numel(dataDerFilt) - 5)
          curValue = mean(dataDerFilt(j + dither));
          if curState == 0 && curValue < gapThresh
             curState = 1;
          end 
          if curState == 1 && curValue > (gapThresh + 0.05)
              subEventTimes = [subEventTimes (startTimes(i) + ((j - (2 * pointsPerMs)) * zData.protocol.msPerPoint))];
              curState = 0;
          end
      end
      allEvents = [allEvents subEventTimes];
      if numel(subEventTimes) == 1 
         cleanEventsStart = [cleanEventsStart startTimes(i)]; 
         cleanEventsPeak = [cleanEventsPeak peakTimes(i)];
      end
  end
  
end