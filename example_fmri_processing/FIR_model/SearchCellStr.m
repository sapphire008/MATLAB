function result_struct = SearchCellStr(search_cell,search_by,return_type)
% result_struct = SearchCellstr(search_cell, search_by)
% search a cell array of strings inside search_cell, 
% for items specified by search_by
% returns in the index of each search_by in search_cell
% 
% Required Inputs:
%       search_cell: must be a cellarray of strings
%
%       search_by: can be either a cellstr or a string
%
% Optional Inputs:
%       return_logical: whether return number indices(0) or 
%                       logical indices (1)

% Inspect optional input(s)
if nargin<3
    return_logical = 0;
end

% making sure that search_by is a cellstr
search_by = cellstr(search_by);

result_struct = struct();
for n = 1:length(search_by)
    result_struct(n).search_name = search_by{n};
    result_struct(n).index = ~cellfun(@isempty, strfind(...
        search_cell,search_by{n}));
    if ~return_type
        result_struct(n).index = find(result_struct(n).index);
    end
end
end