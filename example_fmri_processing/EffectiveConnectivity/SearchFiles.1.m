function [P,N] = SearchFiles(Path,Target)
% Routine to search for files with certain characteristic names. It does
% not search recursively. However, the function can search under multiple
% layers of sub-directories, when specifying Target variable in the format 
% *match1*/*match2*. Regular expression (regexp) is allowed.
%
% [P, N] = searchfiles(Path, Target)
%
% Inputs:
%       Path: path to search files in
%       Target: target file format, accept wildcards
% 
% Outputs:
%       P: cellstr of full paths of files found
%       N: cellstr of names (without the path) of files found

% get a list of target directories and subdirectories
original_targets = regexp(Target,'/','split');
% remove regular expression
counter = zeros(1,numel(original_targets));
targets = original_targets;
for n = 1:length(targets)
    while true
        x = regexp(targets{n},'('); y = regexp(targets{n},')');
        if isempty(x) || isempty(y),break;end
        targets{n} = strrep(targets{n},targets{n}(x(1):y(1)),'*');
        counter(n) = counter(n)+1;
        if numel(counter)>1000,error('maximum iteration exceeded!');end
        pause(0.01);
    end
end
% addively add the result directories to the output
P = cellstr(Path);
for t = 1:length(targets)
    try
        % get the list of directories
        [P,N] = cellfun(@dir_tree,P,repmat(targets(t),size(P)),'un',0);
        % unwrap the directories
        P = unwrap_cellstr(P);
        N = unwrap_cellstr(N);
        if counter(t)>0
            P = P(~cellfun(@isempty,regexp(N,original_targets{t})));
            N = N(~cellfun(@isempty,regexp(N,original_targets{t})));
        end
    catch ERR
        error('Cannot find the specified files\n');
    end
end
end

function [V,N] = dir_tree(P,T)
X = dir(fullfile(P,T));
if isempty(X)
    V = {};
    N = {};
    return;
end
N = {X.name};
clear X;
V = cellfun(@(x) fullfile(P,x),N,'un',0);
end

function C_out = unwrap_cellstr(C)
C_out = [];
for n = 1:length(C)
    if ischar(C{n})
        C_out = [C_out,C(n)];
    elseif iscellstr(C{n})
        C_out = [C_out,C{n}];
    else
        C_out = [C_out,C{n}];
    end
end
% check if everything is cellstr now
TEST = cellfun(@iscellstr,C_out);
if any(TEST)
    C_out = unwrap_cellstr(C_out);
end
end