function [MEA, X] = loadMEA(fileName, varargin)
% Wrapper function of NeuroShare for loading MEA (.mcd) data files without 
% converting to binary format
%
%       MEA = loadMEA(fileName, 'opt_1', val_1, ...)
%
% or to return electrode data separately
%
%       [MEA, ElectrodeData] = loadMEA(fileName, 'opt_1', val_1, ...)
%
% Inputs:
%   fileName: full path to the file
%
% Optional Inputs:
%   'select': select a list of type of data stream to load: 'Electrode',
%             'Analog','Filtered','ChannelTool','Digital','Spike',
%             'Trigger'. Default is to load all data streams available in a
%             file.
%   'elecs': select a list of electrodes to load. Default will load all 
%            the electrodes data. Input as a cellstr,e.g. {'D7','F8'}. 
%            For list of available electrodes, see MEA structure field 
%            MEA.MapInfo.channelnames. Note that the current function is
%            efficient when transversing through all the electrodes one at
%            a time. Use functions in "Example Data Loading Using 
%            NeuroShare" shown at the end of this help document.
%   'info': [true|false] return only information of the data
%   'unit': unit of the electrode time series data to be read as. Default
%           is in [mV]. Options include ['V','mV','uV'].
%   'prefer_segment': preferentially stream segment data instead of channel
%                     data, when both data exsit. Default true.
%   'stream_channel':index of electrode data to stream, instead of the 
%                    default entire time series data. Specify as 
%                    [startindex, endindex]. Setting this flag will set
%                    'prefer_segment' to false automatically
%   'stream_event':  index of event data to stream, instead of default
%                    full set of event. Specify as a vector of event index.
%   'stream_segment': index of segment data to stream, instead of default
%                     full set of segments. Specify as a vector of segment 
%                     index. Speicifying this flag will set
%                     'prefer_segment' to true automatically, regardless of
%                     what has been specified in 'prefer_segment' and
%                     'stream_channel'.
%   'verbose': [true|false] display messages. Default is false. Setting 
%              this flag to false does not suppress warnings generated by 
%              NeuroShare library.
%
% Output:
%   MEA: structure variable that contains data information and data, with
%        the following entity types for each data stream (listed as in 
%        optional input 'select', if available)
%           .LibraryInfo: information about the library (.dll, .dylib, .so
%                   etc.) to read the .mcd file.
%           .FileInfo: information about the files read
%           .EntityInfo: NeuroShare refer each stream of data (time series
%                       of the electrode, analog data, triggers,
%                       stimulations, etc) as an entity. This includes all
%                       the general information regarding the entities,
%                       including the source of the data, and type of data
%                       contained in these data streams.
%           .MapInfo: this is the presumed multielectrode array map, parsed
%                     from the electrode entity info. Note the coordinate
%                     is in [row; col].
%           .Analog/.Digital/.Electrode/.Filtered/.ChannelTool/.Spike/
%           .Trigger: each of these fields is a data stream type. 
%                       Each contains subfields: 
%                       '.Index', which maps to EntityInfo; 
%                       '.Types': types of data contained in the data 
%                                stream; 
%                       '.Channel': another structure that contains 
%                                  continuous/time series data of the data
%                                  stream, which has the following 
%                                  subfields: 
%                                   ~ 'Info': information regarding the
%                                             properties of current data,
%                                             such as sampling rate,
%                                             units, etc.
%                                   ~ 'TimeStamp': actual time of each data
%                                             point in seconds (first data
%                                             point is 0 sec).
%                                   ~ 'Data': the time series data. For
%                                             electrode data (time series),
%                                             they are arranged by
%                                             time x channel
%                                   
% For further understandings of the data stream type, read page 2 and 3 of
% the .PDF help document 'nsMCDLibrary_3.7b.pdf', included with the
% package.
%
% Streaming options of NeuroShare. See help documents of ns_GetAnalogData,
% ns_GetSegmentData, and ns_GetEventData. By default, the function load the
% entire electrode data to memory.
%
% ################ Example Data Loading Using NeuroShare ################
%[ns_RESULT, ContCount, Data] = ns_GetAnalogData(hfile, EntityID, StartIndex, IndexCount);
%[ns_RESULT, TimeStamp, Data, SampleCount, UnitID] = ns_GetSegmentData(hfile, EntityID, Index);
%[ns_RESULT, TimeStamp, Data, DataSize] = ns_GetEventData(hfile, EntityID, Index);
%[ns_RESULT, Time] = ns_GetTimeByIndex(hfile, EntityID, Index)

