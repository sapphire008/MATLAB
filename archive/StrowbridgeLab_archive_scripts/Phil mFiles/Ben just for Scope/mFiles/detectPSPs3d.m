  function [pspData noBlues] = detectPSPs3d(data, protocol) 
  % this is a subfunction, so gets access to outside variables  
  % 3d version made to remove pump noise on 8.6.08
  
  % set detection constants
    rinThresh = 0.1; % G ohm, traces with an input resistance less than this are rejected
    cumulativeDerThresh = 3; % pA
    baselineThreshEPSC = 6666; % pA, if the data 10 ms before a PSC range more than this then the kinetics aren't determined   
    baselineThreshIPSC=6666;
    amplitudeThreshEPSC = 40; % pA, PSCs smaller than this will not be detected    
    amplitudeThreshIPSC=80; 
    scaleFactor = 1; % factor by which to scale data traces
    dataFilterLength = 11; % moving average filter of raw data trace
    derFilterLength = 7; % savitsky golay filter length (uses a third order filter)
    blankStop = 50; % ms, time after which to start looking for PSCs
    supressBlueLines=0; % 1 for supress and 0 for show lines
    blockPumpNoise=0; % 1 for remove pump noise sections or 0 to leave in analysis
     
%     voltHold=0;%protocol.ampStepInitialAmplitude{1}; 
    voltHold=protocol.startingValues(whichChannel(protocol,1,'V'));
    if ~isnan(scaleFactor)
        data=data*scaleFactor;
    end
    if numel(data)~=26000
       extraPoints=zeros(1000,1);  
       extraPoints(:,1)=data(2500);
       data=cat(1,data, extraPoints);
    end
    
    Rin=nan;
    if voltHold<0 
        % check Rin
        initCur=mean(data(1:99));
        stepCur=mean(data(495:594));
        Rin=1000*(10/(stepCur-initCur)); % in megaOhms
        EPSCs=1;
    else
        EPSCs=0;
    end 
    
