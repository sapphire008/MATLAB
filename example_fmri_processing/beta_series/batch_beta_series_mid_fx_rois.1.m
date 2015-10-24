% rmpath(genpath(addmatlabpkg('spm8')));
% addspm8('NoConflicts');
% addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/beta_series/');
clear all;clc;

GLM_type = '';% '_Cue_Feedback' or '_Cue_Response' or ''

ROI_ext = {{'CaudateHeadLeft','CaudateHeadRight'},{'PutamenLeft','PutamenRight'}};
ROI_name = {'CaudateHead','Putamen'};

subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
TRs = repmat({''},1,numel(subjects));
extension_dir = '/SPM.mat';
subject_dir = ['/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/GLM',GLM_type,'/'];
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/SecondLevel/striatum_functional_ROIs/';
results_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/beta_series/extracted_betas_striatum_fxROIs/';

%% Main Beta Extraction Algorithm
for n = 1:length(subjects)
    %display subject ID
    disp(subjects{n});
    
    SPM_loc = [subject_dir subjects{n} extension_dir];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(SPM_loc);
    
    [beta_idx, beta_names] = group_beta_images_by_block_condition_basis(SPM);
    
    for r = 1:length(ROI_ext)
        % find the X Y Z index for the ROI - need so we do not need to read the
        % whole image into memory
        if ischar(ROI_ext{r})
            ROI_loc = SearchFiles(fullfile(ROI_dir,TRs{n}),[subjects{n},'*',ROI_ext{r},'.nii']);
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
                ROI_loc = SearchFiles(fullfile(ROI_dir,TRs{n}),[subjects{n},'*',ROI_ext{r}{kk},'.nii']);
                if isempty(ROI_loc)
                    warning('%s %s does not exist\n',subjects{n},ROI_ext{r}{kk});
                    continue;
                elseif numel(ROI_loc)>1
                    warning('%s %s has multiple ROIs\n',subjects{n},ROI_ext{r}{kk});
                    continue;
                end
                XYZ = [XYZ,roi_find_index(ROI_loc)];
            end
            XYZ = XYZ'; XYZ = unique(XYZ,'rows'); XYZ = XYZ';
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
        
        fid = fopen([results_dir,subjects{n},ROI_name{r},'.csv'], 'w');
        
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
end
