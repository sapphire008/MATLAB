function eggArray = makeEgg(pprExpt, stimStringIn, startSec, stopSec, basalStartSec, basalStopSec)
    % revised 5 Jan 2015 BWS for poly3 ppr location stim files
    % basalStartSec == basalStopSec == 0 for no baseline subtract
    % pprExpt assumed to have row1 be string comments
    % rows 2--end have eventTimesMs in columns 5... (one column per cell)
    % column2 is stimString ('A' or similar); column2 is drugString
    % column4 is 1==okayToUse or 0==prunedAway; column1 is epiStringID
    
    stimString = strtrim(stimStringIn);
    startMs = startSec * 1000;
    stopMs = stopSec * 1000;
    winDurSec = stopSec - startSec;
    basalStartMs = basalStartSec * 1000;
    basalStopMs = basalStopSec * 1000;
    basalDurSec = basalStopSec - basalStartSec;
    baselineSubtract = basalStopMs > 0;
    numCells = size(pprExpt,2) - 4; % default unless loop finds an empty vector
    for i = 5:size(pprExpt,2)
        if numel(pprExpt{2,i}) == 0 
            numCells = i - 5;
            break;
        end
    end
    eggArray = [];
    for i = 2:size(pprExpt,1) % assume row1 is string header info
        if strcmpi(strtrim(pprExpt{i,2}), stimString) && pprExpt{i,4}==1
           % use this trial since it has the correct stimLetter and is not pruned
           newRow = zeros(1,numCells);
           for cell = 1:numCells
              eventListMs = pprExpt{i, 4 + cell};
              tempFreq = numel(find(eventListMs >= startMs & eventListMs < stopMs)) / winDurSec;
              if baselineSubtract
                  basalFreq = numel(find(eventListMs >= basalStartMs & eventListMs < basalStopMs)) / basalDurSec; 
                  tempFreq = tempFreq - basalFreq;
              end
              newRow(cell) = tempFreq;
           end
           eggArray = [eggArray; newRow];
        end
    end
    if size(eggArray,1) == 0
       display(['Warning... no trials found for stimString ' stimString]); 
    end
end