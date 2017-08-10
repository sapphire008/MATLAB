function table_cell=ReadTable(file_dir,varargin)
% table = ReadTable(file_dir, ...)
% Required Input: 
%       file directory. May read .txt file and .csv file, and output a
%       table in cell array or matrix (if all the contents are numeric)
%
% Optional Inputs:
%       'delimiter': default comma ','; white-space = ' \b\t'
%
%       'header': has header. Default true.
%
%       'numeric':   specify whether or not convert any numbers into
%                    instead of leaving them as strings when reading the
%                    file. If all the values are numeric, will output all
%                    the content as a matrix, instead of a cell array.
%                    Default: True.
%
%       'rmdupcolhead': remove duplicated column header, assuming the first
%                    row is the column header. Default: True.
%
%       'skipto': skip specified number of lines before reading the table
%       
%       'comment': a list of comment characters. Default {'%','#'}

flag = parse_varargin(varargin, {'delimiter',','}, {'numeric',true}, ...
    {'rmdupcolhead', true}, {'skipto',0}, {'comment', {'%', '#'}}, ...
    {'header',true});
% open the file
FID = fopen(file_dir);
%flag for the end of line in the file
ENDLINE = 0; 
%read in all the lines
lines_cell = {};
lnum = 0; 
while ~ENDLINE
    clear tmp_line;
    tmp_line = fgetl(FID);
    lnum = lnum + 1;
    if tmp_line == -1
        break;
    elseif isempty(tmp_line) || all(isspace(tmp_line))
        continue;%skipping empty line
    elseif any(ismember(tmp_line(1), flag.comment))
        continue;
    elseif lnum < flag.skipto
        continue
    else
        lines_cell{end+1} = tmp_line;
    end
end
fclose(FID);%close opened file

%remove repeated column headers,
%assuming the first row is the column
if flag.rmdupcolhead && flag.header
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
    otherwise
        valid_delimiter = [];
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



function flag = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1'}.
% return flag with fields 'opt1', 'opt2', ...

% for sanity check
IND = ~ismember(options(1:2:end),cellfun(@(x) x{1}, varargin, 'un',0));
if any(IND)
    EINPUTS = options(find(IND)*2-1);
    S = warning('QUERY','BACKTRACE'); % get the current state
    warning OFF BACKTRACE; % turn off backtrace
    warning(['Unrecognized optional flags:\n', ...
        repmat('%s\n',1,sum(IND))],EINPUTS{:});
    warning('These options are ignored');
    warning(S);
end
flag = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp) % if present, assign using input value
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
    else % if not present, assign default value
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end