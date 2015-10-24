%make MID vectors
%based on the papers, selecting only cue and feedback phases
clear all;
clc;
addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/mid_vectors/');

base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/behav/';
subjects = {'M3039_CNI_061014'};

forbidden_words = {'RUN0','practice','demo'};%filter out files with these names
runs = {'b1','b2','b3','b4'};%look for files with these run labels
ext = '.csv';
TriggerDelay = 0;%seconds of delayed onset of the first trial after scanner 
% starts to acquire the first image. This setting should be used when there 
% are number of images excluded from the series.

%specify necessary column headers to lookup in the table
col_name.trial = 'Trial';%trial index
col_name.cond = 'TrialType';%condition
col_name.acc = 'ACC';%accuracy

% conditions and corresponding markers
conditions.name = {'gain5','gain1','gain0','lose0','lose1','lose5'};
conditions.marker = {6,5,4,1,2,3};

%1). for normal vectors
% accuracy information
hits.name = {'hit','miss'};
hits.marker = {1,0};

phases.name = {'Cue','Feedback'};
phases.marker = {'CueOnset','FeedBackOnset'};%column names
phases.dur = [4,2];

% 2). for making vectors of all phases
phases2.name = {'Cue','Delay','Target','Feedback'};
phases2.marker = {'CueOnset','DelayOnset','TargetOnset',...
    'FeedBackOnset'};
phases2.dur = [0 0 0 0];


% 3). for making visual activated phases vectors
which_conditions = {'Cue*','Response*','Feedback*'};
new_durations = {0};
new_names = {'visual'};

% 4). an alternative vector, with Response and Feedback together
phases3.name = {'Cue','Response'};
phases3.marker = {'CueOnset','TargetOnset'};
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
        onsets = cellfun(@(x) x-TriggerDelay,onsets,'un',0);
        save(fullfile(behav_dir,['vectors_',block,'.mat']),...
            'block','names','onsets','durations');
        
        %2). make vectors for all phases
        clear names onsets durations;
        [names,onsets,durations] = make_vectors_mid(...
            raw_table,col_name,phases2,conditions,hits,...
            {'Target','Feedback'});
        onsets = cellfun(@(x) x-TriggerDelay,onsets,'un',0);
        save(fullfile(behav_dir,['vectors_',block,'_all_phases.mat']),...
            'block','names','onsets','durations');
        
        %3). make vectors for only visually activated phases
        [onsets,names,durations] = MID_combine_vectors(...
            onsets,names,durations,which_conditions,...
            'new_names',new_names,'new_durations',new_durations,...
            'include_old',0);
        % don't need to subtract the TriggerDelay becuase the previous
        % vector already subtracted the delay.
        save(fullfile(behav_dir,['vectors_',block,'_visual.mat']),...
            'block','names','onsets','durations');
        
        %4). make vectors for alternative GLM, with cue and reponse
        [names,onsets,durations] = make_vectors_mid(raw_table,...
            col_name,phases3,conditions,hits,{'Response'});
        block = ['run',num2str(r)];
        onsets = cellfun(@(x) x-TriggerDelay,onsets,'un',0);
        save(fullfile(behav_dir,['vectors_',block,'_alternative.mat']),...
            'block','names','onsets','durations');
    end
end





