function neocorticalEggStats(pprArray, startSec, durSec, testName, numBootstrapRuns)
    % revised 2 Feb 2015 BWS example down script
    
    % test names can be: LDA kNN2 kNN3 kNN4 NearestCentroids
    timeStamp = [mfilename '.m on ' getComputerName() ' (' datestr(now,'dd mmm yyyyHH:MM PM') ')'];
    disp(timeStamp);
    stopSec = startSec + durSec;
    accuracy = zeros(1,6); % six numbers because there are six pairwise comparisons to test
    randAccuracy = zeros(1,6);
    pValues = zeros(1,6);
    eggA = makeEgg(pprArray, 'A', startSec, stopSec, 0, 0);
    eggB = makeEgg(pprArray, 'B', startSec, stopSec, 0, 0);
    eggC = makeEgg(pprArray, 'C', startSec, stopSec, 0, 0);
    eggD = makeEgg(pprArray, 'D', startSec, stopSec, 0, 0);
    [accuracy(1), randAccuracy(1), pValues(1)] = helperGetAcc(eggA, eggB, testName, numBootstrapRuns);
    [accuracy(2), randAccuracy(2), pValues(2)] = helperGetAcc(eggA, eggC, testName, numBootstrapRuns);
    [accuracy(3), randAccuracy(3), pValues(3)] = helperGetAcc(eggA, eggD, testName, numBootstrapRuns);
    [accuracy(4), randAccuracy(4), pValues(4)] = helperGetAcc(eggB, eggC, testName, numBootstrapRuns);
    [accuracy(5), randAccuracy(5), pValues(5)] = helperGetAcc(eggB, eggD, testName, numBootstrapRuns);
    [accuracy(6), randAccuracy(6), pValues(6)] = helperGetAcc(eggC, eggD, testName, numBootstrapRuns);
    tempStr = ['Mean accuracy: ' num2str(mean(accuracy)) ' Rand acc: ' num2str(mean(randAccuracy))];
    tempStr = [tempStr ' NumPlanes: ' num2str(sum(pValues < 0.05))];
    disp(tempStr);
    % plotEggs(60, eggA, eggB, eggC, eggD);
end

function [realAcc, randAcc, pValue] = helperGetAcc(egg1, egg2, testName, numBootstrap)
    [realAcc, distFromPlane] = decodeTwoEggs(egg1, egg2, testName);
    tempAcc = zeros(1,numBootstrap);
    for ii = 1:numBootstrap
       [newArray1, newArray2] = randomizeLabels(egg1, egg2);
       [tempAcc(ii), distFromPlane] = decodeTwoEggs(newArray1, newArray2, testName);
    end
    randAcc = mean(tempAcc);
    pValue = sum(tempAcc >= realAcc) / numBootstrap;
end