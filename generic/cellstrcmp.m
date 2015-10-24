function S = cellstrcmp(STRING_CELL,EXPRESSION_CELL,ignorecase)
% S = cellregexp(STRING_CELL,EXPRESSION_CELL,OutputType,Ignorecase,Binary)
% cellstr version of strcmp, taking the combinations of STRING_CELL with
% EXPRESSION_CELL and compare them.
% Both STRING and EXPRESSION are now in cellstr, with length M and N
% respectively.
% The function will return a matrix with size MxN, where each row
% corresponds to STRING, and each column corresponds to EXPRESSION, so that
% position (m,n) shows the regular expression comparison between the m-th
% STRING and n-th EXPRESSIONS
%
% Inputs:
%       STRING_CELL: cellstr to be investigated
%       EXPRESSION_CELL: regular expression, see REGEXP
%       Ignorecase: [true|false] whether use regexp or regexpi
% 
% Output:
%       S:logical matrix of matches and non-matches, depending on the 
%         output type requested


% parsing inputs
if nargin<3 || isempty(ignorecase)
    ignorecase = false;
end

% determine if need to ignore case
switch ignorecase
    case 0
        fun_handle = @strcmp;
    case 1
        fun_handle = @strcmpi;
end

% place holding
S = zeros(numel(STRING_CELL),numel(EXPRESSION_CELL));

% transverse through
for m = 1:numel(STRING_CELL)
    for n = 1:numel(EXPRESSION_CELL)
        S(m,n)= fun_handle(STRING_CELL{m},EXPRESSION_CELL{n});
    end
end
end