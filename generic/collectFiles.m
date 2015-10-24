function collectFiles(P, Q, ext, mode)
% Move/Copy/Link files to a different directory
%
% collectFiles(P, Q, ext, mode)
% 
% Inputs:
%   P: source directory that contains folders which contains files to be
%      collected
%   Q: target directory where to store the collected files. If positive
%      numeric, collect files Q directories above the original stored
%      folder. E.g. if Q is 1 (default), the collected files will be stored
%      at P
%   ext: extension, or any common characteristic names of the files to be 
%        collected. Accepts wildcards
%   mode: select from 'move', 'copy', 'link' (symbolic link) 
%
% Example:
%   collectFiles(pwd,[],'*.jpg','move');
%

if nargin<1, help('collectFiles'); return; end
if isempty(P), P = pwd; end
if nargin<2 || isempty(Q), Q = 1; end
if nargin<3 || isempty(ext), ext = '.jpg'; end
if nargin<4 || isempty(mode), mode = 'link'; end
dir_list = dir(P);
if strcmpi(dir_list(1).name,'.'), dir_list = dir_list(2:end); end
if strcmpi(dir_list(1).name,'..'), dir_list = dir_list(2:end); end
dir_list = arrayfun(@(x) fullfile(P, x.name), dir_list,'un',0);
source_list = {};
target_list = {};
% construct target collection folder
if ~isnumeric(Q) && ~ischar(Q)
    error('Unrecognized input Q (numeric or path)');
end
if Q<1
    warning('Q must be greater than 0; nothing has been modified.');
    return;
else
    for s = 1:Q
        [P,name,~] = fileparts(P);
    end
    Q = fullfile(P,name);
end
for n = 1:length(dir_list)
    % query for source files
    source = dir(fullfile(dir_list{n},['*',ext]));
    source = {source.name};
    % make target
    target = cellfun(@(x) fullfile(Q,x), source,'un',0);
    % update source list
    source_list = [source_list, cellfun(@(x) fullfile(dir_list{n}, x), source, 'un',0)];
    % make sure no duplicate names
    for m = 1:length(target)
        [target{m},target_list] = mod_duplication(target{m}, target_list);
    end
end
switch lower(mode)
    case 'move'
        cellfun(@movefile, source_list, target_list);
    case 'copy'
        cellfun(@copyfile, source_list, target_list);
    case 'link'
        cellfun(@mylinkfile, source_list, target_list);
end
% disp('source');
% disp(char(source_list));
% disp('target');
% disp(char(target_list));
end

function [target, target_list] = mod_duplication(target, target_list)
% make sure there is no duplicated names 
if ismember(target, target_list);
    target = [target, '-%d'];
    app_num = 1;
else
    target_list{end+1} = target;
    return;
end
% use while loop with safeguards
while ismember(sprintf(target,app_num), target_list) && app_num < 1000
    app_num = app_num+1;
end
target = sprintf(target, app_num);
target_list{end+1} = target;
end

function mylinkfile(source, target)
eval(['!ln -s ', source, ' ', target]);
end