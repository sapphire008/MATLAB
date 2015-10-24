function [EXIST,PASS] = check_model_items_exist(matlabbatch,verbose)
% Check all fields of fMRI model specification exists before running the
% model.
%
% Input:
%       matlabbatch: matlabbatch structure of the fMRI model specification 
%               job or the path to that job file
%       verbose (optional): display results. Default true.
%
% Output:
%
%       EXIST: structure that contains the queries of each occurence of 
%              fMRI model specification job
%       PASS: list of pass/fail for each job. If all criteria met for 
%             current job, score as true, otherwise, false. Has the same
%             length as EXIST.

% load job file
if ischar(matlabbatch),load matlabbatch;end
if nargin<2 || isempty(verbose),verbose = true;end
% find which ones correspond to fMRI model specification
EXIST = struct('Output_Directory',[],'Output_Has_Files',[],...
    'Scan_Data',[],'Non_Existing_Scan_Data',[],'Multi_Conditions',[],...
    'Non_Existing_Multi_Conditions',[],'Multi_Regressors',[],...
    'Non_Existing_Multi_Regressors',[]);
PASS = true;
n = 0;
for m = 1:length(matlabbatch)
    % check if current cell contains fMRI model specification
    [TF, S] = myfieldexist(matlabbatch{m},'spm.stats.fmri_spec');
    if ~TF, continue; else n = n+1;end
    % check dir
    EXIST(n).Output_Directory = exist(char(S.dir),'file') | exist(char(S.dir),'dir');
    if ~EXIST(n).Output_Directory && verbose
        fprintf('Output directory %s does not exist\n',char(S.dir));
        EXIST(n).Output_Has_Files = -1;
    else
        % check if dir already contains models
        tmp = dir(char(S.dir)); 
        tmp = tmp(strcmpi('.',{tmp.name}) & strcmpi('..',{tmp.name}));
        EXIST(n).Output_Has_Files = ~isempty(tmp);
        clear tmp;
    end
    if EXIST(n).Output_Has_Files>0 && verbose
        fprintf('Output directory %s contains files\n',char(S.dir));
    end
    % check raw functional images
    Scans = cellfun(@remove_suffix,cellstr(char(cellfun(@char,{S.sess.scans},'un',0))),'un',0);
    EXIST(n).Scan_Data = cellfun(@(x) exist(x,'file'),Scans);
    EXIST(n).Non_Existing_Scan_Data = Scans(EXIST(n).Scan_Data==0);
    if ~all(EXIST(n).Scan_Data) && verbose
        disp('None-Exiting Scans: ');
        disp(char(EXIST(n).Non_Existing_Scan_Data));
    end
    clear Scans;
    %check behave regressors
    Behaves = cellfun(@remove_suffix,cellstr(char(cellfun(@char,{S.sess.multi},'un',0))),'un',0);
    EXIST(n).Multi_Conditions = cellfun(@(x) exist(x,'file'),Behaves);
    EXIST(n).Non_Existing_Multi_Conditions = Behaves(EXIST(n).Multi_Conditions==0);
    if ~all(EXIST(n).Multi_Conditions) && verbose
        disp('None-Exiting Multi Conditions: ');
        disp(char(EXIST(n).Non_Existing_Multi_Conditions));
    end
    clear Behaves;
    %check regressors
    Regressors = cellfun(@remove_suffix,cellstr(char(cellfun(@char,{S.sess.multi_reg},'un',0))),'un',0);
    EXIST(n).Multi_Regressors = cellfun(@(x) exist(x,'file'),Regressors);
    EXIST(n).Non_Existing_Multi_Regressors = Regressors(EXIST(n).Multi_Regressors==0);
    if ~all(EXIST(n).Multi_Regressors) && verbose
        disp('None-Exiting Regressors: ');
        disp(char(EXIST(n).Non_Existing_Multi_Regressors));
    end
    % check mask
    if isempty(S.mask)
        EXIST(n).Mask = -1;
        if verbose,disp('No mask specified ...');end
    else
        EXIST(n).Mask = exist(remove_suffix(S.mask{:}),'file');
        if ~EXIST(n).Mask && verbose
            fprintf('Mask file: %s does not exist\n',remove_suffix(S.mask{:}));
        end
    end
    % check to see if all criteria passed
    PASS(n) = true & EXIST(n).Output_Directory & all(EXIST(n).Scan_Data) ...
        & all(EXIST(n).Multi_Conditions) & all(EXIST(n).Multi_Regressors)...
        & EXIST(n).Mask;
end
if isempty(EXIST(1).Output_Directory)
    warning('The specified matlabbatch does not contain fMRI specification jobs');
    fprintf('\n');
end
end

function [TF,S] = myfieldexist(S,F)
%check if my field names exist
if isempty(S)
    TF = false;
    S = [];
    return;
end
F = regexp(F,'(\.)','split');
TF = 1;
for n = 1:length(F)
    TF = TF & isfield(S,F{n});
    if TF == 1
        S = S.(F{n});
    else
        S = [];
        return;
    end
end
TF = TF & ~isempty(S);
end

function C = remove_suffix(C)
% remove the ,1 suffix from spm_select
[PATHS,NAME,EXT] = spm_fileparts(C);
C = fullfile(PATHS,[NAME,EXT]);
end