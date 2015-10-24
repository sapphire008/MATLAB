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
