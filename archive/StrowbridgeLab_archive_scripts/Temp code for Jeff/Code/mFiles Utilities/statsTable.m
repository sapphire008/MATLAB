function outStr = statsTable(inTable, colNames)
    % revised 7 Jan 2015 BWS
    precisionStr = '%.4G';
    numVectors = numel(colNames);
    lf = 10;
    outStr = '';
    for i = 1:numVectors
        tempVec = table2array(inTable(:, colNames{i}));
        outStr = [outStr lf helperVarStats(tempVec, colNames{i}, precisionStr)];
    end
end

function outStr = helperVarStats(inVec, dispName, precision)
    inVector = inVec(:);
    outStr = [dispName ': '];
    SEM = num2str(std(inVector) / sqrt(size(inVector,1)), precision);
    cv = num2str(std(inVector)/mean(inVector), precision);
    outStr = [outStr num2str(mean(inVector), precision) ' +/- ' SEM ' CV: ' cv];
    outStr = [outStr ' (N = ' num2str(size(inVector,1)) ')'];
end