base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/timeseries_Connectivity_conn/sources/';
grey_mask_target = 'c1resample_r%s_average_TR3.nii';
white_mask_target = 'c2resample_r%s_average_TR3.nii';
csf_mask_target = 'c3resample_r%s_average_TR3.nii';
average_target = 'resample_r%s_average_TR3.nii';

subjects = {'JY_052413_haldol','MM_051013_haldol',...
    'MP021_051713','MP022_051713',...
    'MP023_052013','MP024_052913','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};

ratings = cell(1,numel(subjects));

for s = 20%:length(subjects)
    IMAGES = cell(1,4);
    IMAGES{1} = fullfile(base_dir,sprintf(grey_mask_target,subjects{s}));
    IMAGES{2} = fullfile(base_dir,sprintf(white_mask_target,subjects{s}));
    IMAGES{3} = fullfile(base_dir,sprintf(csf_mask_target,subjects{s}));
    IMAGES{4} = fullfile(base_dir,sprintf(average_target,subjects{s}));
    IMAGES = char(IMAGES);
    CAPTIONS = {'grey','white','csf','average'};
    spm_check_registration(IMAGES,CAPTIONS);
    ratings{s} = input(sprintf('Is %s''s the segmentation good? ',subjects{s}));
%     ratings{s} = questdlg('Is the segmentation good?',...
%         'Segmentation Quality','Yes','No','Yes');
end