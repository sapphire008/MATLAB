% top level directory for subject beta images
subjectpath = '/nfs/sn_loc/analysis/model_estimation_trialwise_unsmoothed/';

% the seed image - must be in the same space as beta images
Seed_loc = '/nfs/sn_loc/subjects/ITK_Snap/';
Seed_name = {'SN','STN', 'RN'};
% write resulte to
pathstr = '/nfs/sn_loc/analysis/beta_series_correlations/unsmoothed';
% cell array of subject ID's
%subIDs = {'AT10'};
subIDs = {'AT10','AT11','AT13','AT14','AT15','AT17','AT22','AT23','AT24','AT26','AT29','AT30','AT31','AT32','AT33','AT36'};
% Cue information
allevents = {{'GreenCue' 'bf(1)'} {'RedCue' 'bf(1)'} {'GreenDelay' 'bf(1)'} {'RedDelay' 'bf(1)'} {'GreenProbe' 'bf(1)'} {'RedProbe' 'bf(1)'}};
%Events = {'GreenCue' 'bf(1)'};
% Apply Trim? 1 for yes 0 for no
trim = 0;
%set threshold for ROI data - values below the threshold are not included
%in the ROI
threshold = 0;
for s = 1:length(Seed_name)
    for k = 1:length(allevents)
        Events = allevents{k};
        for n = 1:length(subIDs);
            SPM_loc = [subjectpath,subIDs{n},'/SPM.mat'];
            load(SPM_loc);
            Seed_mask = [Seed_loc, Seed_name{s} '/' subIDs{n} '_' Seed_name{s} 'left.nii'];
            [Cout, sqrtN] = beta_series_correlation_nomars(SPM,Seed_mask,Events{1},trim,threshold);
            
            [foo,roiLabel,ext] = fileparts(Seed_mask);
            % output R correlation results to image
            corr_file = fullfile([pathstr,'/'],['Rcorr_',roiLabel,Events{1},'.nii']);
            writeCorrelationImage(Cout,corr_file, SPM.xVol);
            
            % output R correlation results to image
            corr_file = fullfile([pathstr,'/'],['R_atanh_corr_',roiLabel,Events{1},'.nii']);
            writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);
            
            % output Z correlation results to image
            corr_file = fullfile([pathstr,'/'],['Zcorr_',roiLabel,Events{1},'.nii']);
            writeCorrelationImage((atanh(Cout)*sqrtN),corr_file, SPM.xVol);
        end
    end
end