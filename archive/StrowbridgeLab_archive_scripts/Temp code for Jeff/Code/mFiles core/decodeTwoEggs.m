function [accuracy, distFromPlane] = decodeTwoEggs(egg1, egg2, testName)
    switch 1 % test against true
        case strcmpi(testName, 'LDA')
            [accuracy, distFromPlane, constantTerm, coefTerms] = polyLDA(egg1, egg2);
        case strcmpi(testName, 'NearestCentroid')
            [accuracy, distFromPlane, correct1or0] = nearestCentroid(egg1, egg2);
        case strcmpi(testName(1:3), 'kNN')
            kN = str2double(testName(4:end));
            [accuracy, corr] = kNNpairwise(egg1, egg2, kN);
            distFromPlane = corr; % to make return signature consistent
        otherwise
            error(['Unknown test name: ' testName]);
    end
end