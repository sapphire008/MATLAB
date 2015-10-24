% fsl image archive
addmatlabpkg('fMRI_pipeline');
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/subjects/funcs/';
 subjects = {'JY_052413_haldol'};%,'MM_051013_haldol','MP021_051713',...
%     'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
%     'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
%     'MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
%     'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
%     'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
%     'MP124_062113','MP125_072413','TMS100','TMS200'};
for s = 1:length(subjects)
    disp(subjects{s});
    P = char(SearchFiles(fullfile(base_dir,subjects{s}),'2s*4D*.nii.gz'));
    % purge any existing images
    M = SearchFiles(fullfile(base_dir,subjects{s}),'*2sresample*.nii');
    for kk = 1:length(M)
        delete(M{kk});
    end
    FSL_archive_nii('split',P,[],[],'basename','2sresample_rra');
    P = SearchFiles(fullfile(base_dir,subjects{s}),'2sresample*.nii');
    for m = 1:length(P)
       eval(['!mv ',P{141-m},' ',fullfile(base_dir,subjects{s},sprintf('2sresample_rra%04.f.nii',141-m))])
    end
    clear P;
end