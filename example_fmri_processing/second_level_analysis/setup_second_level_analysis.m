addspm8;
fMRI_pipeline = addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/second_level_analysis/;
spm_jobman('initcfg');

%% Step 1: normalize from native space to template space
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
% contrasts that needed to be normalized
source_contrast_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/GLM/';
source_contrast_target = 'con*.img'; % or selected {'con_0001.img','con_0002.img'}
% use native space functional image to calculate normalization matrix. This
% image needs to match the space of contrast images
native_space_func_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/Normalized_con/sources/';
native_space_func_partial = 'resample_r{subjects}_average_TR3.nii';
native_space_func_full = 'resample_r{subjects}_fullhead_average.nii';
% specify where to save the result
result_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/Normalized_con/';
% job directory
save_job = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/jobfiles/normalization/frac_back_con_normalization.mat';

% place holder
BATCH = [];
% load normalization job file
load(fullfile(fMRI_pipeline,'jobfiles/normalization.mat'));
N = matlabbatch;clear matlabbatch;
count = 1;

for s = 1:length(subjects)
    % report progress
    disp(subjects{s});
    
    % determine is necessary files exist
    FULLHEAD = fullfile(native_space_func_dir,regexprep(...
            native_space_func_full,'{subjects}',subjects{s}));
    PARTIAL = fullfile(native_space_func_dir,regexprep(...
            native_space_func_partial,'{subjects}',subjects{s}));
    if ~exist(FULLHEAD,'file') ||~exist(PARTIAL,'file')
        fprintf('%s files not complete, skipped\n',subjects{s});
        continue;
    end
    % parse source files
    if ischar(source_contrast_target) && ~isempty(regexp(source_contrast_target,'\*','once'))
        P = SearchFiles(fullfile(source_contrast_dir,subjects{s}),source_contrast_target);
    elseif iscellstr(source_contrast_target)
        P = cellfun(@(x) fullfile(source_contrast_dir,x),source_contrast_target,'un',0);
    else
        error('Unrecognized source_contrast_target type\n');
    end
    if isempty(P)
        fprintf('%s is empty, skipped\n',subjects{s});
        continue;
    else
        % make the directory
        eval(['!mkdir -p ',fullfile(result_dir,subjects{s})]);
    end
    % make a copy to the result dir
    V = FileFun('sub_copy_files',P,fullfile(result_dir,subjects{s}),[],false,'cp');
    FileFun('sub_copy_files',regexprep(P,'.img','.hdr'),fullfile(result_dir,subjects{s}),[],false,'cp');
    %V = SearchFiles(fullfile(result_dir,subjects{s}),source_contrast_target);
    
    
    % a). coregistration
    load(fullfile(fMRI_pipeline,'jobfiles/coregistration.mat'));
    % set parameters for coregistration job files
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref{1} = FULLHEAD;
    matlabbatch{1}.spm.spatial.coreg.estwrite.source{1} = PARTIAL;
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = cellstr(V);
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'x';
    % expected new images
    [PATHSTR,NAME,EXT] = cellfun(@fileparts,cellstr(V),'un',0);
    V = cellfun(@(x,y,z) fullfile(x,[...
        matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix,y,z]),...
        PATHSTR,NAME,EXT,'un',0);
    clear PATHSTR NAME EXT;
    BATCH = [BATCH,matlabbatch(1)];
    clear matlabbatch;
    
    % b). normalization
    N{1}.spm.spatial.normalise.estwrite.subj(count).source = {FULLHEAD};
    N{1}.spm.spatial.normalise.estwrite.subj(count).resample = V;
    N{1}.spm.spatial.normalise.estwrite.subj(count).resample{end+1} = ...
        fullfile(native_space_func_dir,['x',regexprep(native_space_func_partial,'{subjects}',subjects{s})]);
    N{1}.spm.spatial.normalise.estwrite.subj(count).resample{end+1} = ...
        FULLHEAD;
    count = count + 1;
    clear P V FULLHEAD PARTIAL;
end

% concatenate all the job files
BATCH = [BATCH,N];clear N;
matlabbatch = BATCH;clear BATCH;

% save the job
save(save_job,'matlabbatch');

% run the job
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

% Chagning all the 0's to NaNs for the normalized images
target_img = 'wxcon*.img';
for s = 1:length(subjects)
    P = SearchFiles(fullfile(result_dir,subjects{s}),target_img);
    if isempty(P)
        continue;
    end
    FileFun(@create_thresholded_image,P,P,[],false,0,'=',NaN);
    clear P;
end

%% Step 2: Second Level One-Sample T-Test
subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613'};
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/Normalized_con/';
source_target = 'wxcon_0000.img';
result_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/SecondLevel/';
condnames = {'InstructionBlock-null','ZeroBack-null','OneBack-null',...
    'TwoBack-null','Fixation-null','ZeroBack-Fixation',...
    'OneBack-Fixation','TwoBack-Fixation','OneBack-ZeroBack',...
    'TwoBack-ZeroBack','TwoBack-OneBack','ZeroBack+OneBack+TwoBack-null',...
    'ZeroBack+OneBack+TwoBack-Fixation'};
save_job = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/jobfiles/SecondLevel/frac_back_controls_2ndlvl_OneSampleTTest.mat';

    
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
for m = 1:length(condnames) % for each model
    
    % make model directory
    eval(['!mkdir -p ', fullfile(result_dir,condnames{m})]);
    % load template job file for secod level
    load(fullfile(fMRI_pipeline,'jobfiles','factorialdes2lvl.mat'));
    % make a directory for the current model
    current_dir = fullfile(result_dir,condnames{m});
    % remove some illgeal characters
    IND = intersect(regexp(current_dir,'(\W)'),...
        intersect(regexp(current_dir,'(\S)'),regexp(current_dir,'[^_-+]')));
    current_dir(IND) = '';
    %eval(['!mkdir -p ',current_dir]);
    % set directory for current model
    matlabbatch{1, 1}.spm.stats.factorial_design.dir = {current_dir};
    matlabbatch{1, 2}.spm.stats.fmri_est.spmmat = {fullfile(current_dir,'SPM.mat')};
    subj_count = 1;% count how many subjects are included
    for s = 1:length(subjects)
        % check if this is the special subject
        if exist('subset_vect','var') && isfield(subset_vect,subjects{s})
            if subset_vect.(subjects{s})(m) == 0
                continue;%skip this subject
            else
                % use the specified number
                current_subj = fullfile(source_dir,subjects{s},...
                    regexprep(source_target,'0000',...
                    num2str(subset_vect.(subjects{s})(m),'%04.0f\n')));
            end
        else
            % use the expected number
            current_subj = fullfile(source_dir,subjects{s},...
                    regexprep(source_target,'0000',...
                    num2str(m,'%04.0f\n')));   
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

% rename the job variable
matlabbatch = BATCH;clear BATCH;
% save job
save(save_job,'matlabbatch');

%run the job
spm_jobman('run',matlabbatch);
clear matlabbatch;

%% Step 3: Making contrasts of the resulting betas
con = num2cell(ones(1,length(condnames)));
save_job = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/jobfiles/SecondLevel/frac_back_controls_2ndlvl_contrasts.mat';

spm('defaults','fmri');
fprintf('Running contrasts ...\n')
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
save(save_job,'matlabbatch');

%run the job
spm_jobman('run',matlabbatch);
clear matlabbatch;









