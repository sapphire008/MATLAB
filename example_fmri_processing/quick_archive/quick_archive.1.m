% archive clean up
addmatlabpkg('fMRI_pipeline');
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/';
tasks = {'frac_back','mid','stop_signal'};
subjects = {'JY_052413_haldol';'MM_051013_haldol';'MP020_050613';...
    'MP021_051713';'MP022_051713';'MP023_052013';'MP024_052913';...
    'MP025_061013';'MP026_062613';'MP027_062713';'MP028_062813';...
    'MP029_070213';'MP030_070313';'MP031_071813';'MP032_071013';...
    'MP033_071213';'MP034_072213';'MP035_072613';'MP036_072913';...
    'MP037_080613';'MP120_060513';'MP121_060713';'MP122_061213';...
    'MP123_061713';'MP124_062113';'MP125_072413'};
blocks = {'block1','block2','block3','block4','block5','block6','block7','block8'};
target_file = '5sresample*.nii';

for t= 1:length(tasks)
    for s = 1:length(subjects)
        for b = 1:length(blocks)
            % archive target files
            current_dir = fullfile(base_dir,tasks{t},'subjects/funcs/',subjects{s},blocks{b});
            P = SearchFiles(current_dir,target_file);
            if isempty(P),continue;end
            tar(fullfile(current_dir,'5sresample_rra.nii.tgz'),P);
            cellfun(@delete,P);
            % remove 4D files. They take too much space
            P = SearchFiles(current_dir,'4D*');
            cellfun(@delete,P);
        end
    end
end
    