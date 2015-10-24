function [P,N,D,B] = SearchFiles(Path,Target,sortby)
% Routine to search for files with certain characteristic names. It does
% not search recursively. However, the function can search under multiple
% layers of sub-directories, when specifying Target variable in the format
% *match1*/*match2*. Regular expression (regexp) is allowed.
%
% [P, N, D, B] = SearchFiles(Path, Target, sortby)
%
% Inputs:
%   Path: path to search files in
%   Target: target file format, accept wildcards. Always use '/' for file
%           separator to avoid confusion with escape characters.
%   sortby: choose to sort the list of files by name ('N'[default]), 
%           date ('D'/'d'), or byte size ('B'/'b'). Capital letter for
%           ascending; lowercase letter for descending.
%
% Outputs:
%   P: cellstr of full paths of files found
%   N: cellstr of names (without the path) of files found
%   D: Datenum of the files. See DATESTR to convert to sensible strings.
%   B: Byte size of the files.
% 

if nargin<1, help(SearchFiles); end
% parse optional inputs
if nargin<3, sortby = 'N'; end

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
        [P,N,D,B] = cellfun(@dir_tree,P,repmat(targets(t),size(P)),'un',0);
        % unwrap the directories
        [P, N, D, B] = tupleApply(@unwrap_cell, P, N, D, B);
        if counter(t)>0
            KIND = ~cellfun(@isempty,regexp(N,original_targets{t}));
            [P, D, B] = tupleApply(@(x) x(KIND), P, D, B);
        end
    catch ERR % error occurred
        rethrow(ERR);
    end
end
[D, B] = tupleApply(@cell2mat, D, B);
% sorting result list
if double(sortby(1))>96, ascdesc = 'descend'; else ascdesc = 'ascend'; end
switch lower(sortby(1)) % for flexibility of input
    case 'n'
        if double(sortby(1))>96
            [P, N, D, B] = tupleApply(@(x) x(end:-1:1), P, N, D, B);
        end
    case 'd' % sort by datenum
        [D, IND] = sort(D, 2, ascdesc);
        [P, N, B] = tupleApply(@(x) x(IND), P, N, B);
    case 'b' % sort by byte size
        [B, IND] = sort(D, 2, ascdesc);
        [P, N, D] = tupleApply(@(x) x(IND), P, N, D);
    otherwise
        error('Unreocgnized sort option. See help documentation.');
end
end

function [V,N,D,B] = dir_tree(P,T)
X = dir(fullfile(P,T));
if isempty(X)
    [V, N, D, B] = tupleApply(@(x) x, {}, {}, {}, {});
    return;
end
N = {X.name};
D = {X.datenum}; % time of creation
B = {X.bytes}; % file size
clear X;
V = cellfun(@(x) fullfile(P,x),N,'un',0);
end

function C_out = unwrap_cell(C)
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
    C_out = unwrap_cell(C_out);
end
end

function varargout = tupleApply(fhandle, varargin)
% apply function as if a Python tuple
% [A,B,C,...] = tupleApply(fhandle, X, Y, Z, ...)
% where fhandle is a handle of a function that has only a single input and
% a single output
varargout = cellfun(fhandle, varargin, 'un',0);
end