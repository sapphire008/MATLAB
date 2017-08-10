function [pairProp, allParms, colNames] = eggPairStats(egg1, egg2)
    % revised 15 Jan 2015 BWS
    [eggProp1, ~, ~] = eggStats(egg1);
    [eggProp2, ~, ~] = eggStats(egg2);
    [ICdistance, ICangle, magDifference, ~] = compareEggs(egg1, egg2);
    pairProp.meanRate = mean([eggProp1.meanRate eggProp2.meanRate]);
    pairProp.ICdistance = ICdistance;
    pairProp.ICangle = ICangle;
    pairProp.magDifference = magDifference;
    pairProp.deltaScaledDist = abs(eggProp1.meanScaledDistance - eggProp2.meanScaledDistance);
    pairProp.deltaScaledCellDist = abs(eggProp1.meanScaledCellDist - eggProp2.meanScaledCellDist);
    pairProp.deltaRate = abs(eggProp1.meanRate - eggProp2.meanRate);
    pairProp.maxCell1 = max([mean(egg1(:,1)) mean(egg2(:,1))]);
    pairProp.maxCell2 = -1;
    pairProp.maxCell3 = -1;
    if size(egg1,2) > 1, pairProp.maxCell2 = max([mean(egg1(:,2)) mean(egg2(:,2))]); end
    if size(egg1,2) > 2, pairProp.maxCell3 = max([mean(egg1(:,3)) mean(egg2(:,3))]); end
    e = pairProp;
    allParms = [e.magDifference e.deltaRate e.meanRate e.ICdistance e.ICangle e.deltaScaledDist e.deltaScaledCellDist e.maxCell1 e.maxCell2 e.maxCell3];
    colNames = {'deltaMag' 'deltaRate' 'meanRate' 'ICdist' 'ICangle' 'deltaScaledDist' 'deltaScaledCellDist' 'maxCell1' 'maxCell2' 'maxCell3'};
end