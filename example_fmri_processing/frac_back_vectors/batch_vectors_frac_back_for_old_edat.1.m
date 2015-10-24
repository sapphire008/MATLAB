clear all;
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/behav/edat/';
save_path = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/behav/';
target_file_ext = '.txt';
blocks = {'block1','block2','block3'};
which_conditions=[2,3,4];

% 
% subjects = {'JY_052413_haldol','MM_051013_haldol',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313','MP120_060513','MP121_060713',...
%     'MP122_061213','MP123_061713','MP124_062113'};
 subjects = {'M3126_042514'};

 BlockDesign.Conditions.type = {'InstructionBlock','ZeroBack','OneBack','TwoBack','NULL'};
 BlockDesign.Conditions.durations = [1,10,10,10,5];%in terms of number of scans[1,10,10,10,5](TR3)/[1,9,9,8](TR2)
 BlockDesign.Runs = 3; %number of runs
 BlockDesign.TR = 3;% TR in seconds
 BlockDesign.Onsets = {'ImageOnsetTime','InstructionsOnsetTime'};
 BlockDesign.Conditions.name = 'RunningTrial';
 BlockDesign.ColHeaders = 'Image.OnsetTime,Instructions.OnsetTime,Running[Trial]';
 
 %convert to a BlockDesign Object without Onsets
 BlockDesign2 = rmfield(BlockDesign,'Onsets');
 
 

addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/frac_back_vectors;
for s = 1:length(subjects)
    disp(subjects{s});
    %clear names durations onsets;
    % To create discrete vectors of each conditions specified in BlockDesign
    behav_path = fullfile(base_dir,[subjects{s},target_file_ext]);
    %make vector with onsets
    FB_make_vectors(behav_path,BlockDesign,save_path,'_vectors.mat');
    %make_vectors without onsets
    FB_make_vectors(behav_path,BlockDesign2,save_path,'_estimated_vectors.mat');
    
    %check vectors, compare the two types
    FB_check_vectors(base_dir,subjects{s},0.3);

    
    for b = 1:length(blocks)
        % To create combined_vectors
        load(fullfile(save_path,subjects{s},[blocks{b},'_vectors.mat']));
        [onsets,names,durations]=FB_combine_conditions(onsets,names,durations,BlockDesign,which_conditions);
        save(fullfile(save_path,subjects{s},[blocks{b},'_vectors_combined.mat']),'onsets','names','durations');
    end
end