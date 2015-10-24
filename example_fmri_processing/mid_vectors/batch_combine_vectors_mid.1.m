%batch combine vectors
clear all;
base_dir = '/nfs/jong_exp/midbrain_pilots/mid/behav/';
subjects = {'MP025_061013','MP026_062613','MP027_062613','MP028_062813',...
    'MP029_070213','MP030_070313','MP121_060713','MP122_061213',...
    'MP123_061713';'MP124_062113'};

which_conditions = {'Cue*','Response*','Feedback*'};
new_durations = {0};
new_names = {'visual'};

phases.name = {'Cue','Delay','Target','Feedback'};
phases.marker = {'Drew_cue_onset','Drew_delay_onset','Drew_target_onset',...
    'Drew_feedback_onset'};
conditions.name = {'gain5','gain1','gain0','lose0','lose1','lose5'};
conditions.marker = {6,5,4,1,2,3};



for s = 1:length(subjects)
    clear files;
    files = dir(fullfile(base_dir, subjects{s},source_file));
    if isempty(files)
        continue;
    end
    for f = 1:length(files)
        clear onsets names durations;
        load(fullfile(base_dir,subjects{s},files(f).name));
        [onsets,names,durations] = MID_combine_vectors(...
            onsets,names,durations,which_conditions,...
            'new_names',new_names,'new_durations',new_durations,...
            'include_old',0);
        save(fullfile(base_dir,subjects{s},strrep(files(f).name,...
            'all_phases','visual')),'block','onsets','names','durations');
    end
end