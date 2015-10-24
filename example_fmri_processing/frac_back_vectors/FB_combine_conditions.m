function [onsets_out,names_out,durations_out]=FB_combine_conditions(...
    onsets,names,durations,which_conditions)
%[onsets,names,durations]=FB_combine_conditions(onsets,names,durations,BlockDesign,which_conditions)
%useful for block design psychophysical tasks
%which_conditions: specify which blocks/conditions to combine
%must be either a vector that specified the index of blocks
%within BlockDesign.Conditions, or the name of the name of the blocks in a
%cell array.

% debug
% which_conditions = [1,2,3,4];
BlockDesign.Conditions.type = {'InstructionBlock','ZeroBack','OneBack','TwoBack','Fixation'};
BlockDesign.Conditions.durations = [1,10,10,10,10];%in terms of number of scans
BlockDesign.Runs = 3; %number of runs
BlockDesign.TR = 3;% TR in seconds

if iscellstr(which_conditions)
    block_num  = find(ismember(BlockDesign.Conditions.type,which_conditions));
elseif isnumeric(which_conditions)
    block_num=which_conditions;
else
    error('Check which_conditions parameter');
end
combined_onsets_durations= [];
combined_names = [];
for n = block_num
    combined_onsets_durations = vertcat(combined_onsets_durations,...
        [onsets{n}(:),...
        repmat(BlockDesign.Conditions.durations(n),length(onsets{n}(:)),1)]);
    combined_names = [combined_names,names{n}];
    if n~=block_num(end)
        combined_names = [combined_names,'+'];
    end
end

%amalgamating consecutive blocks
combined_onsets_durations = sortrows(combined_onsets_durations,1);
tmp = diff(combined_onsets_durations(:,1))/BlockDesign.TR;
%find index where the the gap is not specified in the durations
[~,gap_LOC] = ismember(tmp,BlockDesign.Conditions.durations(which_conditions));
gap_IND = [0;find(gap_LOC==0)];
if gap_IND(end)~=size(combined_onsets_durations,1)
    gap_IND = [gap_IND;size(combined_onsets_durations,1)];
else
    gap_IND(end) = gap_IND(end)-1;
end

combined_onsets = [];
combined_durations = 0;
for kk = 1:(length(gap_IND)-1)
    combined_onsets = [combined_onsets;...
        combined_onsets_durations(gap_IND(kk)+1,1)];
    combined_durations(kk) = sum(combined_onsets_durations(...
        (gap_IND(kk)+1):(gap_IND(kk+1)),2))*BlockDesign.TR;
end
if range(combined_durations)>0
    error(['combined durations are: ',num2str(combined_durations),'\n',...
        'Length of combined blocks must be the same']);
end
combined_durations = mean(combined_durations);

% Reorder names, durations, and onsets
uncombined_IND = setdiff(1:length(BlockDesign.Conditions.type),block_num);
onsets_out = [onsets(uncombined_IND),{combined_onsets}];
durations_out = [durations(uncombined_IND),{combined_durations}];
names_out = [names(uncombined_IND),{combined_names}];
end



















