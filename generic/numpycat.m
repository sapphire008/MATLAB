function A = numpycat(A,B,dim)
% Broadcast along singleton dimension
Asize=size(A);
Bsize=size(B);
A = repmat(A, Bsize);
B = repmat(B, Asize);
Asize=size(A);
if nargin<3
    dim = Asize(find(size(A)==1, 1));
A = cat(dim,A,B);
end