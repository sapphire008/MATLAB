subjects = {'202_no_moveparams'};

extension_dir = '/SPM.mat';
subject_dir = '/home/thompson/old/beta_series/subjects/';
ROI_loc = '/home/thompson/old/beta_series/SZ+3Face_-1All_SZ_1000_High_Pass_42_-56_-20.nii';
results_dir = '/home/thompson/old/beta_series/results/';

for n = 1:length(subjects);
    
    SPM_loc = [subject_dir subjects{n} extension_dir]; 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(SPM_loc);
    
    [beta_idx beta_names] = group_beta_images_by_block_condition_basis(SPM);
    
    % find the X Y Z index for the ROI - need so we do not need to read the
    % whole image into memory
    XYZ = roi_find_index(ROI_loc);
    
    % build paths to beta images beta images
    files = char(SPM.Vbeta.fname);
    beta_path = repmat([SPM.swd,'/'],size(files,1),1);
    beta_path = [beta_path,files]; 
    % extract ROI data for all beta images
    raw_data = spm_get_data(beta_path,XYZ);
    mean_data = nanmean(raw_data');
    
    fid = fopen([results_dir,subjects{n},'.csv'], 'w');
    
    for k = 1:size(beta_idx,1),
        beta_mean(k,:) = mean_data(beta_idx(k,:));
        fprintf(fid,'%s\t',beta_names{k}(1:4));
        fprintf(fid,'%s\t',beta_names{k}(6:end));
        fprintf(fid,'%g\t',beta_mean(k,:));
        fprintf(fid,'\n');
    end
    
    fclose(fid);
    
    save([results_dir,subjects{n},],'beta_names','beta_mean', 'raw_data');
    
end
