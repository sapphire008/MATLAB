function [V,N] = dir_tree(P,T)
X = dir(fullfile(P,T));
if isempty(X)
    V = {};
    return;
end
N = {X.name};
clear X;
V = cellfun(@(x) fullfile(P,x),N,'un',0);
end