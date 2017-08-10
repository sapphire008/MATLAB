function [accuracy distFromPlane correct1or0] = nearestCentroid(array1, array2)
    % revised 7 Jan 2015 BWS for Poly3
    % input arrays should be rows as trials
    
    junk1 = 0;
    junk2 = 0;
    numGuesses = 0;
    numCorrectPredictions = 0;
    distances = zeros(2,1);
    distFromPlane = zeros(size(array1,1) + size(array2,1), 1);
    correct1or0 = distFromPlane;
    numCells = size(array1,2);
    centroids = zeros(2, numCells);
    centroids(1,:) = mean(array1);
    centroids(2,:) = mean(array2);
    
    numTrials = size(array1,1);
    for i = 1:numTrials
        numGuesses = numGuesses + 1;
        distances(1,1) = norm(array1(i,:) - centroids(1,:));
        distances(2,1) = norm(array1(i,:) - centroids(2,:));
        [closestDistance, predictedIndex] = min(distances);
        if predictedIndex == 1
           numCorrectPredictions = numCorrectPredictions + 1; 
           sign = 1;
           correct1or0(numGuesses) = 1;
        else
           sign = -1;
        end
        distFromPlane(numGuesses,1) = sign * (abs(closestDistance));
    end
    numTrials = size(array2,1);
    for i = 1:numTrials
        numGuesses = numGuesses + 1;
        distances(1,1) = norm(array2(i,:) - centroids(1,:));
        distances(2,1) = norm(array2(i,:) - centroids(2,:));
        [closestDistance, predictedIndex] = min(distances);
        if predictedIndex == 2
           numCorrectPredictions = numCorrectPredictions + 1; 
           sign = -1;
           correct1or0(numGuesses) = 1;
        else
           sign = 1;
        end
        distFromPlane(numGuesses,1) = sign * (abs(closestDistance));
    end
    accuracy = 100 * (numCorrectPredictions / numGuesses);
end