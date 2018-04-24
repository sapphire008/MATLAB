function C = quick_replace_NaN(C, nan_char, replace_with)
if nargin<2 || isempty(nan_char), nan_char = 'NaN';end
if nargin<3 || isempty(replace_with), replace_with = NaN; end
if ischar(nan_char), nan_char = {nan_char}; end
for r = 1:numel(C)
    if any(strcmpi(C{r}, nan_char))
        C{r} = replace_with;
    end
end
end