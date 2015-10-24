base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/subjects/funcs/';
subjects = {'JY_052413_haldol',...
    'MM_051013_haldol','MP021_051713','MP022_051713','MP023_052013',...
'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};
blocks = {'block1','block2','block3'};
target_file = 'resample_rra*.nii';
save_name = 'resample_rra.nii.tgz';
for s = 1:length(subjects)
    for b = 1:length(blocks)
        clear current_path files;
        current_path = fullfile(base_dir,subjects{s},blocks{b});
        files = dir(fullfile(current_path,target_file));
        if isempty(files)
            fprintf('%s, %s isempty\n',subjects{s},blocks{b});
            continue;
        else
            files = cellfun(@(x) fullfile(current_path,x),{files.name},'un',0);
        end
        tar(fullfile(current_path,save_name),files);
        for f = 1:length(files)
            delete(files{f});
        end
    end
end