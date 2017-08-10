function B = average_every_N(A, N, dim)
% Calculate avergae evrey N rows or columns for a matrix
%   B = average_every_N(A, N, dim)
%
% Inputs:
%   A: matrix
%   N: block size to average
%   dim: dimension. 1 for rows, 2 for columns.
%
% Output:
%   B: averaged matrix

if nargin<2, dim = 1; end
mat_size = size(A);
reshaped_size = [mat_size(1:dim-1), N, mat_size(dim)/N, mat_size(dim+1:end)];

B = reshape(A, reshaped_size);
B = squeeze(mean(B, dim));
end