function C = cell2matnan(C)
% Pad nan for short arrays before converting to matrix
maxsize = cellfun(@size, C, 'un',0);
maxsize = cell2mat(maxsize(:));
if all(range(maxsize) == [0,0])
    C = cell2mat(C);
    return
else
    maxsize = max(maxsize,[], 1);
end

for c = 1:length(C)
    if all(size(C{c})== maxsize), continue; end
    tmp = nan(maxsize);
    [nrow, ncol] = size(C{c});
    tmp(1:nrow, 1:ncol) = C{c};
    C{c} = tmp;
end
C = cell2mat(C);
end