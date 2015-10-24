function [onsets_out,names_out,durations_out]=...
    MID_combine_vectors(onsets,names,durations,which_conditions,varargin)
%[onsets,names,durations]=MID_combine_vectors(onsets,names,durations,which_conditions,...)
% Useful for event related design of psychophysical tasks
%
% Required Inputs:
%       onsets, names, durations: same as the SPM vectors
%
%       which_conditions: must be a cell array that contains each
%                         conditions to combine
%                           The content of each cell must be 
%                           either a cellstr or vector of conditions
%                           if cellstr, contents must follow what has been
%                           specified in the 'names' variable. This script
%                           accepts wildcards character '*' or patterns
%                           used by the function 'regexp'.
%                           For example,
%                           {{'A','B'},{'C','D','E'}
%                           The script will combine conditions 'A' and 'B'
%                           as the first new conditions, and 'C',
%                           'D','E' as another new condition.
%                           
% Optional Inputs:
%
%       'new_names': specify a new name for the combined conditions,
%                   the script will simply concatenate old names. The
%                   specified names must be the same length as the newly
%                   combined conditions.
%
%       'new_durations': specify a new duration for the combined
%                       conditions, otherwise, the script will take the
%                       mean durations of all elementary conditions
%
%       'include_old': 
%                       0: return only combined conditions
%                       1: append old conditions that are not used
%                       2: append all conditions, regardless of being used
%                       in the combination or not.

%debug
%which_conditions = {'Cue*','Response*','Feedback*'};

%check optional inputs
flag = L_InspectVarargin(varargin,...
    {'new_names','new_durations','include_old'},{{},{},0});
%chekc which_conditions
if iscellstr(which_conditions)
    which_conditions = {which_conditions};
end

%place holding outputs
onsets_out = cell(1,length(which_conditions));
names_out = cell(1,length(which_conditions));
durations_out = cell(1,length(which_conditions));
%record which conditions are not used in combination, will be returned in
%the newly combined vector, if specified so.
untouched_conds = false(1,length(names));

for w = 1:length(which_conditions)%for each combination conditions
    %combine onsets
    %onsets_out=get_new_vect(onsets,names,which_conditions{n});
    cond_IND = false(1,length(names));
    for c = 1:length(which_conditions{w})
        clearvars tmp*;
        %find which cell in the 'names' variable that matches the patterns
        tmp = cellfun(@(x) regexp(x,which_conditions{w}{c}),names,...
            'UniformOutput',false);
        %find index of conditions to be combined
        cond_IND = (cond_IND | (~cellfun(@isempty,tmp)));
    end
    %record untouched conditions of current iteration of combination
    untouched_conds = (untouched_conds | (~cond_IND));

    %process each variable by default for now
    onsets_out{w} = unique(vertcat(onsets{cond_IND}));
    %if have MATLAB 2013a or later, use strjoin(cellstr,delimiter)
    clear tmp_names;
    tmp_names =cellfun(@(x) [x,'&'],names(cond_IND),'UniformOutput',0);
    tmp_names{end}(end) = '';%remove extra &
    names_out{w} = horzcat(tmp_names{:});
    durations_out{w} = mean(cell2mat(durations(cond_IND)));
    
    %check if customized names and durations exist
    if ~isempty(flag.new_names)
        names_out{w} = flag.new_names{w};
    end
    if ~isempty(flag.new_durations)
        durations_out{w} = flag.new_durations{w};
    end
end

%check if return old conditions
switch flag.include_old
    case 0
        return;
    case 1
        onsets_out = [onsets_out,onsets(untouched_conds)];
        names_out = [names_out,names(untouched_conds)];
        durations_out = [durations_out,durations(untouched_conds)];
    case 2
        onsets_out = [onsets_out,onsets];
        names_out = [names_out,names];
        durations_out = [durations_out,durations];
end
end



function flag=L_InspectVarargin(search_varargin_cell,keyword,default_value)
% flag = InspectVarargin(search_varargin_cell,keyword, default_value)
%Inspect whether there is a keyword input in varargin, else return default.
%if search for multiple keywords, input both keyword and default_value as a
%cell array of the same length
%if length(keyword)>1, return flag as a structure
%else, return the value of flag without forming a structure
if length(keyword)~=length(default_value)%flag imbalanced input
    error('keyword and default_value must be the same length');
end

%convert everything into cell array if single input
if ~iscell(keyword)
    keyword={keyword};
end
if ~iscell(default_value)
    default_value={default_value};
end

flag=struct();%place holding
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),search_varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=search_varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_value{n};
    end
end

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end

end