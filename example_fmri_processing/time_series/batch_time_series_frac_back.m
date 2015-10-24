%addspm8
clear all;clc;
subjects = {'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
%subjects = {'MP020_050613'};

extension_dir = 'SPM.mat';
subject_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/GLM/';
event = {'ZeroBack','OneBack','TwoBack','NULL'};
TR_type = 'TR3';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/';
ROI_ext = {'SNleft.nii','STNleft.nii'};%older task structure
%ROI_ext = {'_TR3_SNleft.nii','_TR3_STNleft.nii'};
save_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/extracted_timeseries/';

%flags to turn on and off selections of high pass filtering and detrending
flag.detrend = 0;
flag.filter = 1;

% filter parameters
Ns = 24;  %Number of scans in filter time window
threshold = 0;%drop any value below this threshold



ROI_dir = fullfile(ROI_dir,TR_type);
ROI_ext = cellfun(@(x) ['_',TR_type,'_',x],ROI_ext,'un',0);
for m=1:length(event)
    %display current event
    disp(event{m});
    tmp_save_dir = fullfile(save_dir,event{m});
    if ~exist(tmp_save_dir,'dir')
        eval(['!mkdir -p ',tmp_save_dir]);
    end
    
    %change number of scans by event
    switch event{m}
        case {'NULL'}
            switch TR_type
                case {'TR2'}
                    number_of_scans_in_series = 8;
                case {'TR3'}
                    number_of_scans_in_series = 5;
            end
        otherwise
            switch TR_type
                case {'TR2'}
                    number_of_scans_in_series = 9;
                case {'TR3'}
                    number_of_scans_in_series = 10;
            end
    end
    
    % extract time series for each ROI
    for r = 1:length(ROI_ext)
        fprintf('%s\n',ROI_ext{r});
        for n = 1:length(subjects)
            fprintf('%s\n',subjects{n});
            SPM_loc = fullfile(subject_dir,subjects{n},extension_dir);
            ROI_loc = fullfile(ROI_dir,[subjects{n},ROI_ext{r}]);
            load(SPM_loc);
            
            % this block of code makes a volume index  - adjusted for the number of
            % scans per block
            block_index = index_images_per_block(SPM);
            
            % find the X Y Z index for the ROI - need so we do not need to read the
            % whole image into memory
            [XYZ, ROImat]= roi_find_index(ROI_loc,threshold);
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
            
            % function return the location of onset volumns for the give event
            [onset_index] = mapping_images_from_event_name(SPM,event{m});
            
            
            [all_vox_time_series, mean_time_series] = time_series_extraction(final_data, onset_index, block_index, number_of_scans_in_series);
            
            %eval(['save ', raw_dir, subjects{n},' all_vox_time_series, %mean_time_series']);
            %cd save_dir
            csvwrite(fullfile(tmp_save_dir ,[subjects{n},'_',event{m},regexprep(ROI_ext{r},'.nii',''),'.csv']), mean_time_series);
            
            clear raw_data; clear mean_time_series; clear all_vox_time_series; clear V; clear funcXYZ; clear XYZ; clear ROImat;
        end
    end
end
