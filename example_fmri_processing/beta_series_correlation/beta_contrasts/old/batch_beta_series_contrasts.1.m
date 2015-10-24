clear all
subject_dir='/nfs/atom/TMS/DPX/analysis/beta_series_multivariate/model_estimation/';
subject_list={  'TC03'  'TC05'  'TC08'  'TC10'  'TC12'  'TC15'  'TC17'  'TC19'  'TC21'  'TC23'  'TC25'  'TC28'  'TC30' ...
    'TC02'  'TC04'  'TC06'  'TC09'  'TC11'  'TC14'  'TC16'  'TC18'  'TC20'  'TC22'  'TC24'  'TC26'  'TC29'};

file_hint01='*Zcorr_wfu_PickAtlas_Left_AmygdalaProbeBX.*';
file_hint02='*Zcorr_wfu_PickAtlas_Left_AmygdalaProbeAX.*';
contrast=[1 -1];
outfile_name='_Zcorr_wfu_PickAtlas_Left_AmygdalaProbeBX-ProbeAX.nii';


for n = 1:length(subject_list),
    source_path=[subject_dir, subject_list{n}, '/'];
    file01=dir([source_path, file_hint01]);
    file02=dir([source_path, file_hint02]);
    file_list=[source_path file01(1).name; source_path file02(1).name];
    beta_series_contrasts(file_list,contrast,[source_path subject_list{n} outfile_name]);
end