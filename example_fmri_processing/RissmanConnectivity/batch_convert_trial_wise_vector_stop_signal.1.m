%batch convert vectors to trial-wise vectors: EDC
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/RissmanConnectivity/;
addmatlabpkg('fMRI_pipeline');
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/behav/';
subjects = {'MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
target_name = 'vectors_*.mat';
target_file = 'vectors_(\d*).mat';
target_cond = '';
new_file = 'vectors_$1_trial.mat';



for s = 1:length(subjects)
    files = SearchFiles(fullfile(base_dir,subjects{s}),target_name);
    files = files(~cellfun(@isempty,regexp(files,target_file)));
    for f = 1:length(files)
        clear onsets names durations;
        load(files{f});
        if ~isempty(target_cond)
            IND = ~cellfun(@isempty,regexp(names,target_cond));
            onsets = onsets(IND);
            names = names(IND);
            durations = durations(IND);
            clear IND;
        end
        [onsets,names,durations] = vect_group2trial(onsets,names,durations,1);
        save(regexprep(files{f},target_file,new_file),'onsets','names','durations');
        block = f;
        if exist('block','var')
            save(regexprep(files{f},target_file,new_file),'block','-append');
        end
    end
end

% % combines Cues and Delayl. Get rid of Delay onsets, use all others (target
% % and feedback) and nuisance;
% target_name = 'vectors_run*_trial_all_phases.mat';
% target_cond = 'Cue';
% target_throwout = 'Delay';
% 
% for s = 1:length(subjects)
%     files = SearchFiles(fullfile(base_dir,subjects{s}),target_name);
%     for f = 1:length(files)
%         names_out = [];
%         onsets_out = [];
%         durations_out = [];
%         load(files{f});
%         target_cond_IND = ~cellfun(@isempty,regexpi(names,target_cond));
%         throwout_IND = ~cellfun(@isempty,regexpi(names,target_throwout));
%         names_out = names(target_cond_IND);
%         onsets_out = onsets(target_cond_IND);
%         durations_out = num2cell(4*ones(1,sum(target_cond_IND)));
%         names_out = [names_out,{'nuisance'}];
%         onsets_out = [onsets_out,{sort(cell2mat(onsets(~(target_cond_IND | throwout_IND))))}];
%         durations_out = [durations_out,{2}];
%         clear durations names onsets;
%         names = names_out; clear names_out;
%         durations = durations_out; clear durations_out;
%         onsets = onsets_out; clear onsets_out;
%         save(files{f},'onsets','durations','names','block');
%         clear names onsets durations;
%     end
% end
