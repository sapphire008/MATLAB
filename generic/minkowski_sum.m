function S = minkowski_sum(X,Y)
% given rows of X and Y are observations
% S is a matrix of minkowski sums where S(1,2) corresponds to the sum of
% X(1) and Y(2)
S = NaN(numel(X),numel(Y));
for I = 1:length(X)
    for J = 1:length(Y)
        S(I,J) = X(I)+Y(J);
    end
end
end