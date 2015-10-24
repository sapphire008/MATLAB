function U = rank_matrix_entries(X,MODE)
% U = rankd_matrix_entires(X,MODE)
% Rank the entries of matrix. If two or more entires have the same value,
% same rank will be given to these entries
% MODE = 'ascend'(default) or 'descend', see SORT

if nargin<2
    MODE = 'ascend';
end
%sort the number out
[Y,I] = sort(X(:),MODE);
%find repeats
[N,BIN] = hist(Y,unique(Y));

% give NaN numbers NaN rank
Z = [1:numel(Y)]';
Z(isnan(Y)) = NaN;

%give the same rank for identical numbers
K = BIN(N>1);
for n = 1:numel(K)
    Z(Y==K(n)) = min(Z(Y==K(n)));
end

%put it back to the form of X
U = zeros(size(X));
U(I) = Z;
end