function outStr = varStats(inVector, flag)
    % revised 23 Oct 2014 BWS
    precision = '%.4G';
    if nargin == 1
        flag = '';
    end
    outStr = [inputname(1) ': '];
    inVector = inVector(:);
    SEM = num2str(std(inVector) / sqrt(size(inVector,1)), precision);
    sd = num2str(std(inVector), precision);
    cv = num2str(std(inVector)/mean(inVector), precision);
    outStr = [outStr num2str(mean(inVector), precision) ' +/- ' SEM ' SD: ' sd ' CV: ' cv];
    if strcmpi(flag, 'LONG') % i at end means case does not matter
        skew = num2str(skewness(inVector), precision);
        kur = num2str(kurtosis(inVector), precision);
        med = num2str(median(inVector), precision);
        outStr = [' skew: ' skew ' kurtosis: ' kur ' median: ' med];
    end
    outStr = [outStr ' (N = ' num2str(size(inVector,1)) ')'];
end