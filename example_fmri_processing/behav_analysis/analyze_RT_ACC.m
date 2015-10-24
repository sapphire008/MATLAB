function [RT, ACC] = analyze_RT_ACC(RT_vect,ACC_vect,varargin)
%analyze RT and ACC
flag = L_InspectVarargin(varargin,{'conditions','RT_type','ACC_type'},...
    {{},'average','percentage'});
switch isempty(flag.conditions)
    case 0%separate analysis by conditions
        [cond_names,cond_ind] = inspect_conditions(flag.conditions);
        for c = 1:length(cond_names)
            RT.(['cond_',cond_names{c}]) = analyze_RT(...
                RT_vect(cond_ind{c}),'average');
            ACC.(['cond_',cond_names{c}]) = analyze_ACC(...
                ACC_vect(cond_ind{c}),'percentage');
        end
    case 1%do global analysis
        RT  = analyze_RT(RT_vect,flag.RT_type);
        ACC = analyze_ACC(ACC_vect,flag.ACC_type);
end
end

function [cond_names,cond_ind] = inspect_conditions(condition_vect)
%determine condition types, convert everything to cellstr, remove undesired
if nargin<2
    remove_char = '';
end
if isnumeric(condition_vect)
    %in case of numeric discrete values
    %condition_vect = condition_vect(~isnan(condition_vect));%remove NaNs
    condition_vect = cellfun(@num2str,num2cell(condition_vect),'un',0); %convert to cellstr
end
cond_names = unique(condition_vect);
cond_ind = cellfun(@(x) ismember(condition_vect,x),cond_names,'un',0);
end

function RT = analyze_RT(RT_vect,type,threshold)
if nargin<3
    %by default, if use 'below_above', 
    %the scipt will count how many RTs is below and above mean
    threshold = nanmean(RT_vect(:));
end
%RT_vect expected to be double or numeric
switch type
    case {'average'}
        RT = nanmean(RT_vect(:));
    case {'variance'}
        RT = nanvar(RT_vect(:));
    case {'std'}
        RT = nanstd(RT_vect(:));
    case {'se'}
        RT = nanstd(RT_vect(:))/sqrt(length(RT_vect(~isnan(RT_vect))));
    case {'median'}
        RT = nanmedian(RT_vect(:));
    case {'max_min'}
        RT = [nanmax(RT_vect(:)),nanmin(RT_vect(:))];
    case {'rms'}
        RT = sqrt(nanmean(RT_vect(:).^2));
    case {'below_above'}%count how many [below, above] threshold
        RT = [length(RT_vect(~isnan(RT_vect))<threshold),...
            length(RT_vect(~isnan(RT_vect))>=threshold)];
end
end

function ACC = analyze_ACC(ACC_vect,type,remove_char)
%ACC_vect expected to be discrete, either numeric or cellstr
if nargin<3
    remove_char = '';
end
%determine input type, convert everything to cellstr, and remove undesired
switch isnumeric(ACC_vect)
    case 1 %in case of numeric discrete values
        ACC_vect = ACC_vect(~isnan(ACC_vect));%remove NaNs
        ACC_vect = cellfun(@num2str,num2cell(ACC_vect),'un',0); %convert to cellstr
    case 0 %in case of cellstr
        ACC_vect = ACC_vect(~ismember(ACC_vect,remove_char));
end
accuracy_types = unique(ACC_vect);
ACC = cell(length(accuracy_types),2);%place holding
for m = 1:length(accuracy_types)
    ACC{m,1} = accuracy_types{m};
    switch type
        case {'percentage'}
            ACC{m,2} = length(find(ismember(ACC_vect,accuracy_types{m})))/length(ACC_vect)*100;
    end
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

% %in case there is only one search keyword, return the value
% if length(keyword)==1
%     warning off;
%     flag=flag.(keyword{1});
%     warning on;
% end

end