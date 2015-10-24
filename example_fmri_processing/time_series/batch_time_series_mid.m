clear all;clc;
addspm8('NoConflicts');
addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/time_series/');
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};

extension_dir = 'SPM.mat';
subject_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/GLM/';
event = {'Cue_lose5','Cue_lose1','Cue_lose0','Cue_gain0','Cue_gain1','Cue_gain5'};%start of the time series
TR_type = '';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR2/';
ROI_ext = {'_TR2_SNleft','_TR2_STNleft'};
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/time_series/extracted_time_series_first_3_img/';
number_of_scans_in_series = 3;
%flags to turn on and off selections of high pass filtering and detrending
flag.detrend = 0;%1: will remove mean and linear trend, 2:will remove mean,
flag.filter = 1;

% filter parameters
Ns = 6;  %Number of scans in filter time window
threshold = 0;%drop any value below this threshold

%% MAIN: DO NOT EDIT

for n = 1:length(subjects)
    disp(subjects{n});
    SPM_loc = [subject_dir subjects{n} '/' extension_dir];
    % load SPM.mat to extract information from
    load(SPM_loc);
    % this block of code makes a volume index  - adjusted for the number of
    % scans per block
    block_index = index_images_per_block(SPM);
    % Get header info for all functional data
    SPM.xY.P = char(regexprep(cellstr(SPM.xY.P),'/nfs/jong_exp/','/hsgs/projects/jhyoon1/'));
    V = spm_vol(SPM.xY.P);

    for m=1:length(event)
        disp(event{m});
        % make a folder for each event
        eval(['!mkdir -p ',fullfile(save_dir,event{m})]);
        % function return the location of onset volumns for the give event
        onset_index = mapping_images_from_event_name(SPM,event{m});
        
        % incase ROI_ext is specified only as a character
        if ischar(ROI_ext)
            ROI_ext = cellstr(ROI_ext);
        end
        
        for r = 1:length(ROI_ext)%loop through ROIs
            disp(ROI_ext{r});
            % find the X Y Z index for the ROI - need so we do not need to read the
            % whole image into memory
            if ischar(ROI_ext{r})
                [XYZ,ROImat] = roi_find_index(fullfile(ROI_dir,[subjects{n},ROI_ext{r},'.nii']),threshold);
            elseif iscellstr(ROI_ext{r})
                XYZ = [];
                for kk = 1:length(ROI_ext{r})
                    [A,ROImat] = roi_find_index(fullfile(ROI_dir,[subjects{n},ROI_ext{r}{kk},'.nii']),threshold);
                    XYZ = [XYZ,A];clear A;
                end
            end
            
            % generate XYZ locations for each functional
            % correcting for alignment issues
            funcXYZ = adjust_XYZ(XYZ, ROImat, V);
            % compare funcXYZ and XYZ to see if there is any difference
            COMP = find(cell2mat(cellfun(@(x) any(x(:)-XYZ(:)),funcXYZ,'un',0)));
            for mm = 1:length(COMP)
                fprintf('Volume #%d is misaligned\n',COMP(mm));
            end
                
%             clear XYZ;
%             
%             % extract the ROI for all images
%             for k = 1:size(SPM.xY.P,1)
%                 raw_data(k,:) = spm_get_data(SPM.xY.P(k,:),funcXYZ{k});
%             end
%             
%             clear funcXYZ;
%             
%             % high pass all the roi data;
%             if flag.filter
%                 filtered_data = filter_roi_data(raw_data, block_index, Ns);
%             else
%                 filtered_data = raw_data;
%             end
%             
%             %detrending data
%             switch flag.detrend
%                 case 0
%                     detrended_data = filtered_data;
%                 case 1%remove block/run-wise trend
%                     warning off;
%                     block_end_points = cell2mat(cellfun(@(x) ...
%                         [x(1),x(end)],block_index,'un',0));
%                     detrended_data = detrend(filtered_data,'linear', ...
%                         block_end_points);
%                     warning on;
%                 case 2%remove global trend
%                     detrended_data = detrend(filtered_data);
%             end
%             
%             clear filtered_data raw_data; %save some memory
%             
%             % find mean time series            
%             [all_vox_time_series, mean_time_series] = time_series_extraction(detrended_data, onset_index, block_index, number_of_scans_in_series);
%             
%             % save as csv 
%             csvwrite(fullfile(save_dir,event{m},[subjects{n},'_',...
%                 event{m},'_',ROI_ext{r},'.csv']), mean_time_series);
%             
           clear all_vox_time_series  mean_time_series mean_baseline detrended_data;
        end%rois
    end%events