% Edward D. Cui. 09/23/2014: dxc430@case.edu

% DEBUG
%fileName = 'I:\GalanLab\Example25kHz.mcd';
%NeuroShare_Path = 'I:\GalanLab\NeuroShare';
% Sanity check
if ~ischar(fileName)
    error('unrecognized input fileName.');
end
if ~exist(fileName,'file')
    error('\n%s\n\ndoes not exist!\n',fileName);
end
NeuroShare_Path = fileparts(mfilename('fullpath'));
% parse varargin: default optional values
flag = parse_varargin(varargin,{'select',{'Electrode','Analog',...
    'Filtered','ChannelTool','Digital','Spike','Trigger'}}, ...
    {'info',false},{'unit','mv'},{'stream_channel',[]},...
    {'stream_event',[]},{'stream_segment',[]},{'elecs',[]},...
    {'prefer_segment',true},{'verbose',false});
if ischar(flag.select),flag.select = cellstr(flag.select);end%fool proof
if ischar(flag.elecs),flag.elecs = cellstr(flag.elecs);end %fool proof
if ~isempty(flag.stream_segment), flag.prefer_segment = true;
elseif ~isempty(flag.stream_channel), flag.prefer_segment = false; end
% Set correct libaray path
ns_SetLibrary(fullfile(NeuroShare_Path,computer,list_dynamic_library));
% Get library info
[~,MEA.LibraryInfo] = ns_GetLibraryInfo();
% Open file
[~, hfile] = ns_OpenFile(fileName);
% Get File Info
[~,MEA.FileInfo] = ns_GetFileInfo(hfile);
% Store the file name
MEA.FileInfo.FileName = fileName;
% Get Entity Info
[~,MEA.EntityInfo] = ns_GetEntityInfo(hfile,1:MEA.FileInfo.EntityCount);
% Update the type of data stream to be loaded
D = flag.select;
% Get the index for each type of entity
MEA = separate_entity_type(MEA,D);
% Parse electrode channel map data
if ismember('Electrode',D)
    [MEA.MapInfo.channelnames, MEA.MapInfo.coord, MEA.MapInfo.bin, MEA.MapInfo.name] = ...
        create_default_MEA_map({MEA.EntityInfo(MEA.Electrode.Index).EntityLabel});
end
% Prepare to Get Data and Info for Each Data Stream
if ~flag.info
    if flag.verbose,disp('Loading the file ... This may take a while ...');end
    % parse electrode selection
    if ~isempty(flag.elecs)%get only subset of the electrode data
        MEA.Electrode.Index = MEA.Electrode.Index(cellfun(@(x) ...
            find(ismember(MEA.MapInfo.channelnames,x)),flag.elecs));
    end
    % parse event data type stream index
    if ~isempty(flag.stream_event)
        EventIndex = flag.stream_event;
    else
        EventIndex = 1:max([MEA.EntityInfo([MEA.EntityInfo.EntityType]==1).ItemCount]);
    end
    % parse channel data type stream option
    if ~isempty(flag.stream_channel)
        StartIndex = flag.stream_channel(1);
        IndexCount = flag.stream_channel(end)-flag.stream_channel(1)+1;
    else
        StartIndex = 1;
        IndexCount = min([MEA.EntityInfo([MEA.EntityInfo.EntityType]==2).ItemCount]);
    end
    % parse segment data stream index
    if ~isempty(flag.stream_segment)
        SegmentIndex = flag.stream_segment(flag.stream_segment>0);
    else
        SegmentIndex = 1:max([MEA.EntityInfo([MEA.EntityInfo.EntityType]==3).ItemCount]);
    end
