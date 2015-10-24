function [P,V] = SearchFiles(Path,Target)
% Routine to search for files with certain characteristic names. It does
% not search recursively.
%
% [P, V] = searchfiles(Path, Target)
%
% Inputs:
%       Path: path to search files in
%       Target: target file format, accept wildcards
% 
% Outputs:
%       P: cellstr of full paths of files found
%       V: cellstr of names (without the path) of files found

X = dir(fullfile(Path,Target));
if isempty(X)
    P = {};
    V = {};
    return;
end
V = {X.name};
clear X;
P = cellfun(@(x) fullfile(Path,x),V,'un',0);
P = P(:);
end