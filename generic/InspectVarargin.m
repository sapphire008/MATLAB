function [flag,ord]=InspectVarargin(varargin_cell,varargin)
% Inspect whether there is a keyword input in varargin, else return
% default. If search for multiple keywords, input both keyword and
% default_value as a cell array of the same length.
% If length(keyword)>1, return flag as a structure
% else, return the value of flag without forming a structure
%
% [flag,ord]=InspectVarargin(varargin_cell,{k1,v1},...)
%
% Inputs:
% varargin_cell: varargin cell
% keyword (k): flag names
% default_value (v): default value if there is no input
% Input as many pairs of keys and values
%
% Outputs:
% flag: structure with field names identical to that of keyword
% ord: order of keywords being input in the varargin_cell. ord(1)
% correspond to the index of the keyword that first appeared in the
% varargin_cell
%
%
% Edward Cui. Last modified 12/13/2013
%
% reorganize varargin of current function to keyword and default_value
keyword = cell(1,length(varargin));
default_val = cell(1,length(varargin));
for k = 1:length(varargin)
    keyword{k} = varargin{k}{1};
    default_val{k} = varargin{k}{2};
end
% check if the input keywords matches the list provided
NOTMATCH = cellfun(@(x) find(~ismember(x,keyword)),varargin_cell(1:2:end),'un',0);
NOTMATCH = ~cellfun(@isempty,NOTMATCH);
if any(NOTMATCH)
    error('Unrecognized option(s):\n%s\n',...
        char(varargin_cell(2*(find(NOTMATCH)-1)+1)));
end
%place holding
flag=struct();
ord = [];
% assuming the structure of varargin_cell is {'opt1',val1,'opt2',val2,...}
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_val{n};
    end
end
%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end
end
