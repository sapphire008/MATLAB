function [eggProp, allParms, colNames] = eggStats(realEgg)
    % revised 15 Jan 2015 BWS
    % trials as rows; eg 4x3 for 4 trials of a triple recording
    
    centroid = mean(realEgg,1);
    eggProp.numCells = size(realEgg, 2);
    eggProp.numNonZeroCells = sum(sum(abs(realEgg)) > 0);
    eggProp.numTrials = size(realEgg, 1);
    
    corrResult = corrcoef(realEgg);
    covResult = cov(realEgg);
    switch eggProp.numCells
	case 3
		trialCorr = [corrResult(2,3) corrResult(1,2) corrResult(1,3)];
		eggProp.R = sum(trialCorr) / 3;
		eggProp.R2 = sum(trialCorr .^ 2) / 3;
		trialCov = [covResult(2,3) covResult(1,2) covResult(1,3)];
		eggProp.Cov = sum(trialCov)/3;
	case 2
		eggProp.R = corrResult(1,2);
		eggProp.R2 = (corrResult(1,2)) ^ 2;
		eggProp.Cov = covResult(1,2);
	otherwise
		eggProp.R = nan;
		eggProp.R2 = nan;
		eggProp.Cov = nan;
    end
    
    for u = 1:size(realEgg,1)
       distancesToCentroid(u) = norm(realEgg(u,:) - centroid);
    end
    eggProp.centroid = centroid;
    eggProp.meanRate = mean(mean(realEgg));
    eggProp.magnitude = norm(realEgg);
    eggProp.distancesToCentroid = distancesToCentroid;
    eggProp.meanDistance = mean(distancesToCentroid);
    eggProp.sdDistance = std(distancesToCentroid);
    eggProp.cvDistance = std(distancesToCentroid) / mean(distancesToCentroid);
    eggProp.meanScaledDistance = eggProp.meanDistance / eggProp.meanRate;
    meanCell = mean(realEgg, 1); % the average of each cell's response in the egg
    eggProp.cellDist = abs(meanCell - mean(meanCell)); % all the L1 distances from the average for each cell
    eggProp.meanCellDist = mean(eggProp.cellDist); % measure of how variable the individual cells are
    eggProp.meanScaledCellDist = mean(eggProp.cellDist) / eggProp.meanRate;
    eggProp.cell1 = mean(realEgg(:,1));
    eggProp.cell2 = -1;
    eggProp.cell3 = -1;
    if eggProp.numCells > 1, eggProp.cell2 = mean(realEgg(:,2)); end
    if eggProp.numCells > 2, eggProp.cell3 = mean(realEgg(:,3)); end
    e = eggProp;
    allParms = [e.numTrials e.numCells e.meanRate e.magnitude e.meanDistance e.meanScaledDistance e.sdDistance e.cvDistance e.meanCellDist e. meanScaledCellDist e.R2 e.Cov e.cell1 e.cell2 e.cell3];
    colNames = {'numTrials' 'numCells' 'MeanRate' 'Magnitude' 'MeanDistance' 'meanScaledDistance' 'SDdistance' 'CVdistance' 'meanCellDist' 'meanScaledCellDist' 'R2' 'Cov' 'Cell1' 'Cell2' 'Cell3'};
end