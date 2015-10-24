%subjects = {'AT10', 'AT11', 'AT13', 'AT14', 'AT15', 'AT16', 'AT17', 'AT22', 'AT23', 'AT24', 'AT26', 'AT27', 'AT28', 'AT29', 'AT30', 'AT31', 'AT32', 'AT33', 'AT34', 'AT36', 'AT39'};
subjects = {'AT31'};
extension_dir = 'SPM.mat';
subject_dir = '/nfs/u3/SN_loc/model_estimation_no_masking_threshold/';
raw_dir = '/nfs/u3/SN_loc/time_series/percent_sig_change_RedNuc_right/';
ROI_dir = '/nfs/u3/SN_loc/ITK_Snap/';
%ROI_loc = '/nfs/u3/SN_loc/ITK_Snap/SN_left/.nii';
event = 'GreenCue';
number_of_scans_in_series = 10;
Ns = 24;  %Number of scans in filter time window
threshold = 0;

for n = 1:length(subjects);
    SPM_loc = [subject_dir subjects{n} '/' extension_dir];
    save_dir = [raw_dir];
    %ROI_loc = [ROI_dir subjects{n} '_RedNuc_right.nii'];
    load(SPM_loc);
    % FOR STN EXCLUSION %
    ROI_loc1 = [ROI_dir 'STN_left/' subjects{n} '_STN_left.nii'];
    ROI_loc2 = [ROI_dir 'SN_left/' subjects{n} '_thresholded_SNleft.nii'];
    
    % this block of code makes a volume index  - adjusted for the number of
    % scans per block
    block_index = index_images_per_block(SPM);
    
    % find the X Y Z index for the ROI - need so we do not need to read the
    % whole image into memory
    
    % FOR STN EXCLUSION %
    [XYZ1 ROImat1]= roi_find_index(ROI_loc1,threshold);
    [XYZ2 ROImat2]= roi_find_index(ROI_loc2);
    
    %XYZ = exclude_XYZ_address(XYZ1,ROImat1, XYZ2, ROImat2);
    
    % Get header info for all functional data
    
    V = spm_vol(SPM.xY.P);
    
    % generate XYZ locations for each functional
    % correcting for alignment issues
    
    funcXYZ = adjust_XYZ(XYZ, ROImat2, V);
    
    
    % extract the ROI for all images
    for k = 1:length(SPM.xY.P)
        raw_data(k,:) = spm_get_data(SPM.xY.P(k,:),funcXYZ{k});
    end
    
    filtered_data = filter_roi_data(raw_data, block_index, Ns);
    % high pass all the roi data;
    
    % function return the location of onset volumns for the give event
    [onset_index] = mapping_images_from_event_name(SPM,event);
    
    
    [all_vox_time_series, mean_time_series] = time_series_extraction(filtered_data, onset_index, block_index, number_of_scans_in_series);
    
    %eval(['save ', raw_dir, subjects{n},' all_vox_time_series, mean_time_series']);  
    
    %cd save_dir
    csvwrite([save_dir 'test_' subjects{n} '_' 'GreenCue.csv'],mean_time_series);
end
