function moveImages2Folders(folderPath)
% create folders for each set of images, based on labeled names
appendixDelimiter = '.';
namingDelimiter = ' ';

if nargin<1, folderPath = pwd; end
images = dir(fullfile(folderPath,'*.img'));
if isempty(images)
    folderPath = uigetdir(pwd, 'Select Image Directory'); 
    images = dir(fullfile(folderPath,'*.img'));
end
% move images
images = sort({images.name})';
[folders, IND, ~] = unique(cellfun(@(x) x{1}, regexp(images, ...
    fixregexpmatch(appendixDelimiter),'split'),'un',0), 'first');
IND = [IND, [IND(2:end)-1;numel(images)]];
for n = 1:length(folders)
    % construct source and destination
    source = cellfun(@(x) fullfile(folderPath, x), images(IND(n,1):IND(n,2)),'un',0);
    % parse further to get super folder
    supFolder = getSuperfolder(n<2 || ~strcmpi(folders{n}, folders{n-1}), ...
        folders{n},namingDelimiter);
    destFolder = fullfile(folderPath, supFolder, folders{n}); 
    dest = cellfun(@(x) fullfile(destFolder, x), images(IND(n,1):IND(n,2)),'un',0);
    % make the destination folder
    mkdir(destFolder);
    % move the files
    cellfun(@movefile,source, dest);
end
end

function str = getSuperfolder(redo, str, delimiter)
if ~redo, return; end
str = regexp(str, fixregexpmatch(delimiter), 'split');
str = str(1:end-1);
str = mystrjoin(str{:},'delimiter',delimiter);
end

function str = fixregexpmatch(str)
if ismember(str, '.^*+?|\/')
    str = ['(\',str,')'];
end
end

function str = mystrjoin(varargin)
% concatenate strings
% str = mystrjoin('str1','str2','str3','delimiter',' ')
% default delimiter is space ' '
if ~iscellstr(varargin), error('All inputs need to be strings'); end
IND = find(ismember(varargin, 'delimiter'),1,'last');
if ~isempty(IND)
    delimiter = varargin{IND+1}; 
    varargin = varargin(1:end-2);
else
    delimiter = ' ';
end

str = varargin{1};
for n = 2:length(varargin)
   str = [str, delimiter, varargin{n}];
end
end