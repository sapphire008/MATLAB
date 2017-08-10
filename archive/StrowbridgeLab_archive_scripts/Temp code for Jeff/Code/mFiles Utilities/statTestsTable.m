function outStr = statTestsTable(inTable, colNames, pairedOrUnpaired, optionalFlag)
    % revised 7 Jan 2015 BWS
    precisionStr = '%.4G';
    if nargin == 3
        optionalFlag = '';
    end
    varMethod = 'unequal';
    if strcmpi(optionalFlag, 'EQUAL')
       varMethod = 'equal';
    end
    desc = inTable.Properties.Description;
    numVectors = numel(colNames);
    lf = 10;
    outStr = ['Statistics for: ' inputname(1)];
    outStr = [outStr lf inTable.Properties.Description];
    pairwiseTests = combnk(colNames,2);
    for test = 1:size(pairwiseTests,1)
        vec1name = pairwiseTests{test,1};
        vec2name = pairwiseTests{test,2};
        tempStr = ['  ' vec1name ' vs ' vec2name ': '];
        if strcmpi(pairedOrUnpaired, 'paired') == 1
           [h, p, ci, stats] = ttest(table2array(inTable(:,vec1name)), table2array(inTable(:,vec2name)));
           tempStr = [tempStr num2str(p) ' DF: ' num2str(stats.df, precisionStr) ' tStat: ' num2str(stats.tstat, precisionStr)]; 
           lastTest = 'paired t-test';
        else
           [h, p, ci, stats] = ttest2(table2array(inTable(:,vec1name)), table2array(inTable(:,vec2name)), 'Vartype', varMethod);
           tempStr = [tempStr num2str(p) ' DF: ' num2str(stats.df, precisionStr) ' tStat: ' num2str(stats.tstat, precisionStr)];
           lastTest = ['unpaired t-test (' varMethod ' variance)'];
        end
        outStr = [outStr lf tempStr];
    end
    outStr = [outStr lf '     ' lastTest ' on ' getComputerName() ' (' datestr(now,'dd mmm yyyyHH:MM PM') ')'];
end
