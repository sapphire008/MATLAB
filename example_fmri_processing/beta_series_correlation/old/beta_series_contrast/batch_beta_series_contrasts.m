clear all
subject_dir='/nfs/jong_exp/PFC_basalganglia/TMS_Study/Mike_postTMS/analysis/4POP/beta_series_correlations/';
subject_list={'2mm','8mm'};

file_hint01='*R_atanh_corr_SNLeftRedShortCue*';
file_hint02='*R_atanh_corr_SNLeftGreenShortCue*';
contrast=[1 -1];
outfile_name='_R_atanh_corr_SNLeftRed-GreenCue.nii';


for n = 1:length(subject_list),
    source_path=[subject_dir, subject_list{n}, '/'];
    file01=dir([source_path, file_hint01]);
    file02=dir([source_path, file_hint02]);
    file_list=[source_path file01(1).name; source_path file02(1).name];
    beta_series_contrasts(file_list,contrast,[source_path subject_list{n} outfile_name]);
end