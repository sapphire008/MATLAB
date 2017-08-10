function retValue=benEventsOld(data, downEvents, MsPerPoint, startTime, endTime, parmList) 
  % benEvents   9/5/09
 
  % set detection constants 
    retValue=nan;
    if startTime==0
        startTime=MsPerPoint;
    end
    if endTime==0 
        endTime=length(data)*MsPerPoint;
    end
   
   if parmList==0 
        dataFilterLength = 11; % moving average filter of raw data trace
        derFilterLength = 7; % savitsky golay filter length (uses a third order filter)
        cumulativeDerThresh = 0.60; % pA
        cumulativeDerThreshReturn =0.15; 
   else
       if numel(parmList)>=4 
            dataFilterLength = parmList(1); 
            derFilterLength = parmList(2); 
            cumulativeDerThresh = parmList(3);
            cumulativeDerThreshReturn =parmList(4); 
       else
           msgbox('Error in benEvents.m  Wrong number of paramaters passed.');
       end 
   end
   
%    msgbox(['Debug info - MsPerPoint: ' num2str(MsPerPoint) ' Times ' num2str(startTime) ' and ' num2str(endTime) ' Parms: ' num2str(parmList(1)) ' ' num2str(parmList(2)) ' ' num2str(parmList(3)) ' ' num2str(parmList(4))]);
  % msgbox(['From Matlab benEvents: ' num2str(mean(data))]);   

    % remove artifacts
    data = medfilt1(data, 5);
    

    % filter the raw data
    dataFilt = movingAverage(data, dataFilterLength);

    % filter the derivative
    dataDer = diff(dataFilt);
    dataDer = sgolayfilt(dataDer, 2, derFilterLength);

    % up-only filter
    outData = zeros(size(dataFilt));
    if downEvents
        for index = 2:length(dataFilt)
            if dataDer(index - 1) < 0
                outData(index) = outData(index - 1) + dataDer(index - 1);
            end
        end
    else
        for index = 2:length(dataFilt)
            if dataDer(index - 1) > 0
                outData(index) = outData(index - 1) + dataDer(index - 1);
            end
        end    
    end

    % find the locations of peaks in the up-only function
    if downEvents
        % find where derivative of this function is changing from negative to positive
        functionDer = diff(outData);
        peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) < 0);
    else
        % find where derivative of this function is changing from
        % positive to negative
        functionDer = diff(outData);
        peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) > 0);
    end
    
    % throw out all of the events in the time before startTime + 10 ms
    peaks = peaks(peaks > ((startTime +10)* (1/ MsPerPoint )));
    
    % throw out all of the events in the time after endTime 
    peaks = peaks(peaks < ((endTime-10) * (1/ MsPerPoint )));
    
    % for each such value greater than derThresh find where the function last
    % began to deviate from 0 and call that an event start
    numStarts = 0;
    whereStarts = ones(length(peaks), 1); % pre-allocate space for speed
    wherePeaks = whereStarts;
    for index = 1:length(peaks)
        if abs(outData(peaks(index))) > cumulativeDerThresh
            numStarts = numStarts + 1;
            whereStarts(numStarts) = peaks(index);
            while abs(outData(whereStarts(numStarts))) > cumulativeDerThreshReturn
                whereStarts(numStarts) = whereStarts(numStarts) - 1;
            end
            wherePeaks(numStarts) = peaks(index);
        end
    end
    whereStarts(numStarts + 1) = length(outData);
    whereStarts(numStarts + 2:end) = [];
    wherePeaks(numStarts + 1:end) = [];
    
