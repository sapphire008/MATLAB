addspm8;
fMRI_pipeline = addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/second_level_analysis/;
spm_jobman('initcfg');

%% Step 1: normalize from native space to template space
% subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
%     'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
%     'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
%     'MP123_061713','MP124_062113','MP125_072413'};
% % contrasts that needed to be normalized
% source_contrast_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/GLM/';
% source_contrast_target = 'con*.img'; % or selected {'con_0001.img','con_0002.img'}
% % use native space functional image to calculate normalization matrix. This
% % image needs to match the space of contrast images
% deformation_field_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/fullhead/subject/coreg_TR2_normalized/';
% % specify where to save the result
% result_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/SecondLevel/';
% % job directory
% save_job = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/jobfiles/normalization/stop_signal_con_normalization.mat';
% 
% matlabbatch = cell(1,length(subjects));
% for s = 1:length(subjects)
%     % report progress
%     disp(subjects{s});
%     % search for deformation field
%     deformation_type = 'spm8';
%     P = SearchFiles(deformation_field_dir,sprintf('*%s*_sn.mat',subjects{s}));
%     if isempty(P)
%         P = SearchFiles(deformation_field_dir,sprintf('y_*%s*.nii',subjects{s}));
%         deformation_type = 'spm12';
%     end
%     if isempty(P)
%         fprintf('%s does not have deformation field, cannot be normalized\n',subjects{s});
%         continue;
%     end
%     % get con images to be normalized
%     spm_loc = fullfile(source_contrast_dir,subjects{s},'SPM.mat');
%     if ~exist(spm_loc,'file'),continue;end
%     load(spm_loc);clear spm_loc;
%     Q = arrayfun(@(x) fullfile(source_contrast_dir,subjects{s},...
%         x.Vcon.fname),SPM.xCon,'un',0)';
%     % build normalization job files
%     switch deformation_type
%         case 'spm8'
%             matlabbatch{s}.spm.tools.oldnorm.write.subj.matname = P;
%             matlabbatch{s}.spm.tools.oldnorm.write.subj.resample= Q;
%             matlabbatch{s}.spm.tools.oldnorm.write.roptions.preserve=0;
%             matlabbatch{s}.spm.tools.oldnorm.write.roptions.bb=[-78,-112,-70;78,76,85];
%             matlabbatch{s}.spm.tools.oldnorm.write.roptions.vox=[2,2,2];
%             matlabbatch{s}.spm.tools.oldnorm.write.roptions.interp=4;
%             matlabbatch{s}.spm.tools.oldnorm.write.roptions.wrap=[0,0,0];
%             matlabbatch{s}.spm.tools.oldnorm.write.roptions.prefix='w';
%         case 'spm12'
%             matlabbatch{s}.spm.spatial.normalise.write.subj.def=P;
%             matlabbatch{s}.spm.spatial.normalise.write.subj.resample=Q;
%             matlabbatch{s}.spm.spatial.normalise.write.woptions.bb=[-78,-112,-70;78,76,85];
%             matlabbatch{s}.spm.spatial.normalise.write.woptions.vox=[2,2,2];
%             matlabbatch{s}.spm.spatial.normalise.write.woptions.interp=4;
%     end
% end
% % remove empty entries
% matlabbatch = matlabbatch(~cellfun(@isempty,matlabbatch));
% % save the job
% save(save_job,'matlabbatch');
%
% % run the job
% spm_jobman('initcfg');
% spm_jobman('run',matlabbatch);
%
% % Chagning all the 0's to NaNs for the normalized images
% target_img = 'wcon*.img';
% for s = 1:length(subjects)
%     [P,N] = SearchFiles(fullfile(source_contrast_dir,subjects{s}),target_img);
%     Q = cellfun(@(x) fullfile(result_dir,subjects{s},x),N,'un',0);
%     eval(['!mkdir -p ',fullfile(result_dir,subjects{s})]);
%     if isempty(P)
%         continue;
%     end
%     FileFun(@create_thresholded_image,P,Q,[],false,0,'=',NaN);
%     cellfun(@delete,P);
%     cellfun(@delete,regexprep(P,'.img','.hdr'));
%     clear P Q;
% end
% rmpath(genpath(addmatlabpkg('spm12b')));
% clear classes; addspm8; % everything is removed!!

