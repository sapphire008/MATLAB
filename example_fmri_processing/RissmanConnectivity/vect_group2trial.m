function [onsets_out,names_out,durations_out] = vect_group2trial(onsets,names,durations,numzeropad)
% [onsets,names,durations] = vect_group2trial(onsets,names,durations,numzeropad)
% converts a vector into trial wise vector, separating each onsets as an
% individual condition
% Default numzeropad that labels the trial number is 3, e.g. 3 becomes 003
% and 32 becomes 032

if nargin<4
    % pad some zeros to the numbering of each trial
    numzeropad = 1;
end
%calculate total number of trials
trial_num = sum(cellfun(@length,onsets));

names_out = cell(1,trial_num);
onsets_out = cell(1,trial_num);
durations_out = cell(1,trial_num);

%keep track of which col / index the next condition will start at 
count_col = 1;

for n = 1:length(names)
    %make names
    names_out(1,count_col:(count_col+length(onsets{n})-1)) = ...
        cellfun(@(x) sprintf([names{n},'_%0',num2str(numzeropad),'.f'],x),...
        num2cell(1:length(onsets{n})),'un',0);%generate numbers
    %make onsets
    onsets_out(1,count_col:(count_col+length(onsets{n})-1)) = ...
        num2cell(onsets{n});
    %make durations
    durations_out(1,count_col:(count_col+length(onsets{n})-1)) = ...
        num2cell(repmat(durations{n},1,length(onsets{n})));
    %shift columns
    count_col = count_col + length(onsets{n});
end
end
