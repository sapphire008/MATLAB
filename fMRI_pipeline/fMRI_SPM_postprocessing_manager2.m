% fMRI SPM model estimation managers
% created since there are many types of model estimations to do
clear all;close all;clc;restoredefaultpath;
addpath('/home/cui/scripts/');
addmatlabpkg('jong_spm8');%add customized spm8
spm_jobman('initcfg');%initilize spm job running facilities
addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
base_dir = '/nfs/jong_exp/midbrain_pilots/';
%setup tasks for analysis
ANALYZE(1).task = 'frac_back';
ANALYZE(1).firstlevel.type = {'GLM_model_estimation','GLM_nback_model_estimation',};
ANALYZE(1).firstlevel.jobfile_ext = {'.mat','.mat'};
ANALYZE(1).firstlevel.analysis_dirs = {'GLM','GLM_combined'};

ANALYZE(2).task = 'stop_signal';
ANALYZE(2).firstlevel.type = {'GLM','FIR_GLM'};
ANALYZE(2).firstlevel.jobfile_ext = {'_model_estimation.mat','_model_estimation.mat'};
ANALYZE(2).firstlevel.analysis_dirs = {'GLM','GLM_with_GO_ONLY','FIR_GLM','FIR_GLM_with_GO_ONLY'};

ANALYZE(3).task = 'mid';
ANALYZE(3).firstlevel.type = {'GLM','GLM_alternative','GLM_visual'};
ANALYZE(3).firstlevel.jobfile_ext = {'.mat','.mat','.mat'};
ANALYZE(3).firstlevel.analysis_dirs = {'GLM','GLM_alternative','GLM_visual'};

%subject list
subjects = {'MP031_071813'};%,'MP034_072213','MP035_072613','MP125_072413'};
template_subject = 'MP025_061013';

%before running the script
%check if mask exists
%check if movement data exists


%% First Level Model Estimation
for A = 3:length(ANALYZE)
    %make vectors
    addpath(fullfile(base_dir,'scripts',[ANALYZE(A).task,'_vectors']));
    eval(['PIPE_vectors_',ANALYZE(A).task,'(subjects)']);
    rmpath(fullfile(base_dir,'scripts',[ANALYZE(A).task,'_vectors'])); 
    for s = 1:length(subjects)
         %check if source image file exists
        if isempty(dir(fullfile(base_dir,ANALYZE(A).task,'subjects/funcs/',subjects{s})))
            %display a message
            disp([ANALYZE(A).task,'|',subjects{s},' does not exist. Skipped']);
            continue;%skip that analysis
        end
        %check if mask file and movement file exists
        if isempty(dir(fullfile(base_dir,'ROIs/TR2',[subjects{s},'*','mask.nii'])))
            error([subjects{s},' ','TR2 mask-->NOT FOUND!']);
        end
        if isempty(dir(fullfile(base_dir,'ROIs/TR3',[subjects{s},'*','mask.nii'])))
            error([subjects{s},' ','TR3 mask-->NOT FOUND!']);
        end
        if isempty(dir(fullfile(base_dir,'movement',ANALYZE(A).task,[subjects{s},'*.txt'])))
            error([subjects{s},' ','Movement Data -->NOT FOUND!']);
        end 
         %make folders
        for k = 1:length(ANALYZE(A).firstlevel.analysis_dirs)
            eval(['!mkdir -p ',fullfile(base_dir,ANALYZE(A).task,'analysis',...
                ANALYZE(A).firstlevel.analysis_dirs{k},subjects{s})]);
        end
        %run first level model estimation jobs
        for J = 2:length(ANALYZE(A).firstlevel.jobfile_ext)
            clear job_dir job_file;
            %make SPM jobs
            job_dir = fullfile(base_dir,ANALYZE(A).task,'jobfiles',...
                ANALYZE(A).firstlevel.type{J});
            create_SPM_jobs(job_dir, 1, ...
                ANALYZE(A).firstlevel.jobfile_ext{J},...
                template_subject,{subjects{s}});
            %run SPM job
            job_file = fullfile(job_dir,...
                [subjects{s},ANALYZE(A).firstlevel.jobfile_ext{J}]);
            spm_jobman('run',job_file);
        end
    end
end

%% Contrasts




