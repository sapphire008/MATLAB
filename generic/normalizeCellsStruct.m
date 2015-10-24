function CS = normalizeCellsStruct(CS)
% Normalize a cell array of structures. Filling in missing fields, and
% convert it to an array of structures.

% Get a union of the fields
F = cellfun(@fieldnames, CS, 'un',0);
% Try to see if we can convert it to structure array if the number of
% fields are all the same
if range(cellfun(@(x) numel(x), F)) == 0
    try
        CS = cell2mat(CS);
        return;
    catch
    end
end
% if not working, do the hard work
F = strunion(F{:});
% Transverse to fix all the fields
for n = 1:length(CS)
    for m = 1:length(F)
        if ~isfield(CS{n},F{m})
            CS{n}.(F{m}) = [];
        end
    end
    % make sure all of structures are in the same order
    CS{n} = orderfields(CS{n});
end
% try to convert again
CS = cell2mat(CS);
end

function U = strunion(varargin)
% input a list of cell arrays (double cell arrays) of strings and get
% the unique union
%   U = strunion(A,B,C,D,...)
% where A, B, C, D are cellstr
if ~all(cellfun(@(x) iscellstr(x), varargin))
    error('Some inputs are not cell string');
end
if nargin<2, U = unique(varargin{1}); return; end
U = [];
for n = 1:length(varargin)
    U = [U; varargin{n}(:)];
end
U = unique(U);
end