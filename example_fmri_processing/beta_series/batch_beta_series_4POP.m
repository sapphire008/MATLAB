%addspm8('NoConflicts');
%addpath('/nfs/jong_exp/midbrain_pilots/scripts/beta_series/');
clear all;

GLM_type = '';% '' or '_alternative'

ROI_ext = {'_TR3_SNleft_peakvoxel','_TR3_STNleft_peakvoxel'};

subjects = {'JY_052413_haldol','MM_051013_haldol','TMS100','TMS200'};

extension_dir = '/SPM.mat';
subject_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/analysis/GLM/';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/analysis/ROI_peak_T_voxel/peak_T_ROIs/';
results_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/analysis/beta_series/extracted_peakvoxel_betas/';

%% Main Beta Extraction Algorithm
for n = 1:length(subjects)
    %display subject ID
    disp(subjects{n});
    
    SPM_loc = [subject_dir subjects{n} extension_dir]; 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(SPM_loc);
    
    [beta_idx, beta_names] = group_beta_images_by_block_condition_basis(SPM);
    
    for r = 1:length(ROI_ext)
    % find the X Y Z index for the ROI - need so we do not need to read the
    % whole image into memory
    ROI_loc = fullfile(ROI_dir,[subjects{n},ROI_ext{r},'.nii']);
    XYZ = roi_find_index(ROI_loc);
    
    % build paths to beta images beta images
    files = char(SPM.Vbeta.fname);
    beta_path = repmat([SPM.swd,'/'],size(files,1),1);
    beta_path = [beta_path,files]; 
    % extract ROI data for all beta images
    raw_data = spm_get_data(beta_path,XYZ);
    mean_data = nanmean(raw_data,2)';
    
    fid = fopen([results_dir,subjects{n},ROI_ext{r},'.csv'], 'w');
    
    for k = 1:size(beta_idx,1),
        beta_mean(k,:) = mean_data(beta_idx(k,:));%take only the first column which corresponds to bf(1)
        fprintf(fid,'%s,',beta_names{k}(1:4));
        fprintf(fid,'%s,',beta_names{k}(6:end));
        fprintf(fid,'%g,',beta_mean(k,:));
        fprintf(fid,'\n');
    end
    
    fclose(fid);
    
    save([results_dir,subjects{n},ROI_ext{r},'.mat'],'beta_names','beta_mean', 'raw_data');
    end
end
