function C = quick_replace_NaN(C, nan_char)
if nargin<2 || isempty(nan_char), nan_char = 'NaN';end
if ischar(nan_char), nan_char = {nan_char}; end
for r = 1:numel(C)
    if any(strcmpi(C{r}, nan_char))
        C{r} = NaN;
    end
end
end