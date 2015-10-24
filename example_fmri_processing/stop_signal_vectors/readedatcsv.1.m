function [subject] = readedatcsv(str)
% [subject] = readstroopcsv(str)
% str = type string - the name of the subject edat file to be read
% subject = type cell array - containing the data from the file
%str = 'AX_Immediate_Lefties-53-1_converted.csv'

fid = fopen(str);

%read in headers
headers = textscan(fid,'%s',1);

% split first line into headers
headers = regexp(headers{1}{1},',','split');

% read and split second line
testline = textscan(fid,'%s',1);
testline = regexp(testline{1}{1},',','split');

%figure out if fields are numeric or strings
strformat = [];
for n = 1:size(testline,2),
    foo = regexprep(testline{n},'-','a'); % for dates 
    foo = regexprep(foo,'/','a'); % for dates
    foo = regexprep(foo,'\','a'); % for dates
    foo = regexprep(foo,':','a'); % for times
    % if we hit a NUll or NaN keep reading lines until valid data is found
    if or(~isempty(strmatch('NULL',foo)),~isempty(strmatch('NaN',foo))),
        flag = 1;
        while flag
            testline = textscan(fid,'%s',1);
            testline = regexp(testline{1}{1},',','split');
            
            if ~or(~isempty(strmatch('NULL',testline{n})),~isempty(strmatch('NaN',testline{n}))),
                flag = 0;        
                foo = regexprep(testline{n},'-','a'); % for dates 
                foo = regexprep(foo,'/','a'); % for dates
                foo = regexprep(foo,'\','a'); % for dates
                foo = regexprep(foo,':','a'); % for times
            end
        end
    end
            
    foo = isletter(foo);
    if sum(foo) == 0,
        strformat = [strformat,' %n'];
    else
        strformat = [strformat,' %s'];
    end
end
% trim extra white space
strformat = strtrim(strformat);

% return to bof
fseek(fid,0,'bof');
% read and discard header
textscan(fid,'%s',1);

data = textscan(fid,strformat,'delimiter', ',','treatAsEmpty', 'NULL');%,'EmptyValue',NaN);

fclose(fid);
    
% create a cell object = each entry contains header and data
for n = 1:size(headers,2),
    subject{n}.col = data{n};
    subject{n}.header = headers{n};
end
    
