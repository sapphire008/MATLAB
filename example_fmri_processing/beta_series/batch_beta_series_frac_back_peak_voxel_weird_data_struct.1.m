%addspm8;
clear all;

TR = 3;
ROI_type = {'SNleft_peakvoxel','STNleft_peakvoxel'};
GLM_type = '_combined';


switch TR
    case 2
        subjects = {'MP020_050613'};
    case 3
        subjects = {'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
             'MP022_051713','MP023_052013','MP024_052913','MP120_060513',...
             'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
             'MP029_070213','MP030_070313','MP032_071013',...
             'MP033_071213','MP034_072213','MP035_072613',...
             'MP036_072913','MP037_080613',...
             'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
              'MP124_062113','MP125_072413'};
end
extension_dir = '/SPM.mat';
subject_dir = ['/nfs/jong_exp/midbrain_pilots/frac_back2/analysis/GLM',GLM_type,'/'];
ROI_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_peak_T_voxel/peak_T_ROIs_Fixation/';

results_dir = ['/nfs/jong_exp/midbrain_pilots/frac_back/analysis/','beta_series',GLM_type,'/extracted_peak_voxel_beta_Fixation/'];

for n = 1:length(subjects);
    %display subjects
    disp(subjects{n});
    
    SPM_loc = [subject_dir subjects{n} extension_dir]; 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(SPM_loc);
    
    [beta_idx, beta_names] = group_beta_images_by_block_condition_basis(SPM);
    
    % find the X Y Z index for the ROI - need so we do not need to read the
    % whole image into memory
    for r = 1:length(ROI_type)
    ROI_ext = ['_TR',num2str(TR),'_',ROI_type{r}];
    ROI_loc = fullfile(ROI_dir,[subjects{n},ROI_ext,'.nii']);
    XYZ = roi_find_index(ROI_loc);
    
    % build paths to beta images beta images
    files = char(SPM.Vbeta.fname);
    beta_path = repmat([subject_dir,'/',subjects{n},'/'],size(files,1),1);
    beta_path = [beta_path,files]; 
    % extract ROI data for all beta images
    raw_data = spm_get_data(beta_path,XYZ);
    mean_data = nanmean(raw_data,2);
    
    fid = fopen([results_dir,subjects{n},ROI_ext,'.csv'], 'w');
    
    for k = 1:size(beta_idx,1),
        beta_mean(k,:) = mean_data(beta_idx(k,:));
        fprintf(fid,'%s,',beta_names{k}(1:end));
        fprintf(fid,'%g,',beta_mean(k,:));
        fprintf(fid,'\n');
    end
    
    fclose(fid);
    
    save([results_dir,subjects{n},ROI_ext,'.mat'],'beta_names','beta_mean', 'raw_data');
    end
    
end
