function [X, IND, ISOUTLIER] = remove_outlier_Rboxplot(X, dim)
% Used R's boxplot.stats method to remove outliers from X
% Requires statistics toolbox
% [Y, IND, ISOUTLIER] = remove_outlier_Rboxplot(X, dim)
%   X: a vector or matrix
%   dim: along which dimension
% Outputs:
%   Y: data after outlier removal
%   IND: index of which the retained data used to be in X, along dimension 
%        dim
%   ISOUTLIER: matrix the size as X, labeling outlier elements as 1's
%              and others as 0's, along dimension dim
if (nargin<2 || isempty(dim)) && ndims(X)>1, dim = 1; end
if ndims(X)==1
    Notches = [-1,1]*1.58*iqr(X) + median(X);
    X = X(X>=Notches(1) & X<=Notches(2));
    ISOUTLIER = (X<Notches(1) & X>Notches(2));
    IND = find(~ISOUTLIER);
else
    Notches_size = size(X);
    Notches_size = Notches_size(setdiff(1:ndims(X),dim));
    % find positive and negative notches
    Notches_pos = median(X,dim) + 1.58.*iqr(X,dim);
    Notches_neg = median(X,dim) - 1.58.*iqr(X,dim);
    % find index where X is either greater than positive notch or less
    % than negative notches
    ISOUTLIER = bsxfun(@gt,X,Notches_pos) | bsxfun(@lt, X,Notches_neg);
    IND = find(~any(reshape(ISOUTLIER,prod(Notches_size), size(X,dim)),1));
    % remove the outliers
    %shift dimension so that the dim will now be in the first dimension
    X = shiftdim(X,dim-1);
    X_size = size(X);
    X = X(IND,:);% X becomes 2D temporarily
    %reshape back to orginal number of dimensions
    X = reshape(X, [length(IND),X_size(2:end)]);
    %shift back to original dimension
    X = shiftdim(X,ndims(X)-dim+1);
end
end