%% Step 2: Second Level One-Sample T-Test
subjects_list = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};
group = [repmat({'Controls'},1,18),repmat({'Patients'},1,6)];
SPM_loc = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/GLM/';
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/GLM/';
result_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/SecondLevel/';
mask_loc = '/hsgs/projects/jhyoon1/midbrain_pilots/fullhead/subjects/coreg_TR2_normalized/';
condnames = {'Go-null','StopInhibit-null','StopRespond-null',...
    'StopInhibit-Go','StopRespond-Go','StopInhibit-StopRespond',...
    'StopInhibit+StopRespond-null','StopInhibit+StopRespond-Go'};
job_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/jobfiles/SecondLevel/';
save_job = 'stop_signal_2ndlvl_OneSampleTTest.mat';

    
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
RESULT_DIR = [];
fMRI_pipeline = addmatlabpkg('fMRI_pipeline');
[G,~,IXB] = unique(group);
for g = 1:length(G)
    subjects = subjects_list(IXB==g);
    RESULT_DIR = [RESULT_DIR,{fullfile(result_dir,['SecondLevel_',G{g}])}];
    mask_dir = SearchFiles(mask_loc,sprintf('*%s*group_mask.nii',G{g}));
    for m = 1:length(condnames) % for each model
        % make a directory for the current model
        if ~exist('replacename','var') || isempty(replacename{m})
            current_dir = fullfile(result_dir,['SecondLevel_',G{g}],condnames{m});
        else
            current_dir = fullfile(result_dir,['SecondLevel_',G{g}],replacename{m});
            
        end
        % remove some illgeal characters
        IND = intersect(regexp(current_dir,'(\W)'),...
            intersect(regexp(current_dir,'(\S)'),regexp(current_dir,'[^_-+]')));
        current_dir(IND) = '';
        % make model directory
        eval(['!mkdir -p ', current_dir]);
        % load template job file for secod level
        load(fullfile(fMRI_pipeline,'jobfiles','Group_OneSampleTTest.mat'));
        % set directory for current model
        matlabbatch{1, 1}.spm.stats.factorial_design.dir = {current_dir};
        matlabbatch{1, 1}.spm.stats.factorial_design.masking.em = mask_dir;
        matlabbatch{1, 2}.spm.stats.fmri_est.spmmat = {fullfile(current_dir,'SPM.mat')};
        
        subj_count = 1;% count how many subjects are included
        for s = 1:length(subjects)
            % check if this is the special subject
            if exist('subset_vect','var') && isfield(subset_vect,subjects{s})
                if subset_vect.(subjects{s})(m)==0
                    continue;
                end
            elseif ~exist(fullfile(SPM_loc,subjects{s},'SPM.mat'),'file')
                continue;
            else
                load(fullfile(SPM_loc,subjects{s},'SPM.mat'));
                IND = find(strcmpi(condnames{m},{SPM.xCon.name}));
                current_subj = fullfile(source_dir,subjects{s},['w',SPM.xCon(IND).Vcon.fname]);
                clear SPM IND;
            end
            % check if current target file exist
            if ~exist(current_subj,'file')
                continue;
            end
            % set current model's contrasts
            matlabbatch{1, 1}.spm.stats.factorial_design.des.t1.scans{subj_count} = current_subj;
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
save(fullfile(job_dir,save_job),'matlabbatch');

%run the job
%spm_jobman('run',matlabbatch);
%clear matlabbatch;

%% Step 3: Making contrasts of the resulting betas in One Sample T-Test
con = num2cell(ones(1,length(condnames)));
save_job = 'stop_signal_2ndlvl_contrasts_OneSampleTTest_result.mat';

BATCH = [];
names = condnames;
if exist('replacename','var')
    IND = find(~cellfun(@isempty,replacename));
    names(IND) = replacename(IND);
end
for r = 1:length(RESULT_DIR)
for m = 1:length(names)
    disp(names{m});
    % parse path to SPM.mat
    spm_loc = fullfile(RESULT_DIR{r},names{m},'SPM.mat');
    if ~exist(spm_loc,'file'),continue;end
    % make contrasts
    contrasts.name = names{m}; 
    contrasts.con = con{m};
    % add contrasts to jobs to be run
    BATCH = [BATCH,make_contrasts_jobs(spm_loc,contrasts)];
    % load result report samplel job file
    load(fullfile(fMRI_pipeline,'jobfiles','resultsreport.mat'));
    matlabbatch{1, 1}.spm.stats.results.spmmat = cellstr(spm_loc);
    matlabbatch{1, 1}.spm.stats.results.conspec.titlestr = names{m};% use cond name as title of the report
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
save(fullfile(job_dir,save_job),'matlabbatch');

