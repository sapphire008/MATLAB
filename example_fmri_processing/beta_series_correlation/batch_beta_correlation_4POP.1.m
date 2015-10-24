% top level directory for subject beta images
subjectpath = '/nfs/jong_exp/PFC_basalganglia/TMS_Study/Mike_postpost2_TMS/analysis/4POP/multivariate_estimations/';

% the seed image - must be in the same space as beta images
Seed_mask ='/nfs/jong_exp/PFC_basalganglia/TMS_Study/Mike_postpost2_TMS/funcs/SNLeft.nii';
% write resulte to
pathstr = '/nfs/jong_exp/PFC_basalganglia/TMS_Study/Mike_postpost2_TMS/analysis/4POP/beta_series_correlations/';
% cell array of subject ID's
subIDs = {'2mm','8mm'};
% Cue information
Events = {{'GreenCue' 'bf(1)'} {'RedCue' 'bf(1)'} {'GreenDelay' 'bf(1)'} {'RedDelay' 'bf(1)'} {'GreenProbe' 'bf(1)'} {'RedProbe' 'bf(1)'}};
% Apply Trim? 1 for yes 0 for no
trim = 0;
%set threshold for ROI data - values below the threshold are not included
%in the ROI
threshold = 0;

for n = 1:length(subIDs);
        
    SPM_loc = [subjectpath,subIDs{n},'/SPM.mat'];
    load(SPM_loc);
        
    for k = 1:length(Events);
        
        [Cout, sqrtN] = beta_series_correlation_nomars(SPM,Seed_mask,Events{k},trim,threshold);
        
        [foo,roiLabel,ext] = fileparts(Seed_mask);
        % output R correlation results to image
        corr_file = fullfile([pathstr,'/'],[subIDs{n},'_Rcorr_',roiLabel,Events{k}{1},'.nii']);
        writeCorrelationImage(Cout,corr_file, SPM.xVol);
        
        % output R correlation results to image
        corr_file = fullfile([pathstr,'/'],[subIDs{n},'_R_atanh_corr_',roiLabel,Events{k}{1},'.nii']);
        writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);
        
        % output Z correlation results to image
        corr_file = fullfile([pathstr,'/'],[subIDs{n},'_Zcorr_',roiLabel,Events{k}{1},'.nii']);
        writeCorrelationImage((atanh(Cout)*sqrtN),corr_file, SPM.xVol);
        
    end
end


    
    
  