%% varargin input
function [flag,key,ind] = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1','key1'}.
% returns structure of flag and key with each option name, e.g. 'opt1' as
% field names
% also returns ind variable, which specifies the index mapping between
% options and varargin
flag = struct();%place holding
key = struct();%place holding
ind = [];
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
        ind = [ind, 2*find(tmp,1) + [-1,0]];
    else
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    if numel(varargin{n})>2
        key.(varargin{n}{1}) = varargin{n}{3};
    else
        key.(varargin{n}{1}) = [];
    end
    clear tmp;
end
ind = sort(ind);
end