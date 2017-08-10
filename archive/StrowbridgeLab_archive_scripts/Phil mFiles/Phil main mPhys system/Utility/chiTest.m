function pVal = chiTest(cT)
% computes a chi-squared from a 2x2 contingency table cT
%               Dead 	 Alive 	Total
%  Treated      36      14      50
%  Not treated 	30      25      55
%  Total        66      39      105

for i = 1:2
    for j = 1:2
        if cT(i,j) == 0
            cT(i,j) = 0.001;
        end
    end
end    

chiSquared = ((cT(1,1) * cT(2,2) - cT(1,2) * cT(2,1))^2 * sum(sum(cT))) / ((cT(1,1) + cT(1,2)) * (cT(2,1) + cT(2,2)) * (cT(1,2) + cT(2,2)) * (cT(1,1) + cT(2,1)));

% n = (size(cT, 1) - 1) * (size(cT, 2) - 1);
% chiSquared = 0;
% for cellIndex = 1:prod(size(cT))
%     chiSquared = chiSquared + (observed - expected) ^ 2 / expected
% end

pVal = 1 - chi2cdf(chiSquared,1);