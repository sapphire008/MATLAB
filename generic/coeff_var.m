function c = coeff_var(x, dim)
if nargin<2
     dim = find(size(x)~=1,1);
end

if isempty(dim) || size(x, dim)<2
    c = 0;
else
    c = nanstd(x, [], dim)./(nanmean(x, dim));
end

end