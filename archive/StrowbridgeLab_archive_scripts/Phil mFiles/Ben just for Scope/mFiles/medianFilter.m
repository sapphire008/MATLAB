function [newvec] = medianFilter(vec, size)

% Apply a median filter to vector VEC
%
% [NEWVEC] = APPLY_MEDIAN_FILTER(VEC)
%
% Replace each item with the median of itself and its two
% neighbors. For the first and last item, simply take the
% median of themselves and their only neighbor.


if ndims(vec)>2
  error('Cannot feed in n-dimensional matrices')
end

if min(size(vec))~=1
  error('VEC must be a vector')
end

newvec=medfilt1(vec,size);

