clear all;
base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/behav/';
save_path = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/behav/';
target_file_ext = '*Fmri*.csv';
blocks = {'block1','block2','block3'};
which_conditions=[2,3,4];%which conditions to combine

subjects = {'M3129_CNI_060814'};

addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/frac_back_vectors;
for s = 1:length(subjects)
    disp(subjects{s});
    %clear names durations onsets;
    % To create discrete vectors of each conditions specified in BlockDesign
    behav_path = {fullfile(base_dir,subjects{s}),target_file_ext};
    %make vector with onsets
    FB_make_vectors(behav_path,'_vectors.mat');
    %make_vectors without onsets
    %FB_make_vectors(behav_path,BlockDesign2,save_path,'_estimated_vectors.mat');
    
    %check vectors, compare the two types
    %FB_check_vectors(base_dir,subjects{s},0.3);

    for b = 1:length(blocks)
        % To create combined_vectors
        load(fullfile(save_path,subjects{s},[blocks{b},'_vectors.mat']));
        [onsets,names,durations]=FB_combine_conditions(onsets,names,durations,which_conditions);
        save(fullfile(save_path,subjects{s},[blocks{b},'_vectors_combined.mat']),'onsets','names','durations');
    end
end