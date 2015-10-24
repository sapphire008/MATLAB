addspm8;
subject_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM_with_GO_ONLY/';
subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP120_060513'};
extension_dir = '/SPM.mat';
save_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/ROI_based/';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
ROI_ext = {'_TR2_TG_SNleft.nii','_TR2_TG_STNleft.nii'};

number_of_scans_in_series = 12;
Ns = 24;  %Number of scans in filter time window

%flags to turn on and off selections of high pass filtering and detrending
flag.detrend = 0;% 0 for no detrending, 1 for block-wise detrending, 2 for global detrending
flag.filter = 0;
flag.append_ROI_names = 1;


Ns = 24;  %Number of scans in filter time window
threshold = 0;


for m=1:length(event)
    tmp_save_dir = [save_dir,event{m},'/'];
    mkdir(tmp_save_dir);
    
    for n = 1:length(subjects)
        SPM_loc = [subject_dir subjects{n} '/' extension_dir];
        if ischar(ROI_ext) && ~iscellstr(ROI_ext)
            ROI_ext = {ROI_ext};
        end
        for r = 1:length(ROI_ext)%loop through ROIs
            ROI_loc = [ROI_dir,subjects{n},ROI_ext{r}];
            load(SPM_loc);
            
            % this block of code makes a volume index  - adjusted for the number of
            % scans per block
            block_index = index_images_per_block(SPM);
            
            % find the X Y Z index for the ROI - need so we do not need to read the
            % whole image into memory
            [XYZ ROImat]= roi_find_index(ROI_loc,threshold);
            disp(subjects{n});
            % Get header info for all functional data
            
            V = spm_vol(SPM.xY.P);
            
            % generate XYZ locations for each functional
            % correcting for alignment issues
            
            funcXYZ = adjust_XYZ(XYZ, ROImat, V);
            
            % extract the ROI for all images
            for k = 1:length(SPM.xY.P)
                raw_data(k,:) = spm_get_data(SPM.xY.P(k,:),funcXYZ{k});
            end
            
            % high pass all the roi data;
            if flag.filter
                filtered_data = filter_roi_data(raw_data, block_index, Ns);
                final_data = filtered_data;%pass onto final_data in case detrending is selected
            end
            
            %detrending data
            if flag.detrend>0
                switch flag.detrend
                    case 1%remove block/run-wise trend
                        block_end_points = cell2mat(cellfun(@(x) [x(1),....
                            x(end)],block_index,'un',0));
                        detrended_data = detrend(raw_data,'linear', ...
                            block_end_points);
                    case 2%remove global trend
                        detrended_data = detrend(filtered_data);
                end
                trend = raw_data - detrended_data;
                mean_trend = mean(trend(:));
                final_data = detrended_data;
            end
            
            %in case neither high pass filter nor detrending data
            if ~flag.filter && ~(flag.detrend>0)
                final_data = raw_data;
            end
            
            clear filtered_data detrended_data raw_data; %save some memory
            mean_timeseries = mean(final_data,2);
            
            %plot the time series by blocks
            plot_timeseries(mean_timeseries,'blocks',block_index,...
                'events_time',event_onsets);
            
            %         % function return the location of onset volumns for the give event
            %         [onset_index] = mapping_images_from_event_name(SPM,event{m});
            %
            %
            %         [all_vox_time_series, mean_time_series] = time_series_extraction(filtered_data, onset_index, block_index, number_of_scans_in_series);
            %
            %         %eval(['save ', raw_dir, subjects{n},' all_vox_time_series, %mean_time_series']);
            %         %cd save_dir
            %         csvwrite([tmp_save_dir  subjects{n} '_' event{m} '.csv'], mean_time_series);
            
            %clear mean_time_series all_vox_time_series V funcXYZ XYZ ROImat;
        end
    end
end
