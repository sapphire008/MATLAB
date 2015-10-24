function OPT = AFNI_3dDespike(P,Q,afnidir,varargin)
% MATLAB interface of AFNI's 3dDespike
%
%   AFNI_3dDespike(P,Q,afnidir,'opt1',val1,...)
% 
% Inputs:
%   P: full paths of images directory
%   Q: output directory
%   afnidir (optional): directory of AFNI
%
% Options of current function
%       Function Options     |    3dDespike Options    |     Default
%       'ignore'             :      '-ignore I'        :        0
%       'corder'             :      '-corder L'        :   numvols/30
%       'cut'                :      '-cut c1 c2'       :     [2.5,4.0]
%       'prefix'             :      '-prefix d'        :       'd'
%       'ssave'              :      '-ssave ttt'       :    not saving
%       'nomask'             :      '-nomask'          :       true
%       'dilate'             :      '-dilate nd'       :        4
%       'quiet'              :      '-q[uiet]'         :       true
%       'localedit'          :      '-localedit'       :       false
%       'NEW'                :      '-NEW'             :       true


% set up option dictionary
opt_name = {'ignore','corder','cut','prefix','ssave','nomask','dilate','quiet','localedit','NEW'};
opt_key = {'-ignore','-corder','-cut','-prefix','-ssave','-nomask','-dilate','-q','-localedit','-NEW'};
opt_val ={false,[],[],'d',[],true,[],true,false,true};
flag = sub_parse_opt_input(varargin,opt_name,opt_key,opt_val);

% convert options to strings
OPT = '';
FN = fieldnames(flag);
for n = 1:length(FN)
    if ~isempty(flag.(FN{n}).val)%value is not empty
        %logical value is not false
        if islogical(flag.(FN{n}).val) && flag.(FN{n}).val
            OPT = [OPT,flag.(FN{n}).key,' ']; %#ok<AGROW>
        elseif ~islogical(flag.(FN{n}).val)%assuming is corresponding input
            % make sure every thing is in string
            if isnumeric(flag.(FN{n}).val)
                flag.(FN{n}).val = num2str(flag.(FN{n}).val);
            end
            OPT = [OPT,flag.(FN{n}).key,' ',flag.(FN{n}).val,' ']; %#ok<AGROW>
        end
    end
end
clearvars opt* FN PATHSTR NAME;

end

%% sub-routines
function flag=sub_parse_opt_input(search_varargin_cell,name,key,val)
%convert everything into cell array if single input
if ~iscell(name)
    name={name};
end
if ~iscell(key)
    key = {key};
end
if ~iscell(val)
    val={val};
end

flag=struct();%place holding
for n = 1:length(name)
    % add in key of the dictionary
    flag.(name{n}).key = key{n};
    % parse values
    IND=find(strcmpi(name(n),search_varargin_cell),1);
    if ~isempty(IND)

        flag.(name{n}).val=search_varargin_cell{IND+1};
    else
        flag.(name{n}).val=val{n};
    end
end
end
