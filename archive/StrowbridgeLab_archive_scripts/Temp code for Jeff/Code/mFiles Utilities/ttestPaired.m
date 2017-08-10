function outStr = ttestPaired(vec1, vec2)
    % revised 9 Oct 2014 BWS
    precision = '%.4G';
    outStr = ['Paired t-test: ' inputname(1) ' vs ' inputname(2) ' - pValue: '];
    a1 = vec1(:);
    a2 = vec2(:);
    if numel(a1) ~= numel(a2)
        disp('Cannot used unpaired t-test with different sized arrays')
        outStr = '';
    else
        [h, p, ci, stats] = ttest(a1, a2);
        outStr = [outStr num2str(p) ' DF: ' num2str(stats.df, precision) ' tStat: ' num2str(stats.tstat, precision)];
    end
end