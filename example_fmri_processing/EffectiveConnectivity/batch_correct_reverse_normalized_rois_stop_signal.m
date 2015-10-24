% correct ROI reverse normalization

subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};
target_rois = {'ACC','SupTempLeft','SupTempRight'};
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/EffectiveConnectivity/';

for s = 1:length(subjects)
    disp(subjects{s});
    current_dir = fullfile(base_dir,subjects{s});
    for r = 1:length(target_rois)
        % search for current rois
        P = char(SearchFiles(current_dir,['*',target_rois{r},'*.img']));
        % load ROIs
        V = spm_vol(P);
        % correct non integer problem
        D = double(V.private.dat);
        D(D<0.5) = 0;
        D(D>0) = 1;
        V.fname = fullfile(fileparts(P),[subjects{s},'_',target_rois{r},'.nii']);
        V = spm_create_vol(V);
        V = spm_write_vol(V,D);
        delete(P);
        delete(regexprep(P,'.img','.hdr'));
        clear P D V;
    end
end
