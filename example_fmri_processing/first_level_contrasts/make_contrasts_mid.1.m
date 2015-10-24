function contrasts = make_contrasts_mid(SPM_loc,positive_cons,negative_cons,...
    name,baseline_cond,sumtozero,remove_bf)
% Pass in SPM data structure
% if you want to make sure the contrasts sum to zero - set sumtozero to 1
%
% Following lines should be changed to match your desired contrasts
% Note number of positive strings must equal number of negative strings
% if you want to do vs baseline set the negative string to 'null'
%
% If you do not want to use custom names set custom_names to zero


% modifed to remove contrasts that are all zero DMT 8/15/12
% Adapted for MID task by EDC 05/30/13

if isempty(name)
    custom_name = 0;%make the name from cons
    if ~exist('remove_bf','var')
        remove_bf = 1;%by default, remove base function character '*bf(1)'
    end
else
    custom_name = 1;
end
%inspect baseline name
if isempty(baseline_cond) || ~ischar(baseline_cond)
    baseline_cond = 'null';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%sanity check
if length(positive_cons) ~= length(negative_cons)
    error('Positive conditions and negative conditions must be the same length');
end
if custom_name && length(name) ~=length(positive_cons)
    error('Custom names must be the same length as the conditions');
end

switch exist('SPM_loc')
    
    case 0 % no SPM_loc passed in
        disp(' Need to provide SPM.mat file');
        contrasts = 'Empty Need to provide SPM.mat file to make_contrasts';
        return
    case 1 % SPM structure or location
        if ischar(SPM_loc),
            disp('Load SPM.mat file');
            load(SPM_loc);
            clear('SPM_loc');
        elseif iscell(SPM_loc),
            SPM = SPM_loc;
            clear('SPM_loc');
        end
    otherwise
        disp(' Need to provide SPM.mat file');
        contrasts = 'Empty Need to provide SPM.mat file to make_contrasts';
        return
end

if ~exist('sumtozero'), sumtozero = 0; end

good_con = [];  %used at end of script

%%%%%%%%%%%%%%%%%%%% change nothing below here %%%%%%%%%%%%%%%%%%%%%%%%%%%
contrasts = struct();

for n = 1:length(positive_cons)
    
    contrasts(n).con = zeros(1,length(SPM.Vbeta));
   
    %%%%%%%%% Match Beta Names to generate contrasts %%%%%%%%%
    %positive conditions
    %disp('Currently doing positive conditions');%debug
    [contrasts(n).con,pos_null_counter,pos_cond_exists]=generate_contrast(...
        SPM,contrasts(n).con,positive_cons{n},1,baseline_cond);
    %negative conditions
    %disp('Currently doing negative_conditions');%debug
    [contrasts(n).con,neg_null_counter,neg_cond_exists]=generate_contrast(...
        SPM,contrasts(n).con,negative_cons{n},-1,baseline_cond);
    null_counter = pos_null_counter + neg_null_counter;
%     pos_cond_exists = false(1,length(positive_cons{n}));
%     null_counter=0;%tally null condition
%     for k = 1:length(positive_cons{n}),
%         if strcmpi(positive_cons{n},baseline_cond)
%             null_counter = null_counter +1;
%         end
%         idx = strfind({SPM.Vbeta.descrip},positive_cons{n}{k});
%         idx = find(~cellfun('isempty',idx));
%         contrasts(n).con(idx) = 1;
%         %tally if current condition exists
%         if ~isempty(idx)
%             pos_cond_exists(k) = true;
%         else
%             pos_cond_exists(k) = false;
%             disp('Warning:');
%             disp(positive_cons{n}{k});
%             disp('does not exist!');
%             disp('The script will ignore this condition.');
%         end
%     end
% 
%     neg_cond_exists = false(1,length(negative_cons{n}));
%     for k = 1:length(negative_cons{n}),
%         if strcmpi(negative_cons{n},baseline_cond)
%             null_counter = null_counter +1;
%         end
%         idx = strfind({SPM.Vbeta.descrip},negative_cons{n}{k});
%         idx = find(~cellfun('isempty',idx));
%         contrasts(n).con(idx) = -1;
%         %tally if current condition exists
%         if ~isempty(idx)
%             neg_cond_exists(k) = true;
%         else
%             neg_cond_exists(k) = false;
%             disp('Warning:');
%             disp(negative_cons{n}{k});
%             disp('The script will ignore this condition.');
%         end
%     end
    
     %%%%%%%% make contrast name %%%%%%%%%%%%
    if custom_name %name is defined by user
        contrasts(n).name = name{n}; % allow for custom names
    else
        % name is constructed from Beta names
        contrasts(n).name = construct_beta_names(positive_cons{n},...
            negative_cons{n},remove_bf, pos_cond_exists,neg_cond_exists);

    end
    
    %%%%%%%%% Adjusts contrast if sumtozeros is true and negative_con is defined %%%%%%%%%
    
    if (sumtozero && ~isempty(negative_cons{n}) && ~isempty(positive_cons{n})) && null_counter==0
        pos = find(contrasts(n).con > 0);
        neg = find(contrasts(n).con < 0);
        if length(neg) > length(pos),
            contrasts(n).con(neg) = contrasts(n).con(neg) * (length(pos)/length(neg));
        else
            contrasts(n).con(pos) = contrasts(n).con(pos) * (length(neg)/length(pos));
        end
    end
    
