function k = getindexblock(t, returnarray)
% Given block index, return the start and the end of the block
% e.g. t = [ones(1,3), 2*ones(1,4), 3*ones(1,2)];
% return [1,3; 4,7; 8,9]
% if returnarray is true
% return {1:3, 4:7, 8:9};
if nargin<2 || isempty(returnarray)
    returnarray = false;
end
[~, k, ~] = unique(t);
k0 = [k(2:end)-1; length(t)];
k = [k, k0];
k0 = cell(size(k, 1), 1);
if returnarray
    for n = 1:length(k0)
        k0{n} = k(n, 1):k(n,2);
    end
    k = k0;
end
end