end%subjects


%%
% for m=2:length(event)
%     %display current event
%     disp(event{m});
%     tmp_save_dir = fullfile(save_dir,event{m});
%     if ~exist(tmp_save_dir,'dir')
%         eval(['!mkdir -p ',tmp_save_dir]);
%     end
%     
%     % extract time series for each ROI
%     for r = 1%:length(ROI_ext)
%         fprintf('%s\n',ROI_ext{r});
%         for n = 1:length(subjects)
%             fprintf('%s\n',subjects{n});
%             SPM_loc = fullfile(subject_dir,subjects{n},extension_dir);
%             ROI_loc = fullfile(ROI_dir,[subjects{n},ROI_ext{r}]);
%             load(SPM_loc);
%             SPM = string_replace(SPM,'/nfs/','/hsgs/projects/jhyoon1/');
%             
%             % this block of code makes a volume index  - adjusted for the number of
%             % scans per block
%             block_index = index_images_per_block(SPM);
%             
%             % find the X Y Z index for the ROI - need so we do not need to read the
%             % whole image into memory
%             [XYZ, ROImat]= roi_find_index(ROI_loc,threshold);
%             % Get header info for all functional data
%             
%             V = spm_vol(SPM.xY.P);
%             
%             % generate XYZ locations for each functional
%             % correcting for alignment issues
%             funcXYZ = adjust_XYZ(XYZ, ROImat, V);
%             
%             % extract the ROI for all images
%             for k = 1:length(SPM.xY.P)
%                 raw_data(k,:) = spm_get_data(SPM.xY.P(k,:),funcXYZ{k});
%             end
%             
%             % high pass all the roi data;
%             if flag.filter
%                 filtered_data = filter_roi_data(raw_data, block_index, Ns);
%                 final_data = filtered_data;%pass onto final_data in case detrending is selected
%             end
%             
%             
%             %detrending data
%             if flag.detrend>0
%                 switch flag.detrend
%                     case 1%remove block/run-wise trend
%                         block_end_points = cell2mat(cellfun(@(x) [x(1),....
%                             x(end)],block_index,'un',0));
%                         detrended_data = detrend(raw_data,'linear', ...
%                             block_end_points);
%                     case 2%remove global trend
%                         detrended_data = detrend(filtered_data);
%                 end
%                 trend = raw_data - detrended_data;
%                 mean_trend = mean(trend(:));
%                 final_data = detrended_data;
%             end
%             
%             %in case neither high pass filter nor detrending data
%             if ~flag.filter && ~(flag.detrend>0)
%                 final_data = raw_data;
%             end
%             
%             % function return the location of onset volumns for the give event
%             [onset_index] = mapping_images_from_event_name(SPM,event{m});
%             
%             
%             [all_vox_time_series, mean_time_series] = time_series_extraction(final_data, onset_index, block_index, number_of_scans_in_series);
%             
%             %eval(['save ', raw_dir, subjects{n},' all_vox_time_series, %mean_time_series']);
%             %cd save_dir
%             csvwrite(fullfile(tmp_save_dir ,[subjects{n},'_',event{m},regexprep(ROI_ext{r},'.nii',''),'.csv']), mean_time_series);
%             
%             clear raw_data; clear mean_time_series; clear all_vox_time_series; clear V; clear funcXYZ; clear XYZ; clear ROImat;
%         end
%     end
% end