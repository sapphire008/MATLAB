%batch convert vectors to trial-wise vectors
base_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/behav/';
subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP032_071013',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713','MP124_062113'};
target_name = 'vectors_*.mat';
target_file = 'vectors_(\d*).mat';
new_file = 'vectors_$1_trial.mat';



for s = 1:length(subjects)
    files = dir(fullfile(base_dir,subjects{s},target_name));
    files = {files.name};
    for f = 1:length(files)
        clear onsets names durations;
        load(fullfile(base_dir,subjects{s},files{f}));
        [onsets,names,durations] = vect_group2trial(onsets,names,durations);
        save(fullfile(base_dir,subjects{s},regexprep(files{f},...
            target_file,new_file)),'onsets','names','durations');
    end
end
