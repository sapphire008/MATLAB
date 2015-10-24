% rmpath(genpath(addmatlabpkg('spm8')));
% addspm8('NoConflicts');
% addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/beta_series/');
clear;clc;

GLM_type = '_Cue_Feedback'; %'_Cue_Feedback' or '_Cue_Response' or ''
% ROI_ext = {'_SNleft','_STNleft','_RNleft',...
%     '_VTAleft',{'_VTAleft','_VTAleft_ext'},...
%     {'_VTAleft','_VTAleft_ext','_Bridgeleft'},...
%     {'_SNleft','_VTAleft'},{'_SNleft','_VTAleft','_VTAleft_ext'},...
%     {'_SNleft','_VTAleft','_VTAleft_ext','_Bridgeleft'}};
% ROI_names = {'SNleft','STNleft','RNleft','VTAleft','VTA_extended',...
%     'VTAleft_blob','SNVTAleft','SNVTAleft_extended','SNVTAleft_blob'};
% ROI_ext = {'_TR2_SNleft','_TR2_STNleft','_TR2_RNleft',...
%     '_TR2_SNright','_TR2_STNright','_TR2_RNright',...
%     '_TR2_VTAleft','_TR2_VTAright','_TR2_VTAbilateral',...
%     '_TR2_VTAleft_extended','_TR2_VTAright_extended','_TR2_VTAbilateral_extended',...
%     '_TR2_SNVTAleft','_TR2_SNVTAright','_TR2_SNVTAbilateral',...
%     '_TR2_VTA_blob','_TR2_SNVTA_blob'};
ROI_ext = {'_SNleft','_STNleft','_RNleft','_VTAleft',{'_VTAleft','_VTAleft_extended'},...
    {'_SNleft','_VTAleft'},{'_SNleft','_VTAleft','_VTAleft_extended'}};
ROI_name = {'_SNleft','_STNleft','_RNleft','_VTAleft','_VTAleft_extended',...
    '_SNVTAleft','_SNVTAleft_extended'};
% ROI_ext = {'_TR2_SNleft_peakvoxel','_TR2_STNleft_peakvoxel',...
%     '_TR2_RNleft_peakvoxel','_TR2_SNright_peakvoxel',...
%     '_TR2_STNright_peakvoxel','_TR2_RNright_peakvoxel',...
%     '_TR2_VTAleft_peakvoxel','_TR2_VTAright_peakvoxel',...
%     '_TR2_VTAbilateral_peakvoxel','_TR2_VTAleft_extended_peakvoxel',...
%     '_TR2_VTAright_extended_peakvoxel',...
%     '_TR2_VTAbilateral_extended_peakvoxel','_TR2_SNVTAleft_peakvoxel',...
%     '_TR2_SNVTAright_peakvoxel','_TR2_SNVTAbilateral_peakvoxel',...
%     '_TR2_VTA_blob_peakvoxel','_TR2_SNVTA_blob_peakvoxel'};

%ROI_ext = {{'CaudateHeadLeft','CaudateHeadRight'},{'PutamenLeft','PutamenRight'}};

subjects = {'M3126_CNI_052314','M3039_CNI_052714','M3039_CNI_061014','M3128_CNI_060314','M3129_CNI_060814'};
TRs = {'TR2','TR2','TR2','TR2'};%which folder the ROIs are in
extension_dir = '/SPM.mat';
subject_dir = ['/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/analysis/GLM',GLM_type,'/'];
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/';
results_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/analysis/beta_series/extracted_betas_all_ROIs_Cue_Feedback/';

%% Main Beta Extraction Algorithm
for n = 1%:length(subjects)
    %display subject ID
    disp(subjects{n});
    
    SPM_loc = [subject_dir subjects{n} extension_dir];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(SPM_loc);
    
    [beta_idx, beta_names] = group_beta_images_by_block_condition_basis(SPM);
    
    csv_results = cell(1,length(ROI_ext));
    for r = 1:length(ROI_ext)
        % find the X Y Z index for the ROI - need so we do not need to read the
        % whole image into memory
        if ischar(ROI_ext{r})
            ROI_loc = SearchFiles(fullfile(ROI_dir,TRs{n}),[subjects{n},'*',TRs{n},ROI_ext{r},'.nii']);
            if isempty(ROI_loc)
                warning('%s %s does not exist\n',subjects{n},ROI_ext{r});
                continue;
            elseif numel(ROI_loc)>1
                warning('%s %s has multiple ROIs\n',subjects{n},ROI_ext{r});
                continue;
            end
            XYZ = roi_find_index(ROI_loc);
        else
            % find the union of the ROI
            XYZ = [];
            for kk = 1:length(ROI_ext{r})
                ROI_loc = SearchFiles(fullfile(ROI_dir,TRs{n}),[subjects{n},'*',TRs{n},ROI_ext{r}{kk},'.nii']);
                if isempty(ROI_loc)
                    warning('%s %s does not exist\n',subjects{n},ROI_ext{r}{kk});
                    continue;
                elseif numel(ROI_loc)>1
                    warning('%s %s has multiple ROIs\n',subjects{n},ROI_ext{r}{kk});
                    continue;
                end
                XYZ = [XYZ,roi_find_index(ROI_loc)];
            end
        end
        % build paths to beta images beta images
        files = char(SPM.Vbeta.fname);
        beta_path = repmat([SPM.swd,'/'],size(files,1),1);
        beta_path = [beta_path,files];
        % extract ROI data for all beta images
        raw_data = spm_get_data(beta_path,XYZ);
        mean_data = nanmean(raw_data,2)';
        
        if (~exist('ROI_name','var') || isempty(ROI_name))
            if iscellstr(ROI_ext)
                ROI_name = ROI_ext;
            else
                error('Please specify ROI_names')
            end
        end
        
        IND = cellfun(@(x) ~strcmpi(x(1),'_'),ROI_name);
        ROI_name(IND) = cellfun(@(x) ['_',x],ROI_name(IND),'un',0);
        
        csv_results{r} = fullfile(results_dir,[subjects{n},ROI_name{r},'.csv']);
        fid = fopen(csv_results{r}, 'w');
        
        for k = 1:size(beta_idx,1),
            beta_mean(k,:) = mean_data(beta_idx(k,:));%take only the first column which corresponds to bf(1)
            fprintf(fid,'%s,',beta_names{k}(1:4));
            fprintf(fid,'%s,',beta_names{k}(6:end));
            fprintf(fid,'%g,',beta_mean(k,:));
            fprintf(fid,'\n');
        end
        
        fclose(fid);
        
        save([results_dir,subjects{n},ROI_name{r},'.mat'],'beta_names','beta_mean', 'raw_data');
    end
    
    % summarize all the data in one sheet
    worksheet = [];
    for r = 1:length(csv_results)
        T = ReadTable(csv_results{r});
        if strcmpi(ROI_name{r}(1),'_')
            roi_name = ROI_name{r}(2:end);
        else
            roi_name = ROI_name{r};
        end
        worksheet = [worksheet;[repmat({roi_name},size(T,1),1),T]];
        clear T;
    end
    cell2csv(fullfile(results_dir,['summary_',subjects{n},'.csv']),worksheet,',');
end
