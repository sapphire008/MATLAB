function retValue=benEvents(inData, downEvents, MsPerPoint, startTime, endTime, parmList) 
  % benEvents   4/23/10 last changed to bail out on slope calc if either
  % Index20 or Index80 is still -1 after search
 
  % set detection constants 
    retValue=nan;

    if startTime==0
        startTime=MsPerPoint;
    end
    if endTime==0 
        endTime=length(inData)*MsPerPoint;
    end
    maxIndexAllowed=(endTime-startTime)*(1/MsPerPoint);
    startTimeIndex = startTime*(1/MsPerPoint);
    if startTimeIndex>4
        startTimeIndex=startTimeIndex - 4;  % to give points to calculate baseline
        maxIndexAllowed=maxIndexAllowed+4;
    end 
    correctionTime = (startTimeIndex-1)*MsPerPoint;
    endTimeIndex = (endTime+25) * (1/MsPerPoint); % add 25 ms to end time
    if endTimeIndex>numel(inData) 
        endTimeIndex=numel(inData);
    end
    data=inData(startTimeIndex:endTimeIndex);

%   correctionTime=0;
%   data=inData;
%     if startTime==0
%         startTime=MsPerPoint;
%     end
%     if endTime==0 
%         endTime=length(data)*MsPerPoint;
%     end
  
    
   if parmList==0 
        dataFilterLength = 11; % moving average filter of raw data trace
        derFilterLength = 7; % savitsky golay filter length (uses a third order filter)
        cumulativeDerThresh = -6.0; % pA
        cumulativeDerThreshReturn =-0.15; 
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
    
    % for each such value greater than derThresh find where the function last
    % began to deviate from 0 and call that an event start
    numStarts = 0;
    whereStarts = ones(length(peaks), 1); % pre-allocate space for speed
    wherePeaks = whereStarts;
    for index = 1:length(peaks)
        if abs(outData(peaks(index))) > cumulativeDerThresh
            numStarts = numStarts + 1;
            whereStarts(numStarts) = peaks(index);
            if downEvents
               while (outData(whereStarts(numStarts))) < (cumulativeDerThreshReturn)
                whereStarts(numStarts) = whereStarts(numStarts) - 1;
              end
            else
              while (outData(whereStarts(numStarts))) > (cumulativeDerThreshReturn)
                whereStarts(numStarts) = whereStarts(numStarts) - 1;
              end
            end 
            wherePeaks(numStarts) = peaks(index);
        end
    end
    
   
    wherePeaks = wherePeaks(whereStarts>3);
    whereStarts = whereStarts(whereStarts>3);
    
    wherePeaks = wherePeaks(whereStarts<maxIndexAllowed);
    whereStarts = whereStarts(whereStarts<maxIndexAllowed);
     
    numStarts=numel(whereStarts);
    
    whereStarts(numStarts + 1) = length(outData);
    whereStarts(numStarts + 2:end) = [];
    wherePeaks(numStarts + 1:end) = [];
     if numel(whereStarts)==2 
        whereStarts=whereStarts';
    end
%     msgbox(['Debug info: found ' num2str(numel(whereStarts)) ' events, with first at ' num2str(MsPerPoint*whereStarts(1)) ' ms']);
    
    % preallocate output data space
    pspData2 = zeros(length(whereStarts)-1,20);
    
    % get parameters for PSCs
    PeakDither=[-1 0 1];
    BaseDither=[-3 -2 -1 0];
    for pspIndex=1:length(whereStarts)-1
             pspData2(pspIndex,1)=correctionTime + ((2+whereStarts(pspIndex))*MsPerPoint); % start time in ms
             pspData2(pspIndex,2)=correctionTime +((2+wherePeaks(pspIndex))*MsPerPoint); % peak time in ms
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
             
             
             if Index20~=-1 && Index80 ~=-1 
               yData=data(Index20:Index80);
               xData=yData;
               for i=Index20:Index80
                 xData(1+(i-Index20))=((i-Index20)*MsPerPoint);
               end
               try
               polyResults=polyfit(xData,yData,1);
               pspData2(pspIndex,7)=polyResults(1); % 20-80 percent slope
               catch ME
%                  msgbox([ME.identifier ' and long is ' ME.message]);
               end
             else
                 pspData2(pspIndex,7)=0;
             end 
             
             pspData2(pspIndex,8)=correctionTime + (MsPerPoint +(Index20*MsPerPoint)); % output time points used for slope measurements
             pspData2(pspIndex,11)=MsPerPoint+((Index80-Index20)*MsPerPoint); % ms between 20 and 80% times
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
%                  msgbox([ME.identifier ' and long is ' ME.message]);
             end 
    end
 
    retValue=reshape(pspData2',1,[]); % makes one dimensional vector listing all points from a point and then the next one
    
end