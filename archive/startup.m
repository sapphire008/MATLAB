function startup()
% Add my thumb drive path
Drives = getdrives('VolumeName','Lexar');
if ~isempty(Drives)
    addpath(fullfile(Drives.Caption,'StrowbridgeLab','scripts'));
end
end

function Drives = getdrives(varargin)
% Drives = getdrives(...)
% Get a list of mounted drives
% Input:
%   'DriveType' (optional): filter types of drives. Input as a vector of
%       drive types, e.g. [2,3]
%       For PC Drive types
%           0 = Unknown
%           1 = No root directory
%           2 = Removable disk
%           3 = Local disk
%           4 = Network drive
%           5 = Compact disk
%           6 = RAM disk
%   'VolumeName' (optional): filter by known drive names. Input as a
%        cellstr if multiple names to be filtered.

% parse optional inputs
flag = parseVarargin(varargin,{'DriveType',[]},{'VolumeName',{}});

if ispc
    % wmic logicaldisk where drivetype=3 get caption, name, description, 
    %          drivetype, providername, volumename
    % build and run command
    cmd = '!wmic logicaldisk get caption, description, drivetype, name, volumename, providername';
    T = evalc(cmd);
    % parse the output
    S = regexp(T,'\n','split'); % split by line
    S = S(1:(numel(regexp(T,'\n'))-1));
    S = regexp(S,'( {2,100})','split'); % split by delimiter
    S = cellfun(@(x) x(1:end-1),S,'un',0);
    % reoganize the cell
    Header = [S{1}(1:4), S{1}(6), S{1}(5)];
    Drives = cell(length(S)-1,length(S{1}));
    Drives(:) = {''};% initialize empty table
    for n = 2:length(S)
        % if description is missing (3rd column is drive letter instead 
        % of drive type numeric)
        if ~isempty(regexp(S{n}{3},'([A-Z]*):','once')) 
            S{n} = [S{n}(1),{''},S{n}(2:end)];
        end
        % if somehow drivename is missing but providername is present
        if length(S{n})==5 && strcmpi(S{n}{5}(1:2), '\\')
            S{n}{6} = S{n}{5};
            S{n}{5} = '';
        end
        % if provider name and volume name are present
        if length(S{n})>5, S{n}(5:6) = S{n}(6:-1:5); end
        Drives(n-1,1:length(S{n})) = S{n};
    end
     % make sure DriveType is numeric
     Drives(:,3) = cellfun(@str2double, Drives(:,3), 'un',0);
    
    % Filter by DriveType
    if ~isempty(flag.DriveType)
        Drives = Drives(find(ismember([Drives{:,3}], flag.DriveType)),:);
    end
    % Filter by VolumeName
    if ~isempty(flag.VolumeName)
        Drives = Drives(find(ismember(Drives(:,5),...
            cellstr(flag.VolumeName))),:);
    end
    
    % Convert to structure
    Drives = cell2struct(Drives,Header,2);
    
    % Convert to table
    % Drives = cell2table(Drives, 'VariableNames', Header);
end
end

%% varargin input
function flag = parseVarargin(options, varargin)
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

