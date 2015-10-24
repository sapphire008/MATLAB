function [D_prime,Bias,Hits,FalseAlarm,RESP] = analyze_SignalDetection(...
    Stimulus_vect, Response_vect, diff_target, varargin)
% D_prime = DPRIME(stimulus_vector, response_vector, target_different_condition, ...)
% [D_prime, Bias] = DPrime(...)
% [D_prime, Bias, Hits, FalseAlarm, ResponseRate] = DPrime(...)
%
% Calculates parameters defined in Signal Detection Theory:
%       D':
%               D' = Z(P(Hits)) - Z(P(FalseAlarm))
%       Bias: 
%               Bias = -[Z(P(Hits))+Z(P(FalseAlarm))]/2
%
% From: Detection Sensitivity and Response Bias (Lewis O Harvey, Jr. 2003)
% http://psych.colorado.edu/~lharvey/p4165/p4165_2003_spring/2003_Spring_pdf/P4165_SDT.pdf
% And also, D-prime (signal detection) analysis from UCLA' linguistics website
% http://www.linguistics.ucla.edu/faciliti/facilities/statistics/dprime.htm      
%
% Where Z is the normal quantile function, implemented with NORMINV from
% MATLAB's Statistics Toolbox.
%
% Required Inputs:
%   Stimulus_vector: either cellstr or numerics of stimulus presented. This
%                    vector is what the subject supposed to respond.
%
%   Response_vector: either cellstr or numerics, must be the same class as
%                    Response_vector. This is what the subject actually
%                    responded.
%
%   Note that both Stimulus_vector and Response_vector must be binary, with
%   two types of values: stimulus/response marker for the stimuli are
%   constant, and stimulus/reponse marker for the stimuli are different.
%      i.e. [1 0 0 0 1 1 0 0 1...] 
%                       OR
%           {'H','M','M','M','H','H',....}
%
%   target_different_condition: which condition/response should the subject
%                    respond when detecting a different target? Must be the
%                    same class as the elements of Stimulus_vector. That 
%                    is, if the element of Stimulus_vector is char and
%                    Stimulus_vector itself is a cellstr, then diff_target
%                    must be a char.
%

flag = L_InspectVarargin(varargin,{'conditions'},{{}});
%sanity check
if ~strcmp(class(Stimulus_vect),class(Response_vect))
    error(['Stimulus_vector and Response_vector are not the same class.',...
        ' Both must be either cellstr or numeric array.']);
elseif ~strcmp(class(Stimulus_vect), class(diff_target))
    error(['Stimulus_vector and target_different_condition are not the same class.',...
        ' Both must be either cellstr or numeric array.']);
end

switch isempty(flag.conditions)
    case 0%separate analysis by conditions
        [cond_names,cond_ind] = inspect_conditions(flag.conditions);
        for c = 1:length(cond_names)
            [D_prime.(['cond_',cond_names{c}]),...
                Bias.(['cond_',cond_names{c}]),...
                Hits.(['cond_',cond_names{c}]),...
                FalseAlarm.(['cond_',cond_names{c}]),...
                RESP.(['cond_',cond_names{c}])]=calculate_SignalDetection(...
                Stimulus_vect(cond_ind{c}),...
                Response_vect(cond_ind{c}),...
                diff_target);
        end
    case 1%do global analysis
        [D_prime,Bias,Hits,FalseAlarm,RESP] = ...
            calculate_SignalDetection(Stimulus_vect,Response_vect,diff_target);
end
end

function [D_prime,Bias,H,F,RESP]=calculate_SignalDetection(S,R, diff_target)
%remove NaN and empty cells in S and corresponding entries in R
switch isnumeric(S)
    case {0}%if cellstr
        valid_IND = ~cellfun(@isempty, S);
        valid_IND = valid_IND & ~cellfun(@isnan,S);
        S = S(valid_IND);
        R = R(valid_IND);
    case {1}%if numeric
        IND = ~isnan(S);
        S = S(IND);
        R = R(IND);
        S = cellfun(@num2str,num2cell(S),'un',0); %convert to cellstr
        R = cellfun(@num2str,num2cell(R),'un',0); %convert to cellstr
        diff_target = num2str(diff_target);
end
%same_target: which response should it be when the stimulus stays the same
% assuming S, stimulus, is binary, which contains only two types of stimuli
all_targets = unique(S);
same_target = all_targets(~ismember(all_targets,diff_target));

% The following calculations are from:
% Detection Sensitivity and Response Bias (Lewis O Harvey, Jr. 2003)
% Hits = numberOf(different_stimulus & different_response) / numberOf(different_stimulus)
H=length(find(ismember(S,diff_target) & ismember(R,diff_target)))/length(find(ismember(S,diff_target)));
% FalseAlarm = numberOf(same_stimulus & different_response) / numberOf(same_stimulus)
F=length(find(ismember(S,same_target) & ismember(R,diff_target)))/length(find(ismember(S,same_target)));
% RESP: response rate, numberOf(response) / numberOf(total trials)
RESP = length(find(~cellfun(@isempty,R) & ~ismember(R,'NaN')))/length(R);
% Z(H), cap to absolute value of 10 instead of returing Inf
Z_H = norminv(H,0,1);
if isinf(Z_H)
    Z_H = sign(Z_H)*10;
end
% Z(F), cap to absolute value of 11 instead of returning Inf
Z_F = norminv(F,0,1);
if isinf(Z_F)
    Z_F = sign(Z_F)*20;
end
% D_prime = Z(H) - Z(FA)
D_prime = Z_H - Z_F;
% Bias = -(Z(H)+Z(FA))/2
Bias = -(Z_H + Z_F)/2;
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