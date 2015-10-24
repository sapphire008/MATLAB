%compare dicom and reconstructed nifti
clear all;clc;
addmatlabpkg('NIFTI');
addpath /nfs/midbrain_highres_7t/scripts/dicom_tools/;
dicom_folders = {'003_2D_GE_EPI_1mmiso_R3_26slices',...
    '004_2D_GE_EPI_1mmiso_R3_26slices_PE_SI',...
    '005_2D_GE_EPI_1mmiso_R3_26slices_2shots',...
    '007_2D_GE_EPI_1mmiso_R3_26slices_2shots',...
    '008_2D_GE_EPI_1mmiso_R3_26slices_2shots',...
    '009_2D_GE_EPI_1mmiso_R3_26slices_PE_SI',...
    '010_2D_GE_EPI_1mmiso_R3_26slices_3shots',...
    '011_2D_GE_EPI_1mmiso_R3_26slices_3shots',...
    '012_2D_GE_EPI_1pt5mmiso_R3_26slices_PE_SI',...
    '013_2D_GE_EPI_1mmiso_R3_26slices_3shots',...
    '014_2D_GE_EPI_1mmiso_R3_26slices_3shots'};

nifti_folders = {'run01','run02','run03','run04','run05','run06','run07',...
    'run08','run09','run10','stop_signal_run1'};

dicom_dir = '/nfs/midbrain_highres_7t/dicoms/M7020_110113/';
nifti_dir = '/nfs/midbrain_highres_7t/test_drive/funcs/M7020_110113/';
tags = {'TriggerTime','SeriesNumber','AcquisitionNumber',...
    'AcquisitionTime','NumberOfAcquisitions','LocationsInAcquisition',...
    'InstanceNumber','ImagesInAcquisition','NumberOfTemporalPositions',...
    'StackID','InStackPositionNumber','FileName'};

%%
for f = 6:length(dicom_folders)
disp(dicom_folders{f});
dicom_files = dir(fullfile(dicom_dir,dicom_folders{f},'*.dcm'));
dicom_files = {dicom_files.name};
dicom_files = cellfun(@(x) fullfile(dicom_dir,dicom_folders{f},x),dicom_files,'un',0);
nifti_files = dir(fullfile(nifti_dir,nifti_folders{f},'00*.nii'));
nifti_files = {nifti_files.name};
nifti_files = cellfun(@(x) fullfile(nifti_dir,nifti_folders{f},x),nifti_files,'un',0);
%get info from the first image. Assuming that all images in this folder is
%from the same sequence
dicom_header = dicom_header_matlab(dicom_files,tags,false);
num_slices = dicom_header(1).LocationsInAcquisition;
num_vols = dicom_header(1).NumberOfTemporalPositions;

all_images_are_okay=true;%assuming all images are okay so far

for n = 1:length(nifti_files)
    nifti_3D=load_untouch_nii(nifti_files{n});
    for m = 1:num_slices
        ind = m+(n-1)*num_slices;
        %calculate the difference between each slices
        dicom_slice = dicomread(fullfile(dicom_dir,dicom_folders{f},dicom_header(ind).FileName));
        nifti_slice = rot90(squeeze(nifti_3D.img(:,:,m)));
        diff_slice = dicom_slice-nifti_slice;
        if any(diff_slice(:))
            fprintf('dicom image:%s, slice:%d\n',dicom_header(ind).FileName,m);
            all_images_are_okay = false;
        end
        clear dicom_slice nifti_slice diff_slice;
        %         figure;
        %         subplot(3,1,1);
        %         imshow(dicom_slice);
        %         xlabel('Dicom\_slice');
        %         subplot(3,1,2);
        %         imshow(nifti_slice);
        %         xlabel('Nifti\_slice');
        %         subplot(3,1,3);
        %         imshow(diff_slice);
        %         xlabel('Difference\_slice');
        
        
    end
    clear nifti_3D;
end
end