end

%% this block of will remove any contrasts with only zero elements
k = 1;
for n = 1:length(contrasts),
    if(find(contrasts(n).con)),
        foo(k)=contrasts(n);
        k = k+ 1;
    end
end
if exist('foo')
    contrasts = foo;
end
end

function con_name = construct_beta_names(positive_cons,negative_cons, ...
    rm_bf, pos_cond_exists, neg_cond_exists)
%rm_bf: whether or not remove the "*bf(1)" alike character in the names
%pos/neg_cond_exist: whether or not conditions exists

%check if there is anything ignored
if exist('pos_cond_exists','var')
    positive_cons = positive_cons(pos_cond_exists);
end
if exist('neg_cond_exists','var')
    negative_cons = negative_cons(neg_cond_exists);
end

tmp_positive_names = '';
tmp_negative_names = '';

%if positive_cons or negative_cons are simply string, convert them to cell
if ischar(positive_cons) && ~iscellstr(positive_cons)
    positive_cons = cellstr(positive_cons);
end
if ischar(negative_cons) && ~iscellstr(negative_cons)
    negative_cons = cellstr(negative_cons);
end

%combine positive names
for k = 1:length(positive_cons)
    tmp_positive_names = [tmp_positive_names,'+', positive_cons{k}];
end
%combine negative names
for l = 1:length(negative_cons)
    tmp_negative_names = [tmp_negative_names, '+',negative_cons{l},];
end
%get rid of extra plus sign
tmp_positive_names = tmp_positive_names(2:end);
tmp_negative_names = tmp_negative_names(2:end);

%remove base function sign
if rm_bf
    tmp_positive_names = regexprep(tmp_positive_names, '*bf\((\d*)\)','');
    tmp_negative_names = regexprep(tmp_negative_names, '*bf\((\d*)\)','');
end

%group negative conditions in parenthesis if there are more than one
%conditions
if length(negative_cons)>1
    tmp_negative_names = ['(',tmp_negative_names,')'];
end


%combine conditions
con_name = [tmp_positive_names, '-',tmp_negative_names];
end


function [con,null_counter,cond_exists]=generate_contrast(SPM,con,conditions,cond_value,baseline_cond)
%conditions, either postive_cons, or negative_cons
%baseline_cond: 'null' or constant conditions
%cond_value: +1 for positive conditions,-1 for negative conditions

cond_exists = false(1,length(conditions));
null_counter=0;%tally null condition
    for k = 1:length(conditions)
        %debug
        %disp(conditions{k});
        if strcmpi(conditions{k},baseline_cond)
            null_counter = null_counter +1;
            cond_exists(k) = true;
            continue;
        end
        idx = strfind({SPM.Vbeta.descrip},conditions{k});
        idx = find(~cellfun('isempty',idx));
        con(idx) = cond_value;
        %tally if current condition exists but not baseline condition
        if ~isempty(idx)
            cond_exists(k) = true;
        else
            cond_exists(k) = false;
            disp('Warning:');
            disp(conditions{k});
            disp('does not exist!');
            disp('The script will ignore this condition.');
        end
    end

end

