function con_name = construct_beta_names(positive_cons,negative_cons, ...
    rm_bf,group_neg)
%con_name = construct_beta_names(positive_cons,negative_cons,rm_bf,group_neg)
%
%positive_cons, negative_cons: cellstr of positive and negative conditions
%of one contrast. To generate names for all contrasts, use a for loop.
%
%rm_bf: [0|1] logical, default 1,
%       whether or not remove the "*bf(1)" alike character in the names
%group_neg: [0|1] logical, default 1,
%       whether use parentheses () to group multipe negative conditions

% set default for optional inputs
if nargin<3
    rm_bf = 1;
    group_neg = 1;
elseif nargin<4
    group_neg = 1;
end

% decide what to use to concatenate negative conditions
switch group_neg
    case {1}
        concate_sign = '+';
    case {0}
        concate_sign = '-';
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
    
    tmp_negative_names = [tmp_negative_names, concate_sign,negative_cons{l},];
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
if length(negative_cons)>1 && group_neg
    tmp_negative_names = ['(',tmp_negative_names,')'];
end

%combine conditions
con_name = [tmp_positive_names, '-',tmp_negative_names];
end
