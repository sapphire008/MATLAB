function create_SPM_jobs(job_dir, job_mode, varargin)
% create_SPM_jobs(job_dir, job_mode,[...Other required inputs...])
% 
% Required Inputs:
%   job_dir: job directory, string
%   job_mode: 1|2|3, ways to create job files. See following descriptions.
%
% There are three ways to create an SPM job file
% 
% Mode 1: Replace subject names and create new jobs with new subject names
%         in the same folder. In this case, use the following inputs:
%
%       create_SPM_jobs(job_dir, 1, job_ext, original_subject, subjects)
%         
%       *job_ext: job extension names, string; tells the function which 
%                 file to look for and save as. 
%                 Make sure append '.mat' at the end.
%       *original_subject: file names without extension, to be used as 
%                           template file. The template file name will be 
%                           like {original_subject}_{job_ext}.
%       *subjects: cell array of new file/subject names without extension.
%                  The new file names will be like {subjects}_{job_ext}.
%
% Mode 2: Replace strings in existing files, rename the old files as
%         "_old", move the old files into a folder named "old" under the
%         job directory, then create the new job files with strings
%         replaced. In this case, use the following inputs:
%          
%       create_SPM_jobs(job_dir, 2, job_names, original_str, new_str, ...)
%
%       *job_names: existing job names. The strings inside this job will be
%                   replaced, and new jobs will be saved exactly as this
%                   name. Must be cell array of strings.
%       *original_str: original_string to be replaced. Can be regular
%                      expression. See REGEXPREP for detail.
%       *new_str: new string to use. Must be a string, not a cellstr or
%                 cell array of strings.
%       *target_dir(Optional): specify a target directory where the new
%                              files will be saved. Default is the same
%                              directory as the job_dir
%       *append_name(Optional): instead of moving original file to the
%                               './old' directory, append a name
% 
%  Example regular expression string replacement
%       original_txt = 'vectors_run(\d*).mat';
%       new_txt = 'vectors_run$1_visual.mat';
% changes 'vectors_run1.mat' to 'vectors_run1_visual.mat'
%
% Mode 3: Change parameters of an existing job file (Not implemented)
%

% Edward DongBo Cui (cui23327@gmail.com) : 12/11/2013

switch job_mode
    case {1,'1'}
        create_job_mode_1(job_dir,varargin{1},varargin{2},varargin{3});
    case {2,'2'}
        %determine target directorystrrep
        if length(varargin)>=4 && ~isempty(varargin{4})
            target_dir = varargin{4};%use target_dir input
        else
            target_dir = job_dir;%no target_dir input
        end
        if length(varargin)>=5 && ~isempty(varargin{5})
            append_name = varargin{5};
        else
            append_name = '';
        end
        
        create_job_mode_2(job_dir,target_dir,varargin{1},varargin{2},...
            varargin{3},append_name);
    case {3,'3'}
        disp('This mode has not been implemented yet');
        
end
end

%% job mode selection
% create job with mode 1
function create_job_mode_1(job_dir,job_ext,original_subj,subjects)
for n = 1:length(subjects)
    %check if the file exists for string replacement
    tmp_dir = fullfile(job_dir,[subjects{n},'*',job_ext]);
    if isempty(tmp_dir)
        S = warning('QUERY','BACKTRACE');
        warning off backtrace;
        warning('File Does Not Exist:%s\n',fullfile(target_dir,files{n}));
        warning(S);
        continue;
    end
    %check if the file already existed
    if ~check_file_exist(fullfile(job_dir,tmp_dir))
        continue;
    end
    
    clear matlabbatch;
    load(fullfile(job_dir,[original_subj,job_ext]));
    matlabbatch=string_replace(matlabbatch,original_subj,subjects{n});
    %save file
    save(fullfile(job_dir,[subjects{n},job_ext]),'matlabbatch');
    disp(['Created SPM job: ', fullfile(job_dir,[subjects{n},job_ext])]);
end
end

