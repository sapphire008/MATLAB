function outStr = ttestUnpaired(vec1, vec2, flag)
    % revised 9 Oct 2014 BWS
    precision = '%.4G';
    outStr = ['Unpaired t-test: ' inputname(1) ' vs ' inputname(2) ' - pValue: '];
    a1 = vec1(:);
    a2 = vec2(:);
    if nargin < 3
       flag = ''; 
    end
    varMethod = 'Unequal';
    if strcmpi(flag, 'EQUAL')
       varMethod = 'equal';
    end
    if strcmpi(flag, 'UNEQUAL')
       varMethod = 'unequal'; 
    end
    [h, p, ci, stats] = ttest2(a1, a2, 'Vartype', varMethod);
    outStr = [outStr num2str(p) ' DF: ' num2str(stats.df, precision) ' tStat: ' num2str(stats.tstat, precision) ' varMode: ' varMethod];
end