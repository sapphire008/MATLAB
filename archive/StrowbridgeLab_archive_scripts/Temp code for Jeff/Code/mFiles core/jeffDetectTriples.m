function outArray = jeffDetectTriples(zData, traceList, thresholdList, down1or0, maxAmpAllowed)
    % revised 2 Feb 2015 BWS
    % inputs are trace list eg {'VoltA' 'VoltC' 'VoltD'}
    % and a threshold for each trace and 1 or 0 based on whether they are
    % downward events
    % output is a numTraces x 3 cell array with each row containing
    %   startTimesMs, peakTimesMs, Amplitudes
    
    outArray = cell(numel(traceList), 3);
    maxAmp = abs(maxAmpAllowed);
    msPerPoint = zData.protocol.msPerPoint;
    colorList = {'r' 'b' 'g' 'c'}; % should not need more than 4 colors
    resultStr = '';
    for ii = 1:numel(traceList)
        testTrace = eval(['zData.' traceList{ii}]);
        [startTimes, peakTimes, amps] = findEventsJeff(testTrace, thresholdList(ii), down1or0, msPerPoint);
        prune = zeros(1,numel(startTimes));
        % do some checks for outlier events to prune
        for jj = 1:numel(startTimes)
           if down1or0==1 && amps(jj) > 0, prune(jj) = 1; end % looking for down events and got an up event
           if down1or0==0 && amps(jj) < 0, prune(jj) = 1; end % looking for up events and got a down event
           if abs(amps(jj)) > maxAmp, prune(jj) = 1; end % event was too big to be real
        end
        % save detected event info into cell array to return
        outArray{ii,1} = startTimes(~prune); % save event times in cell array that is returned
        outArray{ii,2} = peakTimes(~prune);
        outArray{ii,3} = amps(~prune);
        resultStr = [resultStr traceList{ii} '=' num2str(numel(startTimes)) ' '];
      %  scopeDisplayMarkers(traceList{ii}, startTimes, -72, -70, colorList{ii});
    end
    disp(zData.protocol.fileName);
    disp(['  Events: ' resultStr])
end