clear;clc;
subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};
Mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR2/';
FIR_GLM_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/FIR_trialwiseGLM/';
save_dir_bf2 = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/FIR_timeseries_Connectivity_bf2/';
save_dir_AUC = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/FIR_timeseries_Connectivity_AUC/';
Mask_ext = '_average_TR2_mask.nii';
ROI_dir = Mask_dir;
ROI_ext = {'_TR2_SNleft.nii','_TR2_STNleft.nii'};
ROI_names = {'SNleft','STNleft'};
Events = {'GO','GO_ERROR','StopInhibit','StopRespond'};

%% DO NOT EDIT BELOW
addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/RissmanConnectivity/;
%addspm8;
%spm_jobman('initcfg');
for s = 1:length(subjects)
    disp(subjects{s});
    current_dir = fullfile(FIR_GLM_dir,subjects{s});
    % design
    SPM = fullfile(current_dir,'SPM.mat');
    tmp = load(SPM);
    if ~isfield(tmp.SPM,'Vbeta')
        % model estimation
        matlabbatch{1}.spm.stats.fmri_est.spmmat = {SPM};
        matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
        spm_jobman('run',matlabbatch);
    elseif exist(fullfile(current_dir,'FIR_betas.tgz'),'file') && ...
            ~exist(fullfile(current_dir,'beta_0001.img'),'file')
        working_dir = pwd;
        cd(current_dir);
        eval('!tar -zxvf FIR_betas.tgz');
        cd(working_dir);
        clear working_dir;
    elseif isfield(tmp.SPM,'Vbeta') && ...
            ~exist(fullfile(current_dir,'beta_0001.img'),'file')
        % remove everything in the directory except SPM.mat
        P = [SearchFiles(current_dir,'mask*'),SearchFiles(current_dir,'ResMS*'),...
            SearchFiles(current_dir,'RPV*'),SearchFiles(current_dir,'beta*')];
        cellfun(@delete,P); clear P;
        % model estimation
        matlabbatch{1}.spm.stats.fmri_est.spmmat = {SPM};
        matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
        spm_jobman('run',matlabbatch);
    end
    clear tmp;
    % get ROI/mask
    ROI_loc = cellfun(@(x) fullfile(ROI_dir,[subjects{s},x]),ROI_ext,'un',0);
    Mask_loc = fullfile(Mask_dir,[subjects{s},Mask_ext]);
    
    % save directory
    output_dir_bf2 = fullfile(save_dir_bf2,subjects{s});
    eval(['!mkdir -p ',output_dir_bf2]);
    output_image_bf2 = fullfile(output_dir_bf2,[subjects{s},'.nii']);
    
    output_dir_AUC = fullfile(save_dir_AUC,subjects{s});
    eval(['!mkdir -p ',output_dir_AUC]);
    output_image_AUC = fullfile(output_dir_AUC,[subjects{s},'.nii']);
    
    % calculate correlation maps
    if s>1
        FIR_Seed2Vox_Correlation(SPM,Events,ROI_loc,ROI_names,Mask_loc,output_image_bf2,{'R2Z','Z_test'},true);
    end
    FIR_Seed2Vox_Correlation_AUC(SPM,Events,ROI_loc,ROI_names,Mask_loc,output_image_AUC,{'R2Z','Z_test'},true);

    
    % clean up: archive all the model estimates to save some space
    if ~exist(fullfile(current_dir,'FIR_betas.tgz'),'file')
        tar(fullfile(current_dir,'FIR_betas.tgz'),'beta*',current_dir);
    end
    cellfun(@delete,SearchFiles(current_dir,'beta_*'));
    
    
    clear P ROI_loc Mask_loc output_dir output_image current_dir SPM;
end