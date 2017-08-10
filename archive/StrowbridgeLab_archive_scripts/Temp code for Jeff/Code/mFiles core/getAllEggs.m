function eggOutput = getAllEggs(pprExpt, startSec, durationSec, basalStart, basalStop, minNumTrialsRequired, ignorePruning0or1)
     % returns a numEggs x 2 cell array with each egg in column1 and
     % corresponding stimLetter in column2; 
     eggOutput ={};
     prunedExpt = pprExpt;
     for i = size(prunedExpt,1):-1:2 % row1 is header info
        if (prunedExpt{i,4} == 0) && (ignorePruning0or1 == 0), prunedExpt(i,:) = []; end % remove that trial
     end
     stimLetters = unique(prunedExpt(2:end,2)); % generates a cell array
     for j = 1:numel(stimLetters)
         stimLetter = stimLetters{j};
         egg = makeEgg(prunedExpt, stimLetter, startSec, startSec + durationSec, basalStart, basalStop);
         numTrials = size(egg,1);
         if numTrials >= minNumTrialsRequired
            newRow = {stimLetter egg};
            eggOutput = [eggOutput; newRow]; 
         end
     end
end