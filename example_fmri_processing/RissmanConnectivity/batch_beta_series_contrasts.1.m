clear all
subject_dir='/nfs/jong_exp/PFC_basalganglia/TMS_Study/Mike_postpost2_TMS/analysis/4POP/beta_series_correlations/';
subject_list={'2mm','8mm'};

file_hint01='R_atanh_corr_SNleftCueGreen*';
file_hint02='R_atanh_corr_SNleftCueRed*';
contrast=[-1 1];
outfile_name='R_atanh_corr_SNleftCueRed-Green.nii';


for n = 1:length(subject_list),
    source_path=[subject_dir, subject_list{n}, '/'];
    file01=dir([source_path, file_hint01]);
    file02=dir([source_path, file_hint02]);
    file_list{1} =[source_path file01(1).name]; 
    file_list{2} =[source_path file02(1).name];
    beta_series_contrasts(file_list,contrast,[source_path outfile_name]);
    
    clear file_list{1} file_list{2} file01 file02 source_path
end

% subjects = {'AT10','AT11','AT13', 'AT14', 'AT15', 'AT17', 'AT22', 'AT23', 'AT24', 'AT26', 'AT29', 'AT30' 'AT31', 'AT32', 'AT33','AT36'};
% startingdir = '/nfs/sn_loc/analysis/beta_series_correlations/8mm/'
% targetdir = '/nfs/sn_loc/analysis/normalizations/8mm/'
% for n = 1:length(subjects)
%     eval(['!cp ' startingdir subjects{n} '/R_atanh_corr/*RN* ' targetdir subjects{n} '/multivariate/native_space/']);
% end