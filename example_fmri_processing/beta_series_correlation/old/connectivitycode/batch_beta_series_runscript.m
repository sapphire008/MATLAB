clear all;
clc;
addspm5;
%Code Directory
addpath(genpath('/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/irf_analysis_renata/2mm_2x2x2_1stderv_analysis/code/connectivitycode/'))
%Subjects Directory
pathstr = '/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/irf_analysis_renata/2mm_2x2x2_1stderv_analysis/subjects_tw/';
%ROI
roiFiles = '/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/irf_analysis_renata/2mm_2x2x2_1stderv_analysis/rois/func_rois_18c_17sz/irf_c+sz_fwe05_SN_dil1_14_-16_-4.nii';
%SUbject ID Filter
subIDs = dir([pathstr,'*']);
%Regressors of Interest
cues1 = {'irf_vector' 'bf(1)'};
%cues2 = {'CueB' 'bf(1)'};

%Windsorization
trim = 0;

for s = 3:length(subIDs);
    SPM_loc = [pathstr,subIDs(s).name,'/SPM.mat'];
    %ROI_loc = [pathstr,'ROIs/',roiFiles.name];
    beta_series_correlation_nomars(SPM_loc,roiFiles,cues1,trim);
    %beta_series_correlation_nomars(SPM_loc,roiFiles,cues2,trim);
end


    
    
    