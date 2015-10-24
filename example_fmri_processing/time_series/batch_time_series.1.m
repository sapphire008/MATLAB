subjects = {'spic410', 'spic413', 'spic414', 'spic415', 'spic416', 'spic417', 'spic418', 'spic419', 'spic420', 'spic422', 'spic433', 'spic434', 'spic435', 'spic436', 'spic437', 'spic443', 'spic447', 'spic448', 'spic451', 'spic458', 'spic459', 'spic463', 'spis107', 'spis110', 'spis112', 'spis122', 'spis128', 'spis129', 'spis131', 'spis137', 'spis140', 'spis141', 'spis150', 'spisu102', 'spisu103', 'spisu104', 'spisu115', 'spisu124', 'spisu127', 'spisu132', 'spisu133', 'spisu134', 'spisu146', 'spisu147', 'spisu154', 'spisu156'};

extension_dir = '/SPM.mat';
subject_dir = '/nfs/spi/SPIT/analysis/subjects_all/subjects_peak_delay_cue_only/';
raw_dir = '/tmp/';
ROI_loc = '/nfs/spi/SPIT/ROIs/sphere_5-51_30_24_Right_anterior_DLPFC.nii';
event = 'C_SmRw';cd
number_of_scans_in_series = 12;
Ns = 24;  %Number of scans in filter time window

for n = 1:length(subjects);
    
    SPM_loc = [subject_dir subjects{n} extension_dir];
    save_dir = [raw_dir subjects{n} '/'];
    load(SPM_loc);
    
    % this block of code makes a volume index  - adjusted for the number of
    % scans per block
    block_index = index_images_per_block(SPM);
    
    % find the X Y Z index for the ROI - need so we do not need to read the
    % whole image into memory
    XYZ = roi_find_index(ROI_loc);
    
    % extract the ROI for all images
    raw_data = spm_get_data(SPM.xY.P,XYZ);
    
    %detrended_data = detrend();
    
    % high pass all the roi data
   % filtered_data = filter_roi_data(raw_data, block_index, Ns);
    
    % function return the location of onset volumns for the give event
    [onset_index] = mapping_images_from_event_name(SPM,event);
    
    
    [all_vox_time_series, mean_time_series] = time_series_extraction(filtered_data, onset_index, block_index, number_of_scans_in_series);
    
    eval(['save ', raw_dir, subjects{n},' all_vox_time_series, mean_time_series'})  
    
    %cd save_dir
    csvwrite([save_dir '6vox_' subjects{n} '_' 'event.csv'],mean_time_series);
end
