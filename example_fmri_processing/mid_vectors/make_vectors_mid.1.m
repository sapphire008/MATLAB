function [names,onsets,durations]= make_vectors_mid(...
    raw_table,col_name,phases,conditions,hits,has_acc)
% raw_table: must have column headers
% col_name: strings of following fields
%       trial: index of trial
%       cond: conditions of the trial
%       acc: accuracy of the trial
% phases: structures taht has the following fields
%       name: name of the phase
%       marker: which column header marks each name of the phase. These
%               columns should give onsets of the phase
%       dur: duration of the phase that the user wants to specify
% conditions: structure that has the following fields
%       name: name of the condition
%       marker: what entry item corresponds to this condition
% hits: accuracy information, must have the following fields
%       name: name of getting correct or incorrect
%       marker: what entry items marks correct or incorrect?
% has_acc: which phases must be viewed separately between correct and
%           incorrect? Must be a cell string and must be a subset of
%           phases.name



%list all categories of conditions
%for current Psychotoolbox MID task
% phases.name = {'Cue','Feedback'};
% phases.marker = {'Drew_cue_onset',...
%     'Drew_feedback_onset'};
% conditions.name = {'gain5','gain1','gain0','lose0','lose1','lose5'};
% conditions.marker = {6,5,4,1,2,3};
%conditions.marker = {'+$5','+$1','+$0','-$0','-$1','-$5'};
% %for old edat format MID task
% phases.name = {'Cue','Feedback'};
% phases.marker = {'Drew_cue_onset',...
%     'Drew_feedback_onset'};
% conditions.name = {'gain5','gain1','gain0.2','gain0','neutral',...
%     'lose0','lose0.2','lose1','lose5'};
% conditions.marker = {'+$5','+$1','+$0.2','+$0','neutral',...
%     '-$0','-$0.2','-$1','-$5'};
% hits.name = {'hit','miss'};
% hits.marker = {1,0};
%has_acc: which phases must be viewed separately by accuracy
%has_acc = {'Target','Feedback'};

% sanity check
sanity_check(phases);
sanity_check(conditions);
sanity_check(hits);

%remove empty columns
empty_IND = cell2mat(cellfun(@(x) isempty(x),raw_table(1,:),'un',0));
raw_table = raw_table(:,~empty_IND);
% %remove space in cellstrs
str_IND = cell2mat(cellfun(@(x) ischar(x), raw_table,'un',0));
raw_table(str_IND) = cellfun(@(x) strrep(x,' ',''),raw_table(str_IND),'un',0);


%remake table so that it only contain trial info
%reorganize table
new_struct = struct();
for t = 1:size(raw_table,2)
    new_struct.(raw_table{1,t}) = raw_table(2:end,t);
    %if all values in the cell are numeric, convert to matrix, but leave
    %the condition index as cell array
    if all(cell2mat(cellfun(@(x) isnumeric(x),new_struct.(raw_table{1,t}),...
            'un',0)))
        new_struct.(raw_table{1,t}) = cell2mat(new_struct.(raw_table{1,t}));
    end
end
clear trial_IND;
[~,trial_IND,~] = unique(new_struct.(col_name.trial));
%removed extra information
new_struct = structfun(@(x) x(trial_IND),new_struct,'un',0);


%find index of phases that has hits
hits_ind = find(ismember(phases.name,has_acc));
no_hit_ind = setdiff(1:length(phases.name),hits_ind);

%for cue and delay, it is not necessary to explore hits
onsets = {};
names = {};
durations = {};
for p = no_hit_ind %cue and delay
    for c = 1:length(conditions.name)
        names{end+1} = [phases.name{p},'_',conditions.name{c}];
        switch iscellstr(new_struct.(col_name.cond))
            case 1 %cellstr
                onsets{size(names,2)} = new_struct.(...
                    phases.marker{p})(ismember(...
                    new_struct.(col_name.cond),conditions.marker{c}));
            case 0%not cellstr, numeric
                onsets{size(names,2)} = new_struct.(...
                    phases.marker{p})(new_struct.(col_name.cond) ==...
                    conditions.marker{c});
        end
                
        durations{size(names,2)} = phases.dur(p);
    end
end
%for response and feedback, we need to specify hits
for p =hits_ind%response and feedback
    for c = 1:length(conditions.name)
        clear current_onset_IND;
        switch iscellstr(new_struct.(col_name.cond))
            case 1
                current_onset_IND = ismember(new_struct.(col_name.cond),...
                    conditions.marker{c});
            case 0
                current_onset_IND = new_struct.(col_name.cond) == ...
                    conditions.marker{c};
        end
        
        for h = 1:length(hits.name)
            names{end+1} = [phases.name{p},'_',conditions.name{c},'_',...
                hits.name{h}];
            onsets{size(names,2)} = new_struct.(phases.marker{p})(...
                current_onset_IND & (new_struct.(col_name.acc)==hits.marker{h}));
            
            durations{size(names,2)} = phases.dur(p);
        end
    end
end

%remove empty vectors
empty_vect_IND = cell2mat(cellfun(@(x) isempty(x),onsets,'un',0));
names = names(~empty_vect_IND);
onsets = onsets(~empty_vect_IND);
%onsets = cellfun(@(x) x/1000,onsets,'un',0);%for old format only
durations = durations(~empty_vect_IND);
    
end

function sanity_check(aru_table_struct)
field_len = [];
field_names = fieldnames(aru_table_struct);
for fn = 1:length(field_names)
    field_len(end+1) = length(aru_table_struct.(field_names{fn}));
end
if range(field_len)>0
    error(['Check ', inputname(aru_table_struct)]);
end
end