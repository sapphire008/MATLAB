% top level directory for subject beta images
subjectpath = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM_trial_wise_with_GO_ONLY/';
% directory of native space mask
mask_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
ROI_ext = '_TR2_SNleft.nii';
% write resulte to
pathstr = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/beta_series_correlations_with_GO_ONLY/';
% cell array of subject ID's
subjects = {'MP025_061013','MP123_061713'};
% Cue information
Events = {{'GO','bf(1)'},{'GO_ONLY','bf(1)'},{'StopInhibit','bf(1)'},{'StopRespond','bf(1)'}};
% Apply Trim? 1 for yes 0 for no
trim = 0;
%set threshold for ROI data - values below the threshold are not included
%in the ROI
threshold = 0;

for n = 1:length(subjects);
    
    % the seed image - must be in the same space as beta images
    Seed_mask = fullfile(mask_dir, [subjects{n},ROI_ext]);
    
    %find location fo SPM file
    SPM_loc = [subjectpath,subjects{n},'/SPM.mat'];
    load(SPM_loc);
        
    for k = 1:length(Events);
        
        [Cout, SE] = beta_series_correlation_nomars(SPM,Seed_mask,Events{k},trim,threshold);
        
        [foo,roiLabel,ext] = fileparts(Seed_mask);
        % output R correlation results to image
        corr_file = fullfile([pathstr,'/'],[subjects{n},'_Rcorr_',roiLabel,Events{k}{1},'.nii']);
        writeCorrelationImage(Cout,corr_file, SPM.xVol);
        
        % output R correlation results to image
        corr_file = fullfile([pathstr,'/'],[subjects{n},'_R_atanh_corr_',roiLabel,Events{k}{1},'.nii']);
        writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);
        
        % output Z correlation results to image
        corr_file = fullfile([pathstr,'/'],[subjects{n},'_Zcorr_',roiLabel,Events{k}{1},'.nii']);
        writeCorrelationImage((atanh(Cout)/SE),corr_file, SPM.xVol);
        
    end
end


    
    
  