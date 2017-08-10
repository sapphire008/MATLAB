function y = range(x,dim)
%RANGE  Sample range.

if nargin < 2
    y = max(x) - min(x);
else
    y = max(x,[],dim) - min(x,[],dim);
end
