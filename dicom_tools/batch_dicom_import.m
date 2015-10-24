% batch dicom import
dicom_dir = '/mnt/proclus_mount_point/midbrain_Stanford_3T/dicoms/M3020_CNI_112713/';
source_folders = {'4_1_BOLD_mux3_15mm_2s','5_1_BOLD_mux3_17mm_2s','6_1_BOLD_mux3_10mm_2s'};
save_dir='/mnt/proclus_mount_point/midbrain_Stanford_3T/funcs/M3020_CNI_112713/';
save_folders = {'stop_signal_run01_1pt5mm_mux','mux_1pt7mm','mux_1pt0mm'};
% do dicom import
for n = 1:length(source_folders)
%% Regular 2D dicoms
    %     dcm2nii_matlab(fullfile(dicom_dir,source_folders{n}),...
    %         fullfile(save_dir,save_folders{n}),'spm8',false);

%% For CNI's 4D .nii.gz files
%     tmp_source_file = dir(fullfile(dicom_dir,source_folders{n},'*.nii.gz'));
%     tmp_source_file = fullfile(dicom_dir,source_folders{n},tmp_source_file.name);
%     spm_gz2nii(tmp_source_file,fullfile(save_dir,save_folders{n}));
%% rename all the files
    renumber_files(fullfile(save_dir,save_folders{n},'*.nii'),4,[],[],[1,2],true);
end
