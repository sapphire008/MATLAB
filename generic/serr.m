function s = serr(x, dim)
% generic / custom function: standard error of vector x
% can handle NaNs
if nargin<2
     dim = find(size(x)~=1,1);
end

if isempty(dim) || size(x, dim)<2
    s = 0;
else
    s = nanstd(x, [], dim)./sqrt(sum(~isnan(x), dim));
end
end