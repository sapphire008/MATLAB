function retEggs = makeFakeEgg(realEgg, numEggs)
    % input is a numTrials x numCells egg 
    % (eg, 4x3 for four trials with three cells)
    
    numTrials = size(realEgg,1);
    tempCov = sqrtm(cov(realEgg)); % temp is a 3x3 matrix
    eMean = mean(realEgg,1); % a 1x3 matrix if there are 3 cells 
    if numEggs == 1
        retEggs = helperDoEgg(eMean, tempCov, numTrials);
    else
        retEggs = cell(numEggs,1);
        for ii = 1:numEggs
           retEggs{ii} = helperDoEgg(eMean, tempCov, numTrials);
        end
    end
end

function newEgg = helperDoEgg(eMean, tempCov, numTrials)
    hasNeg = 1;
    while hasNeg 
       newEgg = repmat(eMean,numTrials,1) + (tempCov * randn(3,numTrials)).';
       hasNeg = sum(newEgg(:) < 0);
    end
end