%     % check the input resistance
%     if protocol.ampPulse1Amplitude{1} / (calcMean(data(mean([protocol.ampPulse1Start{1} protocol.ampPulse1Stop{1}]) * 1000 / protocol.timePerPoint:protocol.ampPulse1Stop{1} * 1000 / protocol.timePerPoint)) - calcMean(data(1:protocol.ampPulse1Start{1} * 1000 / protocol.timePerPoint - 1))) > rinThresh
%         data = data * scaleFactor;
%     else
%         error('Input resistance too low')
%     end
        
  b1=benPeakAllPoints(data(1250:6250));
  b2=benPeakAllPoints(data(6250:12500));
  b3=benPeakAllPoints(data(12500:18700));
  b4=benPeakAllPoints(data(18700:25999));
  baselineCurScaled=median([b1 b2 b3 b4]);
  baselineCur=baselineCurScaled/scaleFactor;

    % remove artifacts
    data = medfilt1(data, 5);

    % filter the raw data
    dataFilt = movingAverage(data, dataFilterLength);

    % filter the derivative
    dataDer = diff(dataFilt);
    dataDer = sgolayfilt(dataDer, 2, derFilterLength);

    % up-only filter
    outData = zeros(size(dataFilt));
    if EPSCs
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
    if EPSCs
        % find where derivative of this function is changing from negative to positive
        functionDer = diff(outData);
        peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) < 0);
    else
        % find where derivative of this function is changing from
        % positive to negative
        functionDer = diff(outData);
        peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) > 0);
    end
    
    % throw out all of the events in the time before blankStop
    peaks = peaks(peaks > blankStop * 1000 / protocol.timePerPoint);

    % for each such value greater than derThresh find where the function last
    % began to deviate from 0 and call that an event start
    numStarts = 0;
    whereStarts = ones(length(peaks), 1); % pre-allocate space for speed
    wherePeaks = whereStarts;
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
    whereStarts(numStarts + 1) = length(outData);
    whereStarts(numStarts + 2:end) = [];
    wherePeaks(numStarts + 1:end) = [];

    % preallocate output data space
    pspData = nan(length(whereStarts) - 1, 5); % indexing is (#, [amplitude riseTime  startIndex typeCode peakTimeMs])

    % scan for potential pump noise artifacts
    excludedPeaks=[];
    if blockPumpNoise && numel(whereStarts)>1
        index=2;
        intervalThresholdMs=20;
        startBarrageIndex=nan;
        endBarrageIndex=nan;
        while (index<=numel(whereStarts))
            curInterval=(whereStarts(index)-whereStarts(index-1))* (protocol.timePerPoint / 1000);
            if curInterval<intervalThresholdMs
                if isnan(startBarrageIndex)
                    startBarrageIndex=index-1;
                end
            else
               if ~isnan(startBarrageIndex)
                    endBarrageIndex=index-1;
                    if (endBarrageIndex-startBarrageIndex)>3
                        % had four events in a row with less than specified
                        % interval so flag this section as pump noise
                        startBarrage=whereStarts(startBarrageIndex);
                        endBarrage=whereStarts(endBarrageIndex);
                        disp([' *** pump noise barrage from ' num2str(startBarrage*.2) ' to ' num2str(endBarrage*.2) ' ms']);
                        excludedPeaks=[excludedPeaks startBarrageIndex:endBarrageIndex];
                        startBarrageIndex=nan;
                        endBarrageIndex=nan;
                    else
                        startBarrageIndex=nan; % ignore because barrage was not long enough
                    end
               end
            end
            index=index+1;
        end
    end
    
    % get parameters for PSCs
    numEvents=0;
    numAmpEvents=0;
    meanAmp=0;
    for pspIndex = 1:length(whereStarts) - 1
        pspData(pspIndex,3)=whereStarts(pspIndex);
        pspData(pspIndex,5)=wherePeaks(pspIndex)* (protocol.timePerPoint / 1000);
        pspData(pspIndex, 2) = (wherePeaks(pspIndex) - whereStarts(pspIndex)) .* (protocol.timePerPoint / 1000);
        pspData(pspIndex,1)=nan; 
        eventBaseline=mean(dataFilt(whereStarts(pspIndex)+(-50:-1)));
        eventBaselineImmediate=mean(data(whereStarts(pspIndex)+(-6:-1)));
        eventAmplitude=dataFilt(wherePeaks(pspIndex)) - dataFilt(whereStarts(pspIndex));
        if EPSCs
             if eventAmplitude>(-1*amplitudeThreshEPSC) || (eventBaselineImmediate-baselineCurScaled)>baselineThreshEPSC || sum(excludedPeaks==pspIndex)>0
                pspData(pspIndex,4)=0; % ignore code for event because it is too small or wrong sign
            else
                if (eventBaseline-baselineCurScaled)<(-1*baselineThreshEPSC)
                    pspData(pspIndex,4)=1; % frequency only code
                    numEvents=numEvents+1;
                else
                    pspData(pspIndex,1)=eventAmplitude;
                    pspData(pspIndex,4)=2; % code for okay event to measure amplitude
                    numAmpEvents=numAmpEvents+1;
                    numEvents=numEvents+1;
                    meanAmp=meanAmp+eventAmplitude;
                end 
            end 
        else
            if eventAmplitude<amplitudeThreshIPSC  || (eventBaselineImmediate-baselineCurScaled)<(-1*baselineThreshIPSC)  || sum(excludedPeaks==pspIndex)>0
                pspData(pspIndex,4)=0; % ignore code for event because it is too small or wrong sign
            else
                if (eventBaseline-baselineCurScaled)>baselineThreshIPSC
                    pspData(pspIndex,4)=1; % frequency only code
                    numEvents=numEvents+1;
                else
                    pspData(pspIndex,1)=eventAmplitude;
                    pspData(pspIndex,4)=2; % code for okay event to measure amplitude
                    numAmpEvents=numAmpEvents+1;
                    numEvents=numEvents+1;
                    meanAmp=meanAmp+eventAmplitude;
                end 
            end 
        end 
    end
    meanAmp=meanAmp/numAmpEvents;

    % write information file
%     fid = fopen(['C:\' protocol.fileName(find(protocol.fileName == '\', 1, 'last') + 1:end) '.txt'], 'w');
%         fprintf(fid, [protocol.fileName(find(protocol.fileName == '\', 1, 'last') + 1:end) '\n']);
%         fprintf(fid, [datestr(now, 0) '\n']);
%         fprintf(fid, 'Data Filter Length = : %g\n', dataFilterLength);
%         fprintf(fid, 'Derivative Filter Length = : %g\n', derFilterLength);
%         fprintf(fid, 'Are EPSCs = : %g\n', EPSCs);
%         fprintf(fid, 'Cumulative Derivative Threshold = : %g\n', cumulativeDerThresh);
%         fprintf(fid, 'Input Resistance Threshold = : %g\n', rinThresh);
%         fprintf(fid, 'Scale Factor = : %g\n', scaleFactor);
%         fprintf(fid, ['Amplitude = %g ' char(177) ' %g pA\n'], nanmean(pspData(:,1)), nanstd(pspData(:,1)));
%         fprintf(fid, ['Rise time = %g ' char(177) ' %g ms\n'], nanmean(pspData(:,2)), nanstd(pspData(:,2)));
%         fprintf(fid, 'Number of events = %g\n', length(pspData));        
%         fprintf(fid, 'Number of events characterized= %g\n', sum(~isnan(pspData(:, 1))));                
%         fprintf(fid, 'Average frequency = %g Hz\n\n', length(pspData) / 5);   
%     fclose(fid);

    % write data file
%     fid = fopen(['C:\' protocol.fileName(find(protocol.fileName == '\', 1, 'last') + 1:end) ' Data.txt'], 'w');   
%         fprintf(fid, '%f\t%1.1f\n', pspData');
%     fclose(fid);    
     
    % draw little L's for rise and amp
    for pspIndex = 1:size(pspData, 1)
        line(whereStarts(pspIndex) * protocol.timePerPoint / 1000 + [0 pspData(pspIndex, 2) pspData(pspIndex, 2)], (data(whereStarts(pspIndex)) + [0 0 pspData(pspIndex,1)]) / scaleFactor, 'color', 'g', 'linewidth', 3);
    end    
    
    % now draw the markers above trace
        markerOffset=50;
        markerHeight=20;
        if EPSCs==1 
           y1=baselineCur+markerOffset;
           y2=y1+markerHeight;
        else
           y1=baselineCur-markerOffset;
           y2=y1-markerHeight;
        end
        for pspIndex = 1:length(whereStarts) - 1
            x1= (whereStarts(pspIndex) * protocol.timePerPoint / 1000) + pspData(pspIndex,2);
            switch pspData(pspIndex,4)
                case 0
                    % small or inverted events
                    if ~supressBlueLines
                      line([x1 x1], [y1 y2],  'color', 'b', 'linewidth', 2);
                    end
                case 1
                   % frequency only events
                   line([x1 x1], [y1 y2],  'color', 'r', 'linewidth', 2);
                case 2 
                % amplitude kinetics and frequency events
                   line([x1 x1], [y1 y2],  'color', 'g', 'linewidth', 2);
            end
        end
        
    noBlues=pspData(pspData(:,4)>0,:);
    stimTimes = findStims(protocol);
    bins = 0:500:25000;
    freqData = histc(noBlues(:,5), bins) * 1000/diff(bins(1:2));
    freqData2 = histc(noBlues(:,5), bins + diff(bins(1:2))/2) * 1000/diff(bins(1:2));
    totalData = [freqData freqData2]';
    assignin('base', 'freqData', totalData(:));
    
    assignin('base','noBlueLines', noBlues);
    assignin('base','PSPs',pspData);
    assignin('base','vHold',voltHold);
    
    % dump info to the command window
    if EPSCs==1 
        tmpStr='  For EPSCs';
    else
        tmpStr='  For IPSCs';
    end
    tmpStr=[tmpStr ' at ' num2str(voltHold) 'mV'];
    if ~isnan(Rin)
        tmpStr=[tmpStr '  Rin = ' num2str(Rin,'%.1f') ' Mohms'];
    end
   
    T=[protocol.fileName char(13) tmpStr ];
    T=[T '  Baseline current = ' num2str(baselineCur) char(13)];
    T=[T sprintf('Number of events = %g', numEvents) char(13)];        
    T=[T sprintf('Number of events with amplitudes = %g', numAmpEvents) '   (mean amp = '];        
    T=[T num2str(meanAmp,'%0.2f') ')' char(13)];
    if EPSCs==1
        T=[T 'Baseline Thresh = ' num2str(baselineThreshEPSC,'%.2f') '  Amp Thresh = ' num2str(amplitudeThreshEPSC) char(13)];
    else
        T=[T 'Baseline Thresh = ' num2str(baselineThreshIPSC,'%.2f') '  Amp Thresh = ' num2str(amplitudeThreshIPSC) char(13)];
    end
    T=[T 'Cummulative Der Thresh = ' num2str(cumulativeDerThresh,'%.2f') '  Scale factor = ' num2str(scaleFactor) char(13)];
    disp(T);
    fid=fopen('d:\Frank Event Log.txt','a');
    fprintf(fid,'%s',[T char(13)]);
    fclose(fid);
    

    
%     disp(sprintf(['Amplitude = %g ' char(177) ' %g pA'], nanmean(pspData(:,1)), nanstd(pspData(:,1))));
%     disp(sprintf(['Rise time = %g ' char(177) ' %g ms'], nanmean(pspData(:,2)), nanstd(pspData(:,2))));
    
    % plot all that info
%     if 1 == 2
%         h = newScope({data, dataFilt, [dataDer; nan], outData}, protocol.timePerPoint / 1000 .* (1:length(data)), {'Raw Data', 'Filtered Data', 'Derivative', 'Up-Only Function'});
%         if EPSCs
%             line(get(gca, 'xlim'), -[cumulativeDerThresh cumulativeDerThresh], 'linestyle', ':', 'color', 'r', 'parent', h.axes(4));
%         else
%             line(get(gca, 'xlim'), [cumulativeDerThresh cumulativeDerThresh], 'linestyle', ':', 'color', 'r', 'parent', h.axes(4));
%         end
%         
%         % draw little L's for rise and amp
%         for pspIndex = 1:length(whereStarts) - 1
%             line(whereStarts(pspIndex) * protocol.timePerPoint / 1000 + [0 pspData(pspIndex, 2) pspData(pspIndex, 2)], data(whereStarts(pspIndex)) + [0 0 pspData(pspIndex,1)], 'parent', h.axes(1), 'color', 'g', 'linewidth', 3);
%         end
       
    end