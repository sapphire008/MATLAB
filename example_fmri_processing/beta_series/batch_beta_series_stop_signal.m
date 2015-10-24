addspm8('NoConflicts');
clear all;
addpath('/nfs/jong_exp/midbrain_pilots/scripts/beta_series/');
subjects = {...
    'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};

extension_dir = '/SPM.mat';
subject_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM/';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/ROI_peak_T_voxel/peak_T_ROIs/';
ROI_ext = {'_TR2_SNleft_peakvoxel','_TR2_STNleft_peakvoxel'};
results_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/beta_series/extracted_betas_peak_T_voxel/';

for n = 1:length(subjects);
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
        beta_path = [repmat([SPM.swd,'/'],size(files,1),1),files];
        % extract ROI data for all beta images
        raw_data = spm_get_data(beta_path,XYZ);
        mean_data = nanmean(raw_data,2);
        
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