end
% Load Info and Data for each stream
X = [];
for d = 1:length(D)
    if ~isfield(MEA,D{d}),continue;end
    % assume the types of data for each homegeneous field are identical
    MEA.(D{d}).Types = unique([MEA.EntityInfo(MEA.(D{d}).Index).EntityType]);
    for m = 1:length(MEA.(D{d}).Types)
        % Get Index of current entity type
        IND = [MEA.EntityInfo(MEA.(D{d}).Index).EntityType] == MEA.(D{d}).Types(m);
        % load data and info
        switch MEA.(D{d}).Types(m)
            case 1 %event
                [~, MEA.(D{d}).Event.Info] = ns_GetEventInfo(hfile,MEA.(D{d}).Index(IND));
                if ~flag.info && ~isempty(EventIndex) && all(EventIndex>0)
                    [~, MEA.(D{d}).Event.TimeStamp, MEA.(D{d}).Event.Data, MEA.(D{d}).Event.DataSize] = ns_GetEventData(hfile,MEA.(D{d}).Index(IND), EventIndex);
                end
            case 2 %channel
                [~, MEA.(D{d}).Channel.Info] = ns_GetAnalogInfo(hfile,MEA.(D{d}).Index(IND));
                MEA.(D{d}).Channel.Info = arrayfun(@(x,y) setfield(x, 'ChannelName',y.EntityLabel), MEA.(D{d}).Channel.Info, MEA.EntityInfo(MEA.(D{d}).Index(IND)));
                if flag.info || (flag.prefer_segment && any(MEA.(D{d}).Types == 3)), continue; end
                if strcmpi(D{d},'Electrode') %return electrode data separately
                    if nargout>1
                        [~, ContCount, X] = ns_GetAnalogData(hfile, MEA.(D{d}).Index(IND), StartIndex, IndexCount);
                        [X, MEA.(D{d}).Channel.Info] = correct_analog_unit(X,MEA.(D{d}).Channel.Info,flag.unit);
                    else
                        [~, ContCount, MEA.(D{d}).Channel.Data] = ns_GetAnalogData(hfile, MEA.(D{d}).Index(IND), StartIndex, IndexCount);
                        [MEA.(D{d}).Channel.Data, MEA.(D{d}).Channel.Info] = correct_analog_unit(MEA.(D{d}).Channel.Data,MEA.(D{d}).Channel.Info,flag.unit);
                    end
                else
                    [~, ContCount, MEA.(D{d}).Channel.Data] = ns_GetAnalogData(hfile,MEA.(D{d}).Index(IND), StartIndex, IndexCount);
                end
                % get time stamp of the data loaded
                [~, MEA.(D{d}).Channel.TimeStamp] = ns_GetTimeByIndex(hfile, MEA.(D{d}).Index(IND), StartIndex:(StartIndex+ContCount-1));
            case 3 %segment
                [~, MEA.(D{d}).Segment.Info] = ns_GetSegmentInfo(hfile,MEA.(D{d}).Index(IND));
                if flag.info || isempty(SegmentIndex), continue; end
                if strcmpi(D{d},'Electrode') %return electrode data separately
                    if nargout>1
                        [~, MEA.(D{d}).Segment.TimeStamp, X, MEA.(D{d}).Segment.SampleCount, MEA.(D{d}).Segment.UnitID] = ns_GetSegmentData(hfile, MEA.(D{d}).Index(IND), SegmentIndex);
                        [X, MEA.(D{d}).Channel.Info] = correct_analog_unit(X,MEA.(D{d}).Channel.Info,flag.unit);
                    else
                        [~, MEA.(D{d}).Segment.TimeStamp, MEA.(D{d}).Segment.Data, MEA.(D{d}).Segment.SampleCount, MEA.(D{d}).Segment.UnitID] = ns_GetSegmentData(hfile, MEA.(D{d}).Index(IND), SegmentIndex);
                        [MEA.(D{d}).Segment.Data, MEA.(D{d}).Channel.Info] = correct_analog_unit(MEA.(D{d}).Segment.Data,MEA.(D{d}).Channel.Info,flag.unit);
                    end
                else
                    [~, MEA.(D{d}).Segment.TimeStamp, MEA.(D{d}).Segment.Data, MEA.(D{d}).Segment.SampleCount, MEA.(D{d}).Segment.UnitID] = ns_GetSegmentData(hfile, MEA.(D{d}).Index(IND), SegmentIndex);
                end
        end
    end
end
if ~flag.info
    if flag.verbose,disp('Done.');end
elseif nargout>1
    X = []; %return empty
end
% close the file
ns_CloseFile(hfile);
end



%% correct the data read unit
function [X,Info] = correct_analog_unit(X, Info, target_unit)
% Assume the units for all entries are identical
volt_unit =[lower(Info(1).Units),'-',lower(target_unit)];
switch volt_unit
    case 'v-mv'
        k = 1000;
    case 'v-uv'
        k = 1E6;
    case 'mv-v'
        k = 1E-3;
    case 'mv-uv'
        k = 1000;
    case 'uv-v'
        k = 1E-6;
    case 'uv-mv'
        k = 1E-3;
    otherwise
        k = 1;
