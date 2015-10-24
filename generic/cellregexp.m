function S = cellregexp(STRING_CELL,EXPRESSION_CELL,varargin)
% S = cellregexp(STRING_CELL,EXPRESSION_CELL,OutputType,Ignorecase,Binary)
% cellstr version of regular expression
% Both STRING and EXPRESSION are now in cellstr, with length M and N
% respectively
% The function will return a matrix with size MxN, where each row
% corresponds to STRING, and each column corresponds to EXPRESSION, so that
% position (m,n) shows the regular expression comparison between the m-th
% STRING and n-th EXPRESSIONS
%
% Inputs:
%       STRING_CELL: cellstr to be investigated
%       EXPRESSION_CELL: regular expression, see REGEXP
%       OutputType: See REGEXP for a list of output types
%       Ignorecase: [true|false] whether use regexp or regexpi
%       Binary: [true|false], return any matches with 1 and empty matches
%                with 0. If true, the returned S will be a logical array.
% 
% Output:
%       S: cell matrix of matches and non-matches, depending on the output
%           type requested


% parsing inputs
if isempty(varargin) || isempty(varargin{1})
    flag.outputtype = 'start';
else
    flag.outputtype = varargin{1};
end
if length(varargin)<2 || isempty(varargin{2})
    flag.ignorecase = false;
else
    flag.ignorecase = varargin{2};
end
if length(varargin)<3 || isempty(varargin{3})
    flag.binary = false;
else
    flag.binary = varargin{3};
end
% determine if need to ignore case
switch flag.ignorecase
    case 0
        fun_handle = @regexp;
    case 1
        fun_handle = @regexpi;
end

% place holding
S = cell(numel(STRING_CELL),numel(EXPRESSION_CELL));

% transverse through
for m = 1:numel(STRING_CELL)
    for n = 1:numel(EXPRESSION_CELL)
        S{m,n}= fun_handle(STRING_CELL{m},EXPRESSION_CELL{n},flag.outputtype);
    end
end

% check to see if return the result as a logical array
if flag.binary
    S = ~cellfun(@isempty,S);
end
end