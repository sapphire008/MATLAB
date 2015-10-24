function [onsets,names,durations] = ...
    create_SPM_vectors_with_onsets(col_vect,col_ind,conditions,TR, dur)
% col_vect: column vector of onset times
% col_ind: index of each condition. The number inside corresponds to which
% conditions
% conditions: cellstr of condition names
% dur: durations, corresponding to each condition

onsets = cell(1,length(conditions));
for c = 1:length(conditions)
    onsets{c} = col_vect(col_ind == c);
end
non_empty_IND = ~cellfun(@isempty,onsets);
names = conditions(non_empty_IND);
durations = num2cell(dur(non_empty_IND)*TR);
end
