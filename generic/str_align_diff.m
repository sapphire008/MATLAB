function str_out = str_align_diff(str)
% find where a list of strings start to become different

% convert string to ascii numbers
str_num = double(char(str))';
% find the columns (alinging the characters of each row) that are not all
% identical, and erase the columns that are identical
str_num = str_num(find(range(str_num,2)>0),:);
% convert the ascii numbers back to characters
switch class(str)
    case 'char'
        str_out = char(str_num');
    case 'cell'
        str_out = cellstr(char(str_num'));
end