% create job with mode 2
function create_job_mode_2(job_dir,target_dir,files,original_txt,new_txt,append_name)
for n = 1:length(files)
    %check if the file already existed
    if ~check_file_exist(fullfile(target_dir, files{n}))
        S = warning('QUERY','BACKTRACE');
        warning off backtrace;
        warning('File Does Not Exist:%s\n',fullfile(target_dir,files{n}));
        warning(S);
        continue;
    end
    clear matlabbatch EXT;
    %get file extension
    [~,NAME,EXT] = fileparts(fullfile(job_dir,files{n}));
    %load files
    load(fullfile(job_dir, files{n}));
    %string replace
    matlabbatch = string_replace(matlabbatch,original_txt,new_txt);
    if isempty(append_name)
        %make a directory for old files if not existing
        eval(['!mkdir -p ',fullfile(job_dir,'old')]);
        %move original file to /old folder as backup
        eval(['!mv ' fullfile(job_dir,files{n}),' ',...
            fullfile(job_dir,'old',[NAME,'_old',EXT])]);
    else
        files{n} = [NAME,append_name,EXT];
    end
    %save string replaced file
    save(fullfile(target_dir, files{n}), 'matlabbatch');
    disp(['Created SPM job: ', fullfile(target_dir, files{n})]);
end
end

% create job with mode 3
% %% batch change job file parameters
% subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP120_060513'};
% mask_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
% job_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/jobfiles/GLM/';
% ext = '_model_estimation.mat';
% for s = 1:length(subjects)
%     clear matlabbatch;
%     try
%         load([job_dir,subjects{s},ext]);
%     catch
%         disp(subjects{s});
%         continue;
%     end
%     matlabbatch{1,1}.spm.stats.fmri_spec.mask = cellstr([mask_dir,subjects{s},'_average_TR2_mask.nii']);
%     matlabbatch{1,3}.spm.stats.fmri_spec.mask = cellstr([mask_dir,subjects{s},'_average_TR2_mask.nii']);
%     eval(['!mv ',job_dir,subjects{s},ext, ' ',job_dir,subjects{s},'_backup.mat']);
%     %eval(['!rm ',job_dir,subjects{s},'.mat']);
%     save([subjects{s},ext], 'matlabbatch');
% end
%     
%% overwriting prompt
function overwrite = check_file_exist(file_dir)
if exist(file_dir,'dir')
    flag = input([file_dir, ' already exists. Replace? (Y/N)'], 's');
    switch flag
        case {'Y','y','yes'}
            overwrite = true;
        otherwise
            overwrite = false;
    end
else
    overwrite = 1;
end
end

%% string_replace function by Dennis Thompson
function new_struct = string_replace(old_struct, oldstr, newstr)
% new_struct = string_replace(old_struct, oldstr, newstr)
% string_replace -Does a recursive replacement of strings in a data structure
% It should work with char arrays, cell arrays, and structures
% In SPM can be used to modify SPM.mat files and job files
%
% new_struct = the data structure with strings replaced
% old_struct = the original data structure
% oldstr =  string to be replaced
% newstr = replacement string
% written Dennis Thompson, UCDavis Imaging Research Center, 07/23/2008

data_type = class(old_struct);

switch data_type        
    case 'cell' % if type is cell we need to do a recursion
        new_struct = expand_cell(old_struct, oldstr, newstr);  
        
    case 'struct' % if type is struct we need to do a recursion
        new_struct = expand_struct(old_struct, oldstr, newstr);
      
    case 'char' % if data type is char we can do the replacement
        new_struct = replace_string(old_struct, oldstr, newstr);
        
    otherwise  % if data type is "none of the above" we don't do anything
        new_struct = old_struct;
end
end

function new_struct = replace_string(old_struct, oldstr, newstr)
% this does the string replacement
[row,col] = size(old_struct);
% test empty array
if(~and(row,col)) new_struct = old_struct;
else
    for n = 1:row % I am assuming that the string are stored in a row vector :-)
        new_struct(n,:) = regexprep(old_struct(n,:), oldstr, newstr);
    end
end
end


function new_struct = expand_cell(old_struct, oldstr, newstr)
% this does the a series of recursive calls to expand the cell array
[row,col] = size(old_struct);
% check for zero arrays
if(~and(row,col)) new_struct = old_struct;
else
    for n = 1:row,
        for k = 1:col % recursive call
            new_struct{n,k} = string_replace(old_struct{n,k}, oldstr, newstr);
        end
    end
end
end


function new_struct = expand_struct(old_struct, oldstr, newstr)
% this does the a recursive call for each field in the structure
[row,col] = size(old_struct);
% check for zero arrays
if(~and(row,col)) new_struct = old_struct;
else
    for n = 1:row,
        for k = 1:col,
            names = fieldnames(old_struct(n,k));
            if isempty(names), new_struct(n,k) = old_struct(n,k);
            else
                for z = 1:length(names) % recursive call
                    new_struct(n,k).(names{z}) = string_replace(old_struct(n,k).(names{z}), oldstr, newstr);
                end
            end
        end
    end
end
end


    