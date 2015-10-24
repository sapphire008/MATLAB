% batch create SNR images
clear all;clc;
warning off;
addmatlabpkg('fMRI_pipeline');
rmpath(genpath(addmatlabpkg('spm8')));
rmpath(genpath(addmatlabpkg('spm12b')));
addmatlabpkg('spmnifti');
warning on;
ls /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/SNR_analysis/;
image_dirs = {'/hsgs/projects/jhyoon1/midbrain_Stanford_3T/RestingState/subjects/funcs/M3020_CNI_031714/',...
    '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/test_drive/subjects/funcs/M3020_CNI_031714/BOLD_EPI_18mm_tr3/',...
    '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/test_drive/subjects/funcs/M3020_CNI_031714/BOLD_EPI_20mm_iso_tr3/',...
    {'/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/subjects/funcs/M3020_CNI_031714/block1/',...
    '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/subjects/funcs/M3020_CNI_031714/block2/'},...
    {'/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/subjects/funcs/M3020_CNI_031714/block1/',...
    '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/subjects/funcs/M3020_CNI_031714/block2/'}};
image_names = {'M3020_CNI_031714_RestingState_mux_tSNR.nii',...
    'M3020_CNI_031714_testdrive_18mm_tSNR.nii','M3020_CNI_031714_testdrive_20mm_tSNR.nii',...
    'M3020_CNI_031714_mid_tSNR.nii','M3020_CNI_031714_stopsignal_tSNR.nii'};
target_files = 'ra*.nii';
save_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/QA/M3020_CNI_031714/';

for n = 4:length(image_dirs)
    fprintf('%d/%d\n',n,length(image_dirs));
    if ischar(image_dirs{n})
        image_dirs{n} = cellstr(image_dirs{n});
    end
    % get a list of files to be used
    P = [];
    for m = 1:length(image_dirs{n})
        P = [P,SearchFiles(image_dirs{n}{m},target_files)];
    end
    if isempty(P)
        warning('%s is empty! Skipped...\n',char(image_dir{n}));
    end
    Q = fullfile(save_dir,image_names{n});
    % make the SNR image
    spm_img_snr(char(P),Q,2);
end
