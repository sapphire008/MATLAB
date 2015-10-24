function setup_risscon_second_level_analysis_stopsignal(source_image_label)

% HELP DOCUMENT:
% Create and run second level analyses for Rissman Connecitivity
% For Non-paried T-Test, Group 1 is patient, and Group2 is Control


%addspm8;
clc;
%clear
fMRI_pipeline = addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/second_level_analysis/;

subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};
condnames = {'SNleft_GO-null','SNleft_GO_ERROR-null','SNleft_StopInhibit-null',...
    'SNleft_StopRespond-null','SNleft_StopInhibit-GO','SNleft_StopRespond-GO',...
    'SNleft_StopInhibit+StopRespond-null','SNleft_StopInhibit+StopRespond-GO',...
    'SNleft_All_Conditions-null','STNleft_GO-null','STNleft_GO_ERROR-null',...
    'STNleft_StopInhibit-null','STNleft_StopRespond-null','STNleft_StopInhibit-GO',...
    'STNleft_StopRespond-GO','STNleft_StopInhibit+StopRespond-null',...
    'STNleft_StopInhibit+StopRespond-GO','STNleft_All_Conditions-null',...
    'STNleft-SNleft_GO','STNleft-SNleft_GO_ERROR','STNleft_-SNleft_StopInhibit',...
    'STNleft_SNleft_StopRespond','STNleft-SNleft_Stops','STNleft-SNleft_with_Stops-Go',...
    'STNleft-SNleft_with_sum_All_Conditions',...
    'STNleft+SNleft_with_sum_All_Conditions_except_GO_ERROR',...
    'STNleft+SNleft_with_sum_All_Conditions'};
groups = [repmat({'Controls'},1,18),repmat({'Patients'},1,6)];
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/FIR_timeseries_Connectivity_bf2/';
save_dir = source_dir;
job_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/jobfiles/SecondLevel/';%where to save the jobs
mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/fullhead/subject/coreg_TR2_normalized/';
%source_image_label = 'R2Z';
RESULT_DIR = [];
%% Step 1: Second Level One-Sample T-Test: within group
save_job = 'riss_con_%s_OneSampleTTest_bf2.mat';
% for the subjects with different contrasts, specify which image
% corresponds to the entire space of all 34 contrasts.
% e.g. subset_vect(1) = 5 means at second level contrast model 1 should 
% use the fifth contrast of the subject. To exclude that subject for a
% model, set it to 0. Deafult is to include all subjects and construct all
% 34 models
%subset_vect.MM051013_haldol = [1,2,4,5,7:12,15:18,21:34,36:41,42:47];
%subset_vect.MP020_050613 = [1,2,4,5,7:12,15:18,21:34,36:41,42:47];
%subset_vect.MP022_051713 = [1,2,3,4,5,6,0,7,0,8,9,10,0,11,0,12,0,13,14,15,0,0,16,17,0,0,18,0,0,0,19,0,0,0,20,21,0,22,0,0];

BATCH = [];

[G,~,IXB] = unique(groups);
source_image = ['%s_',source_image_label,'_%s.nii'];
for g = 1:length(unique(G))
    subjects_list = subjects(IXB==g);
    result_dir = fullfile(save_dir,['SecondLevel_',G{g},'_',source_image_label]);
    RESULT_DIR = [RESULT_DIR,cellstr(result_dir)];
    %check source directory for mask
    mask_path = char(SearchFiles(mask_dir,['*',G{g},'*group_mask.nii']));
    if isempty(mask_path);
        error('use spm_create_binary_mask to create a binary mask!\n');
    end
