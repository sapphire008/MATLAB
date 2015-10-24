% percent signal change of each condition
clear all;clc;
%addspm8('NoConflicts');
subject_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/GLM/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
extension_dir = '/SPM.mat';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/percent_signal_change/';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/VTA_ROI_localization/ROIs/TR2/';


ROI_ext = {'_TR2_SNleft','_TR2_STNleft','_TR2_RNleft',...
    '_TR2_SNright','_TR2_STNright','_TR2_RNright',...
    '_TR2_VTAleft','_TR2_VTAright','_TR2_VTAbilateral',...
    '_TR2_VTAleft_extended','_TR2_VTAright_extended','_TR2_VTAbilateral_extended',...
    '_TR2_SNVTAleft','_TR2_SNVTAright','_TR2_SNVTAbilateral',...
    '_TR2_VTA_blob','_TR2_SNVTA_blob'};
ROI_names = {'SNleft','STNleft','RNleft','SNright','STNright','RNright',...
    'VTAleft','VTAright','VTAbilateral','VTAleft_extended',...
    'VTAright_extended','VTAbilateral_extended','SNVTAleft',...
    'SNVTAright','SNVTAbilateral','VTA_blob','SNVTA_blob'};

% ROI_ext = {'_SNleft','_STNleft','_RNleft',...
%     '_VTAleft',{'_VTAleft','_VTAleft_ext'},...
%     {'_VTAleft','_VTAleft_ext','_Bridgeleft'},...
%     {'_SNleft','_VTAleft'},{'_SNleft','_VTAleft','_VTAleft_ext'},...
%     {'_SNleft','_VTAleft','_VTAleft_ext','_Bridgeleft'}};
% ROI_names = {'SNleft','STNleft','RNleft','VTAleft','VTA_extended',...
%     'VTAleft_blob','SNVTAleft','SNVTAleft_extended','SNVTAleft_blob'};
event = {'Cue_lose5','Cue_lose1','Cue_lose0','Cue_gain0','Cue_gain1','Cue_gain5'};

number_of_scans_in_series = 2;% how many time points to extract after the onset of each event
Ns = 24;  %Number of scans in filter time window, usually filter twice the number of scans

%flags to turn on and off selections of high pass filtering and detrending
flag.detrend = 0;% 0 for no detrending, 1 for block-wise detrending, 2 for global detrending
flag.filter = 0;%butterworth filtering
threshold = 0;%ROI threhold, drop any value in ROI below threhold 

%% MAIN: DO NOT EDIT
worksheet = cell(length(subjects)+1,length(event)+1);
worksheet(1,:) = [{'Subjects'},event];
MEAN = cell2struct(repmat({worksheet},1,length(ROI_names)),ROI_names,2);
%STDEV = cell2struct(repmat({worksheet},1,length(ROI_names)),ROI_names,2);
SE = cell2struct(repmat({worksheet},1,length(ROI_names)),ROI_names,2);
clear worksheet;
for n = 25%:length(subjects)
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
    % logging subject

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
            disp(ROI_names{r});
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
            clear XYZ;
            
            % extract the ROI for all images
            for k = 1:size(SPM.xY.P,1)
                raw_data(k,:) = spm_get_data(SPM.xY.P(k,:),funcXYZ{k});
            end
            
            clear funcXYZ;
            
            % high pass all the roi data;
            if flag.filter
                filtered_data = filter_roi_data(raw_data, block_index, Ns);
            else
                filtered_data = raw_data;
            end
            
            %detrending data
            switch flag.detrend
                case 0
                    detrended_data = filtered_data;
                case 1%remove block/run-wise trend
                    block_end_points = cell2mat(cellfun(@(x) [x(1),....
                        x(end)],block_index,'un',0));
                    detrended_data = detrend(filtered_data,'linear', ...
                        block_end_points);
                case 2%remove global trend
                    detrended_data = detrend(filtered_data);
            end
            
            clear filtered_data raw_data; %save some memory
            
            % find mean baseline
            mean_baseline = mean(detrended_data(:));
            
            % find mean time series            
            [all_vox_time_series, mean_time_series] = time_series_extraction(detrended_data, onset_index, block_index, number_of_scans_in_series);
            
            % log percent signal change
            MEAN.(ROI_names{r}){n+1,1} = subjects{n};
            MEAN.(ROI_names{r}){n+1,m+1} = (mean(mean_time_series(:))-mean_baseline)/mean_baseline*100;
            SE.(ROI_names{r}){n+1,1} = subjects{n};
            SE.(ROI_names{r}){n+1,m+1} = std(mean(mean_time_series,2),1,1)/sqrt(size(mean_time_series,1))/mean_baseline*100;
            % save the result
            save(fullfile(save_dir,event{m},[subjects{n},'_',event{m},...
                '_',ROI_names{r},'.mat']),'all_vox_time_series',...
                'mean_time_series','mean_baseline');
            % save as csv 
            csvwrite(fullfile(save_dir,event{m},[subjects{n},'_',...
                event{m},'_',ROI_names{r},'.csv']), mean_time_series);
            
           clear all_vox_time_series  mean_time_series mean_baseline detrended_data;
        end%rois
    end%events
end%subjects
% save reulsts
save(fullfile(save_dir,['summary_matrix_',datestr(now,'mm-dd-yyyy_HH-MM-SS'),'.mat']),'MEAN','SE');

%% write summary result to csv
F = fieldnames(MEAN);
for f = 1:length(F)
    cell2csv(fullfile(save_dir,[F{f},'_MEAN.csv']),MEAN.(F{f}),',');
    cell2csv(fullfile(save_dir,[F{f},'_SE.csv']),SE.(F{f}),',');
end
clear MEAN SE;






















