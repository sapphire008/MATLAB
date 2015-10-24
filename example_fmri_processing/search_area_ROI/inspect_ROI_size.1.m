base_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
ROI_suffix = '_TR2_ACPC_SNleft_STNleft.nii';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113'};

X=cell(length(subjects),1);
Y=cell(length(subjects),1);
Z=cell(length(subjects),1);
addpath('/nfs/pkg64/contrib/nifti/');
for s = 1:length(subjects)
    ROI = load_nii(fullfile(base_dir,[subjects{s},ROI_suffix]));
    [X{s},Y{s},Z{s}] = ind2sub(size(ROI.img),find(ROI.img));
end

X_max = max(cellfun(@max, X));
X_min = min(cellfun(@min, X));

Y_max = max(cellfun(@max, Z));
Y_min = min(cellfun(@min, Z));

Z_max = max(cellfun(@max, Z));
Z_min = min(cellfun(@min, Z));

%X  120:86-->85:120
%Y  129:67-->65:130
%Z  129:67-->65:130