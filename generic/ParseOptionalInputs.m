function [flag,ord]=ParseOptionalInputs(varargin_cell,keyword,default_value)
% Inspect whether there is a keyword input in varargin, else return 
% default. If search for multiple keywords, input both keyword and 
% default_value as a cell array of the same length.
% If length(keyword)>1, return flag as a structure
% else, return the value of flag without forming a structure
%
% [flag,ord] = ParseOptionalInputs(varargin_cell,keyword, default_value)
% 
% Inputs: 
%   varargin_cell: varargin cell
%   keyword: flag names
%   default_value: default value if there is no input
%
% Outputs:
%   flag: structure with field names identical to that of keyword
%   ord: order of keywords being input in the varargin_cell. ord(1)
%        correspond to the index of the keyword that first appeared in the
%        varargin_cell
%
%
% Edward Cui. Last modified 12/13/2013
% 

%flag unbalanced input 
if length(keyword)~=length(default_value) 
    error('keyword and default_value must be the same length');
end

%convert everything into cell array if single input
if ~iscell(keyword)
    keyword={keyword};
end
if ~iscell(default_value)
    default_value={default_value};
end

%place holding
flag=struct();
ord = [];

% assuming the structure of varargin_cell is {'opt1',val1,'opt2',val2,...}
for n = 1:2:length(varargin_cell)
    IND = find(strcmpi(varargin_cell(n),keyword),1);
    if ~isempty(IND)
        flag.(keyword{IND}) = varargin_cell{n+1};
        ord = [ord, IND];
    else
        flag.(keyword{IND}) = default_value{IND};
    end
end

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end

end
