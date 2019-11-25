function block_apply_func(X, vec, dim)
if nargin < 3, dim = 1; end
func = @mean;
% X: matrices to apply function over
% vec indicates grouping. Its length must equal to the size(X, dim).
% dim: dimension to apply the function over. Default dim=1
% func: function to apply over. Default is @mean
X = Rin_mat; % 72 x 10
vec = [1,1,1,2,2,2,3,3,3,4]; % 1 x 10
dim = 2;

[~,~ ,vec] = unique(vec);
Y_out = {};
for v = unique(vec)
    index = find(vec == v);
    sz = size(X);
    ndim = ndims(X);
    inds = repmat({1}, 1, ndim);
    for k = 1:ndim
        if k == dim
            inds{k} = index;
        else
            inds{k} = 1:sz(k);
        end
    end
    % Get the subset
    Y = X(inds{:});
    % Apply the function
    Y_out{end+1} = mean(Y, dim);
    
end
end