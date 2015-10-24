function [dicom_headers,unmatched_tags]=dicom_header_matlab(dicom_files,tags,verbose,DEBUG)
%reads the dicom header using exiftool in perl, with better header
%information instead of Private_** fields
%
%[dicom_headers,unmatched_tags] = dicom_header_matlab(dicom_files,tags,verbose)
%
% Inputs:
%       dicom_files: can be either a string to the path of the dicom
%                    image or a cellstr of dicom image directories, 
%                    or a formatted string with each row as a directory 
%                    to the dicom images
%       tags (optional):cellstr of tag names to output. If left blank or not
%                       specified, the function will output all tags
%       verbose(optional): [true|false], if true, will display
%                           unmatched fields
% Outputs:
%       dicom_headers: structure array, with each field as the tag name and
%                      and field value as the tag value
%       unmatched_tags: will return a cellstr of tags specified previous
%                       not matching any dicom tags

% The input, dicom_files, 
exiftool_PATH = '/hsgs/projects/jhyoon1/pkg64/perlpackages/Image-ExifTool-9.39/';
%parse inputs
if nargin<2 || isempty(tags)
    tags = '';
end
if nargin<3 && nargout<2
    verbose = true;
elseif nargin<3 && nargout ==2
    verbose = false;
end
if nargin<4 || isempty(DEBUG)
    DEBUG = false;
end
%convert all file names to a cellstr
dicom_files = cellstr(dicom_files);
%for each file, read the dicom header
if exist(fullfile(matlabroot,'toolbox/distcomp'),'dir') && length(dicom_files)>10
    %try to use parallel processing toolbox
    if DEBUG
        disp('Using Parallel Computing Toolbox...');
    end
    dicom_headers = cell(1,length(dicom_files));
    unmatched_tags = cell(1,length(dicom_files));
    evalc('matlabpool(5)');%create workpool
    parfor n = 1:length(dicom_files)
        [dicom_headers{n},unmatched_tags{n}] = read_header(dicom_files{n},...
            exiftool_PATH,tags,verbose);
    end
    evalc('matlabpool close');
else
    if DEBUG
        disp('Using arrayfun to calcualte ...');
    end
    [dicom_headers,unmatched_tags] = arrayfun(@(x) read_header(char(x),...
        exiftool_PATH,tags,verbose),dicom_files,'un',0);
    
end
dicom_headers = cell2mat(dicom_headers);

end

% read dicom header information for each file
function [dicom_headers,unmatched_tags] = read_header(dicom_file,exiftool_PATH,tags,verbose)
dicom_headers = struct;
%additional options for tags
if ~isempty(tags)
    %parse FileName and Directory tag request
    if ismember('FileName',tags)
        [~,FileName,EXT]=fileparts(dicom_file);
        dicom_headers.FileName=[FileName,EXT];
    end
    if ismember('Directory',tags)
        [dicom_headers.Directory,~,~]=filparts(dicom_files);
    end
    option_string =cellfun(@(x) sprintf('-DICOM:%s',x),cellstr(tags),'un',0);
    [RESULT,STATUS] = perl(fullfile(exiftool_PATH,'exiftool'),option_string{:},dicom_file);
else
    [RESULT,STATUS] = perl(fullfile(exiftool_PATH,'exiftool'),dicom_file);
end

RESULT = textscan(RESULT,'%s','Delimiter','\n');
RESULT = RESULT{1};

%parse dicom tags
for n = 1:length(RESULT)
    TEMP = regexp(RESULT{n},':','once','split');
    TEMP{1} = regexprep(strtrim(TEMP{1}),'(\W*)','');
    num = str2num(TEMP{2});
    if ~isempty(num) && all(isnumeric(num)) && ~any(isnan(num))
        TEMP{2} = num;
    end
    dicom_headers.(TEMP{1}) = TEMP{2};
    clear TEMP;
end


clear RESULT;
% check to see if FileName and/or Directory information is requested
% check to see if all fields are returned
if ~isempty(tags)
    unmatched_IND = ~ismember(tags,fieldnames(dicom_headers));
    unmatched_tags = tags(unmatched_IND);
    if any(unmatched_IND) && verbose
        fprintf('%s\nThe following fields are not found:\n',dicom_file);
        disp(unmatched_tags);
    end
else
    unmatched_tags = {''};
end
end