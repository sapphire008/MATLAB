base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
func_type = '_Z_test_';
func_target = 'w%s%sTR*%s*.nii';

condnames = {'SNleft_Fixation','SNleft_ZeroBack','SNleft_OneBack','SNleft_TwoBack',...
    'STNleft_Fixation','STNleft_ZeroBack','STNleft_OneBack','STNleft_TwoBack'};
ROI_loc = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/Functional_ROI/';
ROI_targets = {'Caudateleft_1_8489_2_SNleft_RissCon_Patient-Control_TwoBack-Fixation.nii',...
    'Insularight_1_8489_2_SNleft_RissCon_Patient-Control_TwoBack-Fixation.nii'};
ROI_names = {'Caudate','Insula'};

save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/Functional_ROI/';


% initialize worksheet
addmatlabpkg('spmnifti');addmatlabpkg('fMRI_pipeline');addmatlabpkg('ReadNWrite');
for r = 1:length(ROI_targets)
    XYZ = get_roi_info(fullfile(ROI_loc,ROI_targets{r}));
    worksheet = cell(numel(subjects)+1,numel(condnames)+1);
    worksheet(2:end,1) = subjects;
    worksheet(1,2:end) = condnames;
    worksheet{1,1} = ROI_names{r};
    for s = 1:length(subjects)
        fprintf('%s\n',subjects{s});
        for c = 1:length(condnames)
            % search file
            P = SearchFiles(fullfile(base_dir,subjects{s}),...
                sprintf(func_target,subjects{s},func_type,condnames{c}));
            % extract values
            Y = spm_get_data(spm_vol(char(P)),XYZ);
            worksheet{s+1,c+1} = nanmean(Y,2);
            clear P Y;
        end
    end
    clear XYZ;
    % save the worksheet
    save_name = fullfile(save_dir,sprintf(...
        'ROI_values_of_Connectivity_maps%s_at_%s.csv',func_type,ROI_names{r}));
    save_name = regexprep(save_name,'__','_');
    cell2csv(save_name,worksheet,',','w');
end


