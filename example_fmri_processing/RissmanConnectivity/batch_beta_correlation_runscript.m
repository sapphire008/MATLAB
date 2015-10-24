% location of subject data
subjectpath = '/nfs/u3/SN_loc/model_estimation_trial_wise/';

ROI_loc = '/nfs/u3/SN_loc/ITK_Snap/SN_left/old/AT15_SNleft.nii';
% cell array of subject ID's
subIDs = {'AT15'};
% Cue information
Events = {'GreenCue' 'bf(1)'};
% Apply Trim? 1 for yes 0 for no
trim = 0;
%set threshold for ROI data - values below the threshold are not included
%in the ROI
threshold = .5;

for n = 1:length(subIDs);
    SPM_loc = [subjectpath,subIDs{n},'/SPM.mat'];
    beta_series_correlation_nomars(SPM_loc,ROI_loc,Events,trim,threshold);
end


    
    
    