%run the job
spm('defaults','fmri');
fprintf('Running contrasts ...\n')
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;


%% Setp 4: Second Level Between Group Non-Paired Two-Sample T-Test
save_job = 'stop_signal_2ndlvl_TwoSampleTTest.mat';
RESULT_DIR = fullfile(result_dir,'SecondLevel_BetweenGroup');
%check source directory for mask
mask_dir = SearchFiles(mask_loc,'*Control+Patient*group_mask.nii');
if isempty(mask_dir);
    error('use spm_create_binary_mask to create a binary mask!\n');
end
BATCH = [];
for m = 1:length(condnames) % for each model
    % load template job file for secod level
    load(fullfile(fMRI_pipeline,'jobfiles','Group_TwoSampleTTest.mat'));
    % make a directory for the current model
    current_dir = fullfile(RESULT_DIR,condnames{m});
    % remove some illgeal characters
    IND = intersect(regexp(current_dir,'(\W)'),...
        intersect(regexp(current_dir,'(\S)'),regexp(current_dir,'[^_-+]')));
    current_dir(IND) = '';
    % make model directory
    eval(['!mkdir -p ', current_dir]);
    % set directory for current model
    matlabbatch{1, 1}.spm.stats.factorial_design.dir = {current_dir};
    matlabbatch{1, 1}.spm.stats.factorial_design.masking.em = mask_dir;%masking
    matlabbatch{1, 2}.spm.stats.fmri_est.spmmat = {fullfile(current_dir,'SPM.mat')};
    subj_count_1 = 1;% count how many subjects are included
    subj_count_2 = 1;% count how many subjects are included   
    for s = 1:length(subjects_list)
        % find subject
        if exist('subset_vect','var') && isfield(subset_vect,subjects_list{s})...
                && subset_vect.(subjects_list{s})(m)==0
            continue;
        else
            load(fullfile(SPM_loc,subjects_list{s},'SPM.mat'));
            IND = find(strcmpi(condnames{m},{SPM.xCon.name}));
            current_subj = fullfile(source_dir,subjects_list{s},['w',SPM.xCon(IND).Vcon.fname]);
            clear SPM IND;
        end
        
        % check if current target file exist
        if ~exist(current_subj,'file')
            continue;
        end
        % set current model's contrasts
        switch group{s}
            case {'Patients'}% positive: # change the group name
                matlabbatch{1, 1}.spm.stats.factorial_design.des.t2.scans1(...
                    subj_count_1,1) = cellstr(current_subj);
                 subj_count_1 = subj_count_1+1;    
            case {'Controls'}% negative: # change the group name
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
save(fullfile(job_dir,save_job),'matlabbatch');

%run the job
spm('defaults','fmri');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;

%% Step 5: Making contrasts of the resulting betas in Two-Sample T-Test
save_job = 'stop_signal_2ndlvl_contrasts_TwoSampleTTest_results.mat';
con = repmat({[1,-1]},1,length(condnames));

BATCH = [];
names = condnames;
if exist('replacename','var')
    IND = find(~cellfun(@isempty,replacename));
    names(IND) = replacename(IND);
end
for m = 1:length(names)
    disp(names{m});
    % parse path to SPM.mat
    spm_loc = fullfile(RESULT_DIR,names{m},'SPM.mat');
    % make contrasts
    contrasts.name = names{m}; 
    contrasts.con = con{m};
    % add contrasts to jobs to be run
    BATCH = [BATCH,make_contrasts_jobs(spm_loc,contrasts)];
    % load result report samplel job file
    load(fullfile(fMRI_pipeline,'jobfiles','resultsreport.mat'));
    matlabbatch{1, 1}.spm.stats.results.spmmat = cellstr(spm_loc);
    matlabbatch{1, 1}.spm.stats.results.conspec.titlestr = names{m};% use cond name as title of the report
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
save(fullfile(job_dir,save_job),'matlabbatch');

%run the job
spm('defaults','fmri');
fprintf('Running contrasts ...\n')
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
clear matlabbatch;





