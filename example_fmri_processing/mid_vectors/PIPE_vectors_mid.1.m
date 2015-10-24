function PIPE_vectors_mid(subjects)

%make MID vectors
%based on the papers, selecting only cue and feedback phases
%clear all;
%clc;
base_dir = '/nfs/jong_exp/midbrain_pilots/mid/behav/';
%subjects = {'MP122_061213','MP124_062113'};
% subjects = dir(base_dir);
% subjects = {subjects(3:end).name};

addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
addpath('/nfs/jong_exp/midbrain_pilots/scripts/mid_vectors/');
forbidden_words = {'RUN0','practice'};%filter out files with these names
runs = {'b1','b2','b3'};%look for files with these run labels
ext = '.csv';

%specify necessary column headers to lookup in the table
col_name.trial = 'trial';%trial index
col_name.cond = 'trialtype';%condition
col_name.acc = 'hit';%accuracy


%1). for normal vectors
% accuracy information
hits.name = {'hit','miss'};
hits.marker = {1,0};

phases.name = {'Cue','Feedback'};
phases.marker = {'Drew_cue_onset',...
    'Drew_feedback_onset'};
phases.dur = [4,2];

conditions.name = {'gain5','gain1','gain0','lose0','lose1','lose5'};
conditions.marker = {6,5,4,1,2,3};


% 2). for making vectors of all phases
phases2.name = {'Cue','Delay','Target','Feedback'};
phases2.marker = {'Drew_cue_onset','Drew_delay_onset','Drew_target_onset',...
    'Drew_feedback_onset'};
phases2.dur = [0 0 0 0];


% 3). for making visual activated phases vectors
which_conditions = {'Cue*','Response*','Feedback*'};
new_durations = {0};
new_names = {'visual'};

% 4). an alternative vector, with Response and Feedback together
phases3.name = {'Cue','Response'};
phases3.marker = {'Drew_cue_onset','Drew_target_onset'};
phases3.dur = [4,0];


%% get file

for s = 1:length(subjects)
    behav_dir = [base_dir,subjects{s}];
    file_list =dir(fullfile(behav_dir,['*',ext]));
    %if no csv files, skip
    if isempty(file_list)
        disp(['skipped: ', subjects{s}]);
        continue;
    end
    %select correct files
    files = {};
    for f = 1:length(file_list)
        if any(cell2mat(cellfun(@(x) ~isempty(strfind(...
                lower(file_list(f).name),x)),...
                lower(forbidden_words),'un',0)))
            continue;
        else
            files{end+1} = file_list(f).name;
        end
    end
    %import runs
    for r = 1:length(runs)
        %find out current run corresponds to which file
        count_match = 0;
        for f = 1:length(files)
            if ~isempty(strfind(files{f},runs{r}))
                current_run_file = files{f};
                count_match = count_match+1;
            end
        end
        if count_match>1
            error('Run file is not unique, check file names');
        elseif count_match<1
            disp([runs{r},' does not exist. Skipped']);
            continue;%skip this run
        end
        
        %make the vectors
        clear raw_table names onsets durations block;
        raw_table = ReadTable(fullfile(behav_dir,current_run_file));
        
        %1). make vectors based on paper
        [names,onsets,durations] = make_vectors_mid(raw_table,...
            col_name,phases,conditions,hits,{'Feedback'});
          block = ['run',num2str(r)];
        save(fullfile(behav_dir,['vectors_',block,'.mat']),...
            'block','names','onsets','durations');
        
        %2). make vectors for all phases
        clear names onsets durations;
        [names,onsets,durations] = make_vectors_mid(...
            raw_table,col_name,phases2,conditions,hits,...
            {'Target','Feedback'});
        save(fullfile(behav_dir,['vectors_',block,'_all_phases.mat']),...
            'block','names','onsets','durations');
        
        %3). make vectors for only visually activated phases
        [onsets,names,durations] = MID_combine_vectors(...
            onsets,names,durations,which_conditions,...
            'new_names',new_names,'new_durations',new_durations,...
            'include_old',0);
        save(fullfile(behav_dir,['vectors_',block,'_visual.mat']),...
            'block','names','onsets','durations');
        
        %4). make vectors for alternative GLM, with cue and reponse
         [names,onsets,durations] = make_vectors_mid(raw_table,...
            col_name,phases3,conditions,hits,{'Response'});
          block = ['run',num2str(r)];
        save(fullfile(behav_dir,['vectors_',block,'_alternative.mat']),...
            'block','names','onsets','durations');
    end
end


end


