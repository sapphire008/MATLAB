subjects = {'AT10'};

extension_dir = '/SPM.mat';
subject_dir = '/nfs/u3/SN_loc/model_estimation_no_masking_threshold/';
raw_dir = '/tmp/';
ROI_loc = '/nfs/u3/SN_loc/ITK_Snap/SN_left/AT10_SNleft_unsmoothed_placebo.nii';
event = 'GreenCue';
number_of_scans_in_series = 12;
Ns = 24;  %Number of scans in filter time window

for n = 1:length(subjects);
    
    SPM_loc = [subject_dir subjects{n} extension_dir];
    save_dir = [raw_dir subjects{n} '/'];
    load(SPM_loc);
    
    % this block of code makes a volume index  - adjusted for the number of
    % scans per block
    block_index = index_images_per_block(SPM);
    block_end_points = [];
    for k = 1:length(block_index)
        block_end_points = [block_end_points block_index{k}(1) block_index{k}(end)];
    end
        
    
    % find the X Y Z index for the ROI - need so we do not need to read the
    % whole image into memory
    XYZ = roi_find_index(ROI_loc);
    
    % extract the ROI for all images
    raw_data = spm_get_data(SPM.xY.P,XYZ);
    
%     detrended_data = detrend(raw_data,'linear', block_end_points);
%     trend = raw_data - detrended_data;
%     mean_trend = mean(trend(:));
%     
%     
%     % high pass all the roi data
%     filtered_data = filter_roi_data(raw_data, block_index, Ns);
    
    % function return the location of onset volumns for the give event
    [onset_index] = mapping_images_from_event_name(SPM,event);
    
    
    [all_vox_time_series, mean_time_series] = time_series_extraction(raw_data, onset_index, block_index, number_of_scans_in_series);
    
    for k = 1:size(all_vox_time_series,1)
        time_series(k,:) = mean(squeeze(all_vox_time_series(k,:,:)));
    end
    
    eval(['save ', raw_dir, subjects{n},' all_vox_time_series, mean_time_series, time_series'})  
    
    %cd save_dir
    csvwrite([save_dir '6vox_' subjects{n} '_' 'event.csv'],mean_time_series);
end
