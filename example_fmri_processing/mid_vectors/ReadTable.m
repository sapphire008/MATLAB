function table_cell=ReadTable(file_dir,varargin)
% table = ReadTable(file_dir, ...)
% Required Input: 
%       file directory. May read .txt file and .csv file, and output a
%       table in cell array or matrix (if all the contents are numeric)
%
% Optional Inputs:
%       'delimiter': default comma ','; white-space = ' \b\t'
%
%       'numeric':   specify whether or not convert any numbers into
%                    instead of leaving them as strings when reading the
%                    file. If all the values are numeric, will output all
%                    the content as a matrix, instead of a cell array.
%                    Default: True.
%
%       'rmdupcolhead': remove duplicated column header, assuming the first
%                    row is the column header. Default: True.



flag = L_InspectVarargin(varargin,{'delimiter','numeric',...
    'rmdupcolhead'},{',',1,1});
% open the file
FID = fopen(file_dir);
%flag for the end of line in the file
ENDLINE = 0; 
%read in all the lines
lines_cell = {};
while ~ENDLINE
    clear tmp_line;
    tmp_line = fgetl(FID);
    if tmp_line == -1
        break;
    elseif isempty(tmp_line) || all(isspace(tmp_line))
        continue;%skipping empty line
    else
        lines_cell{end+1} = tmp_line;
    end
end
fclose(FID);%close opened file
%remove repeated column headers,
%assuming the first row is the column
if flag.rmdupcolhead
    col_head = lines_cell{1};
    col_head_IND = cell2mat(cellfun(@(x) strncmpi(col_head,x,...
        min(length(x),length(col_head))), lines_cell,'un',0));
    col_head_IND(1) = 0;%exclude first column header;
    lines_cell = lines_cell(~col_head_IND);
end
%check to see if the default delimiter, comma, is correct
switch flag.delimiter
    case ','
        valid_delimiter = regexp(lines_cell{1},',');
    case ' \b\t'
        valid_delimiter = regexp(lines_cell{1},'\s');
end
if isempty(valid_delimiter)
    error('Delimiter is incorrect!\nPerhaps use ...''delimiter'','' \b\t'' argument');
end

%break each lines according to delimiter
table_cell = {};
for n = 1:length(lines_cell)
    clear read_lines;
    read_lines = textscan(lines_cell{n},'%s','delimiter',flag.delimiter);
    %unwrap read_lines, so that it is a cell array of length >1
    while sum(size(read_lines) - [1,1]) == 0 && ~isempty(read_lines)
        read_lines = read_lines{1};
    end
    %transpose col cell array to row cell array
    if size(read_lines,2) <2 && size(read_lines,1) >1
        read_lines = read_lines';
    end
    table_cell(end+1,1:length(read_lines)) = read_lines;
end
%try to convert any numeric cell into numerics from string
if flag.numeric
numeric_IND = cell2mat(cellfun(@(x) ~isnan(str2double(x)),...
    table_cell,'UniformOutput',0));
table_cell(numeric_IND) = cellfun(@(x) str2double(x),...
    table_cell(numeric_IND), 'UniformOutput',0);
%if all the contents are numeric, convert to matrix
if all(numeric_IND(:))
    table_cell = cell2mat(table_cell);
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

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end

end