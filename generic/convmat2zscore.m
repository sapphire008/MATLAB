function Z = convmat2zscore(M)
%convert entries of a matrix to z-scores, with mean of mean of the matrix,
%and std of std of the matrix
MU = nanmean(M(:));
SIGMA = nanstd(M(:));
Z = (M-MU)./SIGMA;
end