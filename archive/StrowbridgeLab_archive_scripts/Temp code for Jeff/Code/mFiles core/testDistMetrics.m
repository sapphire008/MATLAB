function [meanICdist, maxDistPercent, maxDistToCentroidPercent] = testDistMetrics(centroids)
    % revised 17 Jan 2015 BWS
    % input is a 4x3 matrix with the four stim centroids over 3 rec cells
    centroidOfCentroids = mean(centroids,1);
    distToCentroids = zeros(1,4);
    for ii = 1:4
        distToCentroids(ii) = norm(centroids(ii,:) - centroidOfCentroids);
    end
    meanICdist = mean(distToCentroids);
    maxDistToCentroidPercent = 100 * (max(distToCentroids) / mean(distToCentroids));
    pTests = combnk([1 2 3 4], 2);
    ICdistDiff = zeros(1,6);
    for ii = 1:6
        t1 = pTests(ii,1); t2 = pTests(ii,2);
        ICdistDiff(ii) = norm(centroids(t1,:) - centroids(t2,:));
    end
    maxDistPercent = 100 * (max(ICdistDiff) / mean(ICdistDiff));
end