function [positive_cons,negative_cons]= make_contrasts_conditions(...
    all_positives, all_negatives, basis_func,varargin)
% [positive_cons, negative_cons] = make_contrasts_conditions(...
%           all_positives,all_negatives, basis_func,...)
%
% Providing all the positive conditions, all the negative conditions, and
% all the basis functions, which are all cell array of strings, the
% function will compute all possible combinations of the three.
% Each resultant positive and negative cons pair will not have any
% intersections, or any common elements.
% 
% Optional Inputs:
%       'no_bf':  cellstr to tell the function which conditions listed in
%                 both positive and negative conditions should not include 
%                 a basis function. By default it is 'null'
%       
%       'conv_sym': Default convolution symbol is '*'.
%
%
% This function will not generate names, use make_contrasts to generate
% names instead, if wants automated names
% 
% Formula for quickly building basis_funcs if they are quite regular like
% {'bf(1)','bf(2)','bf(3)','bf(4)','bf(5)','bf(6)'}
% basis_func = cellstr([repmat('bf(',6,1),strrep(num2str(1:6),' ','')',...
%       repmat(')',6,1)]); %whwere 6 is the number of basis funcs

%convolution symbol between conditions and basis functions
flag = L_InspectVarargin(varargin,{'conv_sym','no_bf'},{'*',{'null'}});
conv_symbol = flag.conv_sym; % '*' by default
%which conditions within positives or negatives have no basis function?
no_bf = flag.no_bf; % no_bf = {'null'} by default

%generating all possible combinations of contrast pairs, in terms of index
[pos_ind,neg_ind] = meshgrid([1:length(all_positives)],[1:length(all_negatives)]);
pos_ind = pos_ind(:);%make sure it is column vector
neg_ind = neg_ind(:);%make sure it is column vector
%combine conditions with all the possibilities generated
tmp_comb = arrayfun(@(x,y) [all_positives(x), all_negatives(y)], pos_ind, neg_ind,'un',0);

%clean up combinations where positive and negatives have intersections
%(self-contrasts)
self_IND = false(size(tmp_comb,1),1);
for n = 1:length(self_IND)
    if iscellstr(tmp_comb{n})%in case both contrasts are cell
        self_IND(n) = strcmpi(tmp_comb{n}{1},tmp_comb{n}{2});
    else%if one or both of the contrasts are in cell array
        %if there is duplicate, then concatenated cell array will be
        %shortwer than before taking unique elements out
        self_IND(n) = length(unique(horzcat(tmp_comb{n}{1},...
            tmp_comb{n}{2})))<length(horzcat(tmp_comb{n}{1},tmp_comb{n}{2}));
    end
end
%eliminating intersected/self-contrast
tmp_comb = tmp_comb(~self_IND);

%disply all the potential contrasts, and let the user choose
satif = false;
while ~satif%keep prompting people until satisfied with contrasts made
for l = 1:size(tmp_comb,1)
    disp([['Contrast(',num2str(l),')= '],construct_beta_names(...
        tmp_comb{l}{1},tmp_comb{l}{2},0)]);
end
disp('');
disp('Which contrasts would you like create?');
disp('Enter the index as a vector, [1,3,4,5,....]');
which_cons = input('Press Enter to select all contrasts\n');
if ~isempty(which_cons)
    new_tmp_comb = tmp_comb(which_cons);
else
    break;
end
disp('');
disp('Your new contrasts are:');
for l = 1:size(new_tmp_comb,1)
    disp([['Contrast(',num2str(l),')= '],construct_beta_names(...
        new_tmp_comb{l}{1},new_tmp_comb{l}{2},0)]);
end
satif_ans = input('Apply? (Y/N): ','s');
switch satif_ans
    case {'Yes','yes','Y','y','ok','OK','Ok','Okay',1,true,'True','true','T'}
        tmp_comb = new_tmp_comb;
        satif = true;
    otherwise
        continue;
end
end

%for each contrast name, append basis function
positive_cons = {};
negative_cons = {};
for m = 1:length(basis_func)
    tmp_bf = string_replace(tmp_comb,'(.*)',['$1',conv_symbol,basis_func{m}]);
    for k = 1:length(no_bf)%remove basis function with no_bf
        tmp_bf = string_replace(tmp_bf,[no_bf{k},'(.*)'],[no_bf{k}]);
    end
    positive_cons((end+1):(end+size(tmp_comb)),1) = cellfun(@(x) x{1},tmp_bf,'un',0);
    negative_cons((end+1):(end+size(tmp_comb)),1) = cellfun(@(x) x{2},tmp_bf,'un',0);
end

%make sure the returned contents are cellstrs
positive_cons = cellfun(@cellstr,positive_cons,'un',0);
negative_cons = cellfun(@cellstr,negative_cons,'un',0);

end


%% Sub-functions

%% make contrast names based on conds
function con_name = construct_beta_names(positive_cons,negative_cons, ...
    rm_bf)
%rm_bf: whether or not remove the "*bf(1)" alike character in the names

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

%% String replace scripts written by Dennis
function new_struct = string_replace(old_struct, oldstr, newstr)
% new_struct = string_replace(old_struct, oldstr, newstr)
% string_replace -Does a recursive replacement of strings in a data structure
% It should work with char arrays, cell arrays, and structures
% In SPM can be used to modify SPM.mat files and job files
%
% new_struct = the data structure with strings replaced
% old_struct = the original data structure
% oldstr =  string to be replaced
% newstr = replacement string
% written Dennis Thompson, UCDavis Imaging Research Center, 07/23/2008

data_type = class(old_struct);

switch data_type        
    case 'cell' % if type is cell we need to do a recursion
        new_struct = expand_cell(old_struct, oldstr, newstr);  
        
    case 'struct' % if type is struct we need to do a recursion
        new_struct = expand_struct(old_struct, oldstr, newstr);
      
    case 'char' % if data type is char we can do the replacement
        new_struct = replace_string(old_struct, oldstr, newstr);
        
    otherwise  % if data type is "none of the above" we don't do anything
        new_struct = old_struct;
end
end


function new_struct = replace_string(old_struct, oldstr, newstr);
% this does the string replacement
[row,col] = size(old_struct);
% test empty array
if(~and(row,col)) new_struct = old_struct;
else
    for n = 1:row % I am assuming that the string are stored in a row vector :-)
        new_struct(n,:) = regexprep(old_struct(n,:), oldstr, newstr);
    end
end
end


function new_struct = expand_cell(old_struct, oldstr, newstr);
% this does the a series of recursive calls to expand the cell array
[row,col] = size(old_struct);
% check for zero arrays
if(~and(row,col)) new_struct = old_struct;
else
    for n = 1:row,
        for k = 1:col % recursive call
            new_struct{n,k} = string_replace(old_struct{n,k}, oldstr, newstr);
        end
    end
end
end



function new_struct = expand_struct(old_struct, oldstr, newstr);
% this does the a recursive call for each field in the structure
[row,col] = size(old_struct);
% check for zero arrays
if(~and(row,col)) new_struct = old_struct;
else
    for n = 1:row,
        for k = 1:col,
            names = fieldnames(old_struct(n,k));
            if isempty(names), new_struct(n,k) = old_struct(n,k);
            else
                for z = 1:length(names) % recursive call
                    new_struct(n,k).(names{z}) = string_replace(old_struct(n,k).(names{z}), oldstr, newstr);
                end
            end
        end
    end
end
end

%% Inspect varagin inputs
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