end
% conversion
X = X*k;
% reannotate the unit
target_unit = regexprep(target_unit,'v','V','ignorecase');
Info = arrayfun(@(x) setfield(x,'Units',target_unit),Info);
Info = arrayfun(@(x) setfield(x,'MinVal',x.MinVal*k),Info);
Info = arrayfun(@(x) setfield(x,'MaxVal',x.MaxVal*k),Info);
end

%% separate data stream type
function MEA = separate_entity_type(MEA, D)
StreamType = cellfun(@(x) lower(x(1)),{MEA.EntityInfo.EntityLabel},'un',0);
[EntityList,~,INDEX] = unique(StreamType);
for n = 1:length(EntityList)
    switch EntityList{n}
        case 'e'
            F = 'Electrode';
        case 'a'
            F = 'Analog';
        case 'f'
            F = 'Filtered';
        case 'c'
            F = 'ChannelTool';
        case 'd'
            F = 'Digital';
        case 's'
            F = 'Spike';
        case 't'
            F = 'Trigger';
    end
    % Get the index
    if ismember(F,D) % for only allowed fields
        MEA.(F).Index = find(INDEX == n);
    end
    clear F;
end
end
%% create MEA map based on the info read from the data
function [channelnames, MEA_map_coord, MEA_map, MEA_map_name] = ...
    create_default_MEA_map(channelnames)
% % Given channel names, return the following types of MEA maps
%   MEA_map: with 1's indicating channel is recorded (has data) and NaN's
%            indicating channel is not recorded (data not available)
%   MEA_map_name: cell array with channel names filled instead of NaN's and
%            1's.
%   MEA_map_coord: translated coordinate of channelnames, assuming letters
%            means columns and numbers following the letters means rows;
%            e.g. A7 means first column, 7th row. MEA_map_coord(:,1) is the
%            first channel coordinate, [row; col] format.

% get channel names based on the label, assuming the last group of strings
% (after a set of spaces) are the named label
try
    channelnames = cellfun(@(x) x{end}, regexp(channelnames,' ','split'),'un',0);
    channelnames = unique(channelnames,'stable');
    % split letter and numbers (column and row labels)
    [~,~,col_nums] =  unique(cellfun(@(x) x{1}, regexp(channelnames,'([A-Z])','tokens')));
    row_nums = cellfun(@(x) str2double(x{1}{1}), regexp(channelnames,'(\d*)','tokens'));
    MEA_map = zeros(max(row_nums),max(col_nums));
    MEA_map(sub2ind(size(MEA_map),row_nums, col_nums(:)')) = 1;
    MEA_map_name = cell(size(MEA_map));
    MEA_map_name(sub2ind(size(MEA_map),row_nums, col_nums(:)')) = channelnames;
    MEA_map_coord = [row_nums;col_nums(:)'];
catch
    disp('Channel Map Information Not Available');
    channelnames = [];
    MEA_map_coord = [];
    MEA_map = [];
    MEA_map_name = [];
end
end

%% List dynamic library according to computer system
function dylib = list_dynamic_library()
switch computer
    case 'PCWIN'
        dylib = 'nsMCDLibrary.dll';
    case 'PCWIN64'
        dylib = 'nsMCDLibrary64.dll';
    case 'MACI'
        dylib = 'nsMCDLibrary.dylib';
    case 'MACI64'
        dylib = 'nsMCDLibrary.dylib';
    case 'GLNX86'
        dylib = 'nsMCDLibrary.so';
    case 'GLNX64'
        dylib = 'nsMCDLibrary.so';
end
end

%% varargin input
function [flag,key,ind] = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1','key1'}.
% returns structure of flag and key with each option name, e.g. 'opt1' as
% field names
% also returns ind variable, which specifies the index mapping between
% options and varargin
flag = struct();%place holding
key = struct();%place holding
ind = [];
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
        ind = [ind, 2*find(tmp,1) + [-1,0]];
    else
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    if numel(varargin{n})>2
        key.(varargin{n}{1}) = varargin{n}{3};
    else
        key.(varargin{n}{1}) = [];
    end
    clear tmp;
end
ind = sort(ind);
end