function [source_files,target_folders,subset_func] = link_dicom_files(dicom_folder,source_item,dir_struct,tasks,subject,subset)
%####################################################################################
% DEBUG
% dicom_folder = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/dicoms/M3128_CNI_060314';
% source_item = '*.nii.gz';
% tasks = {'frac_back','mid','stop_signal','fullhead'};
% subject = 'M3128_CNI_060314';
% dir_struct = '/hsgs/projects/jhyoon1/midbrain_pilots/%s/subjects/funcs/%s/block%d/';
%####################################################################################
% set the subset variable
if nargin<6 || isempty(subset),subset = cell(1,length(tasks));end
% remove illegal characters before searching
tmp_tasks = regexprep(tasks,'\W','');
tmp_tasks = regexprep(tmp_tasks,'[_-]','');
tmp_items = dir(dicom_folder);
tmp_items = {tmp_items.name};
tmp_items = tmp_items(~cellfun(@isempty,cellfun(@(x) regexp(x,'\w'),tmp_items,'un',0)));
tmp_items = tmp_items(~strncmpi('.',tmp_items,1));
% assuming that the first numerics in the string specifies the order of the
% scan, ignoring the folders that did not have the numerics
ORDINAL = cellfun(@(x) regexp(x,'(^\d*)_','tokens'),tmp_items,'un',0);
tmp_items = tmp_items(~cellfun(@isempty,ORDINAL));
ORDINAL = cellfun(@(x) str2double(x{1}{1}),ORDINAL(~cellfun(@isempty,ORDINAL)));
[~,ORDINAL] = sort(ORDINAL);
tmp_items = tmp_items(ORDINAL);
% initialize
source_files = [];
target_folders = [];    
subset_func = [];
% loop through all the tasks
for t = 1:length(tasks)
    % get the folder of current task
    S = tmp_items(~cellfun(@isempty,cellfun(@(x) regexpi(x,tmp_tasks{t}),tmp_items,'un',0)));
    if isempty(char(S)),
        continue;%if not present, skip
    elseif numel(S)>1
        T = cellfun(@(x) sprintf(dir_struct,tasks{t},subject,x),num2cell(1:numel(S)),'un',0);
    else
        % destination folder
        % turn off block structure if only 1 block
        T = regexp(dir_struct,filesep,'split');
        T = T(~cellfun(@isempty,T));
        T = T(1:end-1);
        T = {sprintf(fullfile(filesep,T{:},filesep),tasks{t},subject)};
    end%
    S = cellfun(@(x) fullfile(dicom_folder,x),S,'un',0);
    S = cellstr(char(cellfun(@(x) char(SearchFiles(x,source_item)),S,'un',0)));
    % get rid of hidden files starting with .
    [~,NAME,~] = cellfun(@fileparts,S,'un',0);
    S = S(~strncmpi('.',NAME,1));
    % putting all the files and folders in a list
    source_files = [source_files;S];
    target_folders = [target_folders;T(:)];
    % subset of each source_files
    subset_func = [subset_func; repmat(subset(t),numel(S),1)];
end
end



%% Search Files
function [P,N] = SearchFiles(Path,Target)
% Routine to search for files with certain characteristic names. It does
% not search recursively. However, the function can search under multiple
% layers of sub-directories, when specifying Target variable in the format 
% *match1*/*match2*. Regular expression (regexp) is allowed.
%
% [P, N] = searchfiles(Path, Target)
%
% Inputs:
%       Path: path to search files in
%       Target: target file format, accept wildcards
%       IgnoreCase (optional): [true|false]. Default false
% 
% Outputs:
%       P: cellstr of full paths of files found
%       N: cellstr of names (without the path) of files found

if nargin<3,IgnoreCase = false;end
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
        [P,N] = cellfun(@dir_tree,P,repmat(targets(t),size(P)),'un',0);
        % unwrap the directories
        P = unwrap_cellstr(P);
        N = unwrap_cellstr(N);
        if counter(t)>0
            P = P(~cellfun(@isempty,regexp(N,original_targets{t})));
            N = N(~cellfun(@isempty,regexp(N,original_targets{t})));
        end
    catch ERR
        error('Cannot find the specified files\n');
    end
end
end

function [V,N] = dir_tree(P,T)
X = dir(fullfile(P,T));
if isempty(X)
    V = {};
    N = {};
    return;
end
N = {X.name};
clear X;
V = cellfun(@(x) fullfile(P,x),N,'un',0);
end

function C_out = unwrap_cellstr(C)
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
    C_out = unwrap_cellstr(C_out);
end
end