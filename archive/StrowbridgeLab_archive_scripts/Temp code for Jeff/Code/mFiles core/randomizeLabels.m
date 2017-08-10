function [newArray1, newArray2] = randomizeLabels(array1, array2)
    % revised 19 Sept 2014 BWS for poly3
   
    allTrials = [array1;array2];
    newTrials = allTrials(randperm(size(allTrials,1)),:);
    newArray1 = newTrials(1:size(array1,1),:);
    newArray2 = newTrials(1+size(array1,1):end,:);
end