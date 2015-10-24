function H = FSL_split_nii(P,Q,fsldir,varargin)
% Use FSL's functions fslmerge and fslsplit to archive NIfTI files

% get list of file in the current directory
list_files_before = dir(Q);
list_files_before = cellfun(@(x) fullfile(Q,x),{list_files_before.name},'un',0);
opt_name = {'basename','deletesource'};
opt_key = {'',''};
opt_val = {'vol',false};
flag = sub_parse_opt_input(varargin,opt_name,opt_key,opt_val);
% get output names
if ischar(flag.basename.val)
    if ~isempty(flag.basename.val)
        ARG = [char(P),' ',fullfile(Q,flag.basename.val)];
    else
        ARG = [char(P),' ',Q,filesep];
    end
else
    ARG = [char(P),' ',Q,filesep];
end
% call fslsplit
[status,result] = call_fsl(fsldir,[fullfile(fsldir,'bin','fslsplit'),' ',ARG],'NIFTI');
% get list of file in the after fslsplit
list_files_after = dir(Q);
list_files_after = cellfun(@(x) fullfile(Q,x),{list_files_after.name},'un',0);
% get the list of resulted files
H = list_files_after(cell2mat(cellfun(@(x) ~ismember(...
    x,list_files_before),list_files_after,'un',0)));
clear list_files_before list_files_after;
% rename the output if the numbering starts at 0
K = regexp(H,fullfile(Q,[flag.basename.val,'(\d*)','.nii']),'tokens');
K = cellfun(@(x) x{1}{1},K,'un',0);
if str2num(K{1}) == 0
    K = cellfun(@(x) fullfile(Q,sprintf('%s%04.f.nii',...
        flag.basename.val,str2num(x)+1)),K,'un',0);
    for k = length(K):-1:1
        eval(['!mv ',H{k},' ',K{k}]);
    end
    H = K;
end
clear K;

% check successful run
if status || numel(result)>=10
    disp(result);
    return;
end
% delete source
if flag.deletesource.val
    cellfun(@delete,P);
end
end

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