for m = 1:length(condnames) % for each model
    % load template job file for secod level
    load(fullfile(fMRI_pipeline,'jobfiles','Group_OneSampleTTest.mat'));
    % make a directory for the current model
    current_dir = fullfile(result_dir,condnames{m});
    % remove some illgeal characters
    IND = intersect(regexp(current_dir,'(\W)'),...
        intersect(regexp(current_dir,'(\S)'),regexp(current_dir,'[^_-+]')));
    current_dir(IND) = '';
    % make model directory
    eval(['!mkdir -p ', current_dir]);
    % set directory for current model
    matlabbatch{1, 1}.spm.stats.factorial_design.dir = {current_dir};
    matlabbatch{1, 1}.spm.stats.factorial_design.masking.em{1} = mask_path;%masking
    matlabbatch{1, 2}.spm.stats.fmri_est.spmmat = {fullfile(current_dir,'SPM.mat')};
    subj_count = 1;% count how many subjects are included
    for s = 1:length(subjects_list)
        % find subj
        current_subj = char(SearchFiles(fullfile(source_dir,subjects_list{s}),...
            sprintf(source_image,subjects_list{s},condnames{m})));
        
        % check if current target file exist
        if ~exist(current_subj,'file')
            continue;
        end
        % set current model's contrasts
        matlabbatch{1, 1}.spm.stats.factorial_design.des.t1.scans(subj_count,1)...
            = cellstr(current_subj);
        subj_count = subj_count+1;
        clear current_subj;
    end
    % add the finalized job to BATCH
    BATCH = [BATCH,matlabbatch];
    clear matlabbatch current_dir;
end
end
% rename the job variable
matlabbatch = BATCH;clear BATCH;
% save job
save(fullfile(job_dir,sprintf(save_job,source_image_label)),'matlabbatch');

%run the job
spm('defaults','fmri');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;

%% Step 2: Non-paired Two sample T-Test between group
save_job = 'riss_con_%s_TwoSampleTTest_bf2.mat';
result_dir = fullfile(save_dir,['SecondLevel_BetweenGroup_',source_image_label]);
source_image = ['%s_',source_image_label,'_%s.nii'];
%check source directory for mask
mask_path = char(SearchFiles(mask_dir,'*Control+Patient*group_mask.nii'));
if isempty(mask_path);
    error('use spm_create_binary_mask to create a binary mask!\n');
end
BATCH = [];
for m = 1:length(condnames) % for each model
    % load template job file for secod level
    load(fullfile(fMRI_pipeline,'jobfiles','Group_TwoSampleTTest.mat'));
    % make a directory for the current model
    current_dir = fullfile(result_dir,condnames{m});
    % remove some illgeal characters
    IND = intersect(regexp(current_dir,'(\W)'),...
        intersect(regexp(current_dir,'(\S)'),regexp(current_dir,'[^_-+]')));
    current_dir(IND) = '';
    % make model directory
    eval(['!mkdir -p ', current_dir]);
    % set directory for current model
    matlabbatch{1, 1}.spm.stats.factorial_design.dir = {current_dir};
    matlabbatch{1, 1}.spm.stats.factorial_design.masking.em{1} = mask_path;%masking
    matlabbatch{1, 2}.spm.stats.fmri_est.spmmat = {fullfile(current_dir,'SPM.mat')};
    subj_count_1 = 1;% count how many subjects are included
    subj_count_2 = 1;% count how many subjects are included   
    for s = 1:length(subjects)
        % find subj
        current_subj = char(SearchFiles(fullfile(source_dir,subjects{s}),...
            sprintf(source_image,subjects{s},condnames{m})));
        
        % check if current target file exist
        if ~exist(current_subj,'file')
            continue;
        end
        % set current model's contrasts
        switch groups{s}
            case {'Patients'}% positive: # change the group name
                matlabbatch{1, 1}.spm.stats.factorial_design.des.t2.scans1(...
                    subj_count_1,1) = cellstr(current_subj);
                 subj_count_1 = subj_count_1+1;    
            case {'Controls'}% negative: # chagne the group name
                matlabbatch{1, 1}.spm.stats.factorial_design.des.t2.scans2(...
                    subj_count_2,1) = cellstr(current_subj);
                 subj_count_2 = subj_count_2+1;
        end
        clear current_subj;
    end
        % add the finalized job to BATCH
    BATCH = [BATCH,matlabbatch];
    clear matlabbatch current_dir;
end
% rename the job variable
matlabbatch = BATCH;clear BATCH;
% save job
save(fullfile(job_dir,sprintf(save_job,source_image_label)),'matlabbatch');

%run the job
spm('defaults','fmri');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;

%% Step 3: Making contrasts of the resulting betas in One Sample T-Test
save_job = 'riss_con_%s_contrasts_OneSampleTTest_results_bf2.mat';

BATCH = [];
con = num2cell(ones(1,length(condnames)));
for r = 1:length(RESULT_DIR)
for m = 1:length(condnames)
    disp(condnames{m});
    % parse path to SPM.mat
    spm_loc = fullfile(RESULT_DIR{r},condnames{m},'SPM.mat');
    % make contrasts
    contrasts.name = condnames{m}; 
    contrasts.con = con{m};
    % add contrasts to jobs to be run
    BATCH = [BATCH,make_contrasts_jobs(spm_loc,contrasts)];
    % load result report samplel job file
    load(fullfile(fMRI_pipeline,'jobfiles','resultsreport.mat'));
    matlabbatch{1, 1}.spm.stats.results.spmmat = cellstr(spm_loc);
    matlabbatch{1, 1}.spm.stats.results.conspec.titlestr = condnames{m};% use cond name as title of the report
    matlabbatch{1, 1}.spm.stats.results.conspec.contrasts = Inf;% print result for which contrast
    matlabbatch{1, 1}.spm.stats.results.conspec.threshdesc = 'FWE';
    matlabbatch{1, 1}.spm.stats.results.conspec.thresh = 0.05;
    matlabbatch{1, 1}.spm.stats.results.conspec.extent = 0;
    matlabbatch{1, 1}.spm.stats.results.conspec.mask = struct([]);
    matlabbatch{1, 1}.spm.stats.results.units = 1; %{'mm', 'mm', 'mm'} in 3D
    matlabbatch{1, 1}.spm.stats.results.print = true; % print results
    
    % add to batch job
    BATCH = [BATCH, matlabbatch];
    clear matlabbatch spm_loc;
end
end
% change variable name
matlabbatch = BATCH; clear BATCH;

% save jobs
save(fullfile(job_dir,sprintf(save_job,source_image_label)),'matlabbatch');

%run the job
spm('defaults','fmri');
fprintf('Running contrasts ...\n')
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;

%% Step 4: Making contrasts of the resulting betas in Two Sample T-Test
save_job = 'riss_con_%s_contrasts_TwoSampleTTest_results_bf2.mat';
con = repmat({[1,-1]},1,length(condnames));

BATCH = [];

for m = 1:length(condnames)
    disp(condnames{m});
    % parse path to SPM.mat
    spm_loc = fullfile(result_dir,condnames{m},'SPM.mat');
    % make contrasts
    contrasts.name = condnames{m}; 
    contrasts.con = con{m};
    % add contrasts to jobs to be run
    BATCH = [BATCH,make_contrasts_jobs(spm_loc,contrasts)];
    % load result report samplel job file
    load(fullfile(fMRI_pipeline,'jobfiles','resultsreport.mat'));
    matlabbatch{1, 1}.spm.stats.results.spmmat = cellstr(spm_loc);
    matlabbatch{1, 1}.spm.stats.results.conspec.titlestr = condnames{m};% use cond name as title of the report
    matlabbatch{1, 1}.spm.stats.results.conspec.contrasts = Inf;% print result for which contrast
    matlabbatch{1, 1}.spm.stats.results.conspec.threshdesc = 'FWE';
    matlabbatch{1, 1}.spm.stats.results.conspec.thresh = 0.05;
    matlabbatch{1, 1}.spm.stats.results.conspec.extent = 0;
    matlabbatch{1, 1}.spm.stats.results.conspec.mask = struct([]);
    matlabbatch{1, 1}.spm.stats.results.units = 1; %{'mm', 'mm', 'mm'} in 3D
    matlabbatch{1, 1}.spm.stats.results.print = true; % print results
    
    % add to batch job
    BATCH = [BATCH, matlabbatch];
    clear matlabbatch spm_loc;
end
% change variable name
matlabbatch = BATCH; clear BATCH;

% save jobs
save(fullfile(job_dir,sprintf(save_job,source_image_label)),'matlabbatch');

%run the job
spm('defaults','fmri');
fprintf('Running contrasts ...\n')
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;