%     msgbox(['Debug info: found ' num2str(numel(whereStarts)) ' events, with first at ' num2str(MsPerPoint*whereStarts(1)) ' ms']);
    
    % preallocate output data space
    pspData2 = zeros(length(whereStarts)-1,10);
    
    % get parameters for PSCs
    PeakDither=[-1 0 1];
    BaseDither=[-3 -2 -1 0];
    for pspIndex=1:length(whereStarts)-1
             pspData2(pspIndex,1)=(2+whereStarts(pspIndex))*MsPerPoint; % start time in ms
             pspData2(pspIndex,2)= (2+wherePeaks(pspIndex))*MsPerPoint; % peak time in ms
             pspData2(pspIndex,3)=pspData2(pspIndex,2)-pspData2(pspIndex,1); % rise time in ms
             pspData2(pspIndex,4)=mean(data(whereStarts(pspIndex)+BaseDither)); % baseline amplitude before event
             pspData2(pspIndex,5)=mean(data(wherePeaks(pspIndex)+PeakDither)); % mean amplitude of 3 points around peak
             pspData2(pspIndex,6)=pspData2(pspIndex,5)-pspData2(pspIndex,4); % event amplitude
             
             if downEvents
                 Index20 = -1;
                 targetLevel=pspData2(pspIndex,4)-(0.2*pspData2(pspIndex,6)); % 20% down event
                 for k=whereStarts(pspIndex):wherePeaks(pspIndex)
                     if data(k)<=targetLevel
                         if Index20<0 
                             Index20=k-1; % index to 20% down event
                         end
                     end
                 end
                 Index80 = -1;
                 targetLevel=pspData2(pspIndex,4)-(0.8*pspData2(pspIndex,6)); % 80% down event
                 for k=whereStarts(pspIndex):wherePeaks(pspIndex)
                     if data(k)<targetLevel
                         if Index80<0 
                             Index80=k; % index to 80% down event
                         end
                     end
                 end
             else
                 Index20 = -1;
                 targetLevel=pspData2(pspIndex,4)+(0.2*pspData2(pspIndex,6)); % 20% up event
                 for k=whereStarts(pspIndex):wherePeaks(pspIndex)
                     if data(k)>=targetLevel
                         if Index20<0 
                             Index20=k-1; % index to 20% up event
                         end
                     end
                 end
                 Index80 = -1;
                 targetLevel=pspData2(pspIndex,4)+(0.8*pspData2(pspIndex,6)); % 80% up event
                 for k=whereStarts(pspIndex):wherePeaks(pspIndex)
                     if data(k)>=targetLevel
                         if Index80<0 
                             Index80=k; % index to 80% up event
                         end
                     end
                 end
             end 
             
             yData=data(Index20:Index80);
             xData=yData;
             for i=Index20:Index80
                 xData(1+(i-Index20))=((i-Index20)*MsPerPoint);
             end
             try
             polyResults=polyfit(xData,yData,1);
             pspData2(pspIndex,7)=polyResults(1); % 20-80 percent slope
             catch ME
                 msgbox([ME.identifier ' and long is ' ME.message]);
             end 
             
             pspData2(pspIndex,8)=MsPerPoint +(Index20*MsPerPoint); % output time points used for slope measurements
             
             startInitSlopeIndex=(0.8*(1/MsPerPoint))+whereStarts(pspIndex); % 0.8 ms offset to begin on rising edge
             stopInitSlopeIndex = startInitSlopeIndex+(4*(1/MsPerPoint));
             yData=data(startInitSlopeIndex:stopInitSlopeIndex);
             xData=yData;
             for i=startInitSlopeIndex:stopInitSlopeIndex
                 xData(1+(i-startInitSlopeIndex))=((i-startInitSlopeIndex)*MsPerPoint);
             end
             try
             polyResults=polyfit(xData,yData,1);
             pspData2(pspIndex,9)=polyResults(1); % initial slope over 4 ms
             
             startInitSlopeIndex=(0.8*(1/MsPerPoint))+whereStarts(pspIndex); % 0.8 ms offset to begin on rising edge
             stopInitSlopeIndex = startInitSlopeIndex+(1.4*(1/MsPerPoint));
             yData=data(startInitSlopeIndex:stopInitSlopeIndex);
             xData=yData;
             for i=startInitSlopeIndex:stopInitSlopeIndex
                 xData(1+(i-startInitSlopeIndex))=((i-startInitSlopeIndex)*MsPerPoint);
             end
             try
             polyResults=polyfit(xData,yData,1);
             pspData2(pspIndex,10)=polyResults(1); % initial slope over 1.4 ms
        
             catch ME
                 msgbox([ME.identifier ' and long is ' ME.message]);
             end 
    end
 
    retValue=reshape(pspData2',1,[]); % makes one dimensional vector listing all points from a point and then the next one
    
end