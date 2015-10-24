function [V, I, S] = eph_findVCS(zData, varargin)
% Find averaged voltage, current, and stimulus, given zData
%
% Inputs:
%   zData: (char) path to episode file; (cellstr) list of episode file;
%          (cell) in format of {Cell, Episode}, e.g.
%               Cell = 'Data 26 Feb 2015/Neocortex A.26Feb15.S1.E%d.dat';
%               Episodes = 5:11;
%   Optional flags
%   'base_dir' (default ''): base directory to be prepended onto zData
%           paths
%   'window' (default [0, 0.5]): time (sec) window to average from
%   'Vchannels': list of voltage channels to extract. Default extract all.
%   'Ichannels': list of current channels to extract. Default extract all.
%   'Schannels': list of stimulus channels to extract. Default extract all.
%
% Outputs:
%   V: averaged voltage. If multiple channels used, return as a structure
%      where each field corresponds to an average of a channel
%   I: averaged current. In case of multiple channels, return a structure
%      like V.
%   S: averaged stimulus. Variable structure similar to V and I.

% Optional flags
flag = InspectVarargin(varargin, {'base_dir', ''}, ...
    {'window', [0, 0.5]}, ...
    {'Vchannels', {'VoltA','VoltB','VoltC','VoltD'}},...
    {'Ichannels', {'CurA','CurB','CurC','CurD'}}, ...
    {'Schannels', {'StimulusA', 'StimulusB','StimulusC','StimulusD'}});
% load correpsonding files
zData = getfile(zData, flag.base_dir);
% Get index of time range, assuming applying time_range to all the zData
% episodes, and all zData episodes are acquired at the same sampling
% rate.
IND = eph_time2ind(flag.window, zData(1).protocol.msPerPoint/1000);
% load voltage, current and stimulus
V = getdata(zData, flag.Vchannels, IND);
if nargout<2, return; end
I = getdata(zData, flag.Ichannels, IND);
if nargout<3, return; end
S = getdata(zData, flag.Schannels, IND);
end

function X = getdata(zData, channels, IND)
count = 0;
X = [];
for x = 1:length(channels)
     % check if field exist. The strucutre should be homogeneous
    if ~isfield(zData,channels{x}), continue; end
    % get the currents from all episodes files
    X.(channels{x}) = [];
    for k = 1:length(zData)
        X.(channels{x}) = [X.(channels{x}); zData(k).(...
            channels{x})(IND(1):IND(2))];
    end
    % average the current during the time frame for all channels
    X.(channels{x}) = mean(X.(channels{x})(:));
    % used in case only 1 channel available. This records the index of
    % the single channel.
    count = x;
end
if count<2, X = X.(channels{count}); end
end

function zData = getfile(zData, base_dir)
if ischar(zData)
    zData = eph_loadEpisodeFile(fullfile(base_dir, zData));
elseif iscellstr(zData)
    zData = cellfun(@eph_loadEpisodeFile, zData);
elseif iscell(zData) && numel(zData) == 2
    % Assuming data file structure
    Cell = zData{1};
    Episodes = zData{2};
    episodeList = sprintfc(Cell, Episodes);
    episodeList = cellfun(@(x) fullfile(base_dir, x), episodeList, 'un',0);
    zData = cell2mat(cellfun(@eph_loadEpisodeFile, episodeList, 'un',0));
elseif isstruct(zData)
    return;
else
    error('Unrecognized zData input format');
end
% Cell = 'Data 26 Feb 2015/Neocortex A.26Feb15.S1.E%d.dat';
% Episodes = 5:11;
end

function [flag,ord]=InspectVarargin(varargin_cell,varargin)
% Inspect whether there is a keyword input in varargin, else return
% default. If search for multiple keywords, input both keyword and
% default_value as a cell array of the same length.
% If length(keyword)>1, return flag as a structure
% else, return the value of flag without forming a structure
%
% [flag,ord]=InspectVarargin(varargin_cell,{k1,v1},...)
%
% Inputs:
% varargin_cell: varargin cell
% keyword (k): flag names
% default_value (v): default value if there is no input
% Input as many pairs of keys and values
%
% Outputs:
% flag: structure with field names identical to that of keyword
% ord: order of keywords being input in the varargin_cell. ord(1)
% correspond to the index of the keyword that first appeared in the
% varargin_cell
%
%
% Edward Cui. Last modified 12/13/2013
%
% reorganize varargin of current function to keyword and default_value
keyword = cell(1,length(varargin));
default_val = cell(1,length(varargin));
for k = 1:length(varargin)
    keyword{k} = varargin{k}{1};
    default_val{k} = varargin{k}{2};
end
% check if the input keywords matches the list provided
NOTMATCH = cellfun(@(x) find(~ismember(x,keyword)),varargin_cell(1:2:end),'un',0);
NOTMATCH = ~cellfun(@isempty,NOTMATCH);
if any(NOTMATCH)
    error('Unrecognized option(s):\n%s\n',...
        char(varargin_cell(2*(find(NOTMATCH)-1)+1)));
end
%place holding
flag=struct();
ord = [];
% assuming the structure of varargin_cell is {'opt1',val1,'opt2',val2,...}
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_val{n};
    end
end
%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end
end

