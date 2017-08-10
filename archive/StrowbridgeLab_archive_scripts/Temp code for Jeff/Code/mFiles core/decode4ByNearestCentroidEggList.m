function [percentCorrect actualStim predictedStim] = decode4ByNearestCentroidEggList(eggList)
    % revised 16 Jan 2015 BWS for poly3
    if numel(eggList) ~=4
       disp('decode4byNearestCentroidEggList.m requires an input cell array with four eggs');
       return
    end
    firstEgg = eggList{1};
    numCells = size(firstEgg,2); % num columns is number of cells
    centroids = zeros(4,numCells);
    totalNumTrials = 0;
    numCorrectPredictions = 0;
    for stimNum = 1:4
        trialPoints = eggList{stimNum};
        totalNumTrials = totalNumTrials + size(trialPoints, 1);
        centroids(stimNum,:) = mean(trialPoints);
    end
    actualStim = zeros(totalNumTrials, 1);
    predictedStim = zeros(totalNumTrials, 1);
    distances = zeros(4,1);
    count = 1;
    for stimNum = 1:4
        trialPoints = eggList{stimNum};
        for trialNum = 1:size(trialPoints, 1)
            for testCentroid = 1:4
               distances(testCentroid) = norm(trialPoints(trialNum,:) - centroids(testCentroid,:)); 
            end
            [closestDistance predictedNum] = min(distances);
            actualStim(count) = stimNum;
            predictedStim(count) = predictedNum;
            if predictedNum == stimNum 
               numCorrectPredictions = numCorrectPredictions + 1; 
            end
            count = count + 1;
        end
    end % stimNum
    percentCorrect = 100 * (numCorrectPredictions / totalNumTrials);
end