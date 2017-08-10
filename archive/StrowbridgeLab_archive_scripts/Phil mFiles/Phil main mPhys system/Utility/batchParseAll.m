function batchParseAll(directory, functionInfo)
% generates a preParse file to speed fileBrowser loads
% file
%   base directory (all other directories are relative to this)
%   unique headers (indexed into below) as a structure array
%   function handles for extra data
%   parseData of the form:
%       node_number, parent_node, text, key, image, expandedImage, cell functions, episodes

% generates a searchable database of header files for files in the given
% directory.  also notes which cells have images of various varieties.
% first arguement is the directory to pull files from, seond is a cell
% array of function handles that act on the data to add extra info to the
% database
% functionInfo is a cell array that is n x 3 with columns:
% function name, function handle, type (one of cell or episode)
% functions of the episode variety are passed the info structure for the
% episode whereas functions of the cell variety are passed a cell array of
% file names that start with the cell name (regardless of extension)

% generateExperimentDatabase('D:\Phil Data\MultiData\dic1\', {'imageMags',
% @findPics, 'cell'; 'current', @biasColumn, 'episode'; 'voltage',
% @heldAtColumn, 'episode'})

if nargin < 1
    directory = uigetdir('','Select directory to preparse')
end
if directory == 0
    error('Invalid Directory');
end
if directory(end) ~= filesep
    directory = [directory filesep];
end

if nargin < 2
    functionInfo = {};
end
dirStack{1} = directory;
parentDirs(1) = 1;
dirPointer = 1;
matched = 0;
        
% make sure the functionHandles don't include any header fields
protocolFields = {'ampsCorandomize','imageScan','imageDuration','takeImages','ampSealTestStep',...
    'ampBridgeBalanceStep','ampCellLocation','ampCellLocationName','ampStimEnable',...
    'ampMatlabCommand','ampMonitorRin','ampRandomizeFamilies','ampTpEnable','ttlType',...
    'ttlTypeName','ttlStepEnable','ttlIntensity','ttlPulseEnable','scanWhichRoi',...
    'timePerPoint','acquisitionRate','source','sourceName','sweepWindow',...
    'channelExtGain','channelRange','channelType','ampTpMaxPer','ampTpMaxCurrent',...
    'ampTpSetPoint','ampCosineEnable','ampMatlabStim','ampPulseEnable','ampTrainEnable',...
    'ampRampEnable','ampSineEnable','ampPspEnable','ampStepEnable','ampStimulus',...
    'ampSaveStim','ampTelegraph','ampVoltage','ampCurrent','ampType','ampTypeName',...
    'ttlStepDuration','ttlStepLatency','ttlTrainEnable','ttlArbitraryEnable',...
    'ttlPulseDuration','ampPulse5Amplitude','ampPulse5Stop','ampPulse5Start',...
    'ampPulse4Amplitude','ampPulse4Stop','ampPulse4Start','ampPulse3Amplitude',...
    'ampPulse3Stop','ampPulse3Start','ampPulse2Amplitude','ampPulse2Stop',...
    'ampPulse2Start','ampPulse1Amplitude','ampPulse1Stop','ampPulse1Start',...
    'ampTrainAmplitude','ampTrainOffDuration','ampTrainOnDuration','ampTrainStart',...
    'ampSineAmplitude','ampSineOffset','ampSineFrequency','ampSineStop','ampSineStart',...
    'ampPspPeak','ampPspInterval','ampPspTau','ampPspNumber','ampPspStart',...
    'ampRampLogarithmic','ampRampStopAmplitude','ampRampStartAmplitude',...
    'ampRampStopTime','ampRampStartTime','ampStepLastAmplitude','ampStep3Amplitude',...
    'ampStep3Stop','ampStep2Amplitude','ampStep2Stop','ampStep1Amplitude',...
    'ampStep1Stop','ampStep1Start','ampStepInitialAmplitude','ampStep3Enable',...
    'ampStep2Enable','ampStep1Enable','ttlArbitrary','ttlBurstEnable','ttlTrainNumber',...
    'ttlTrainInterval','ttlTrainLatency','ttlBurstNumber','ttlBurstInterval',...
    'fileName','channelNames','startingValues','drugTime','episodeTime','cellTime',...
    'nextEpisode','repeatNumber','matlabCommand','repeatInterval','cellName','drug',...
    'bath','internal','ampEnable','ttlEnable','dataFolder','photometryHeader'};
for fieldIndex = 1:size(functionInfo, 1)
    if ismember(functionInfo{fieldIndex, 1}, protocolFields)
        error(['Function name ''' functionInfo{fieldIndex, 1} ''' is the same as a header field and will produce an ambiguous database'])
    end
end      

%if cancel was pressed then do nothing, else
if directory ~= 0
    %set up a log file to keep track of what happens
    logFID = fopen(fullfile(directory, 'logFile.txt'),'a');  
%     logFID = fopen([getenv('homedrive') getenv('homepath') filesep 'logFile.txt'], 'a');
    fprintf(logFID, '%s\n', ['batchParseAll run: ' datestr(now,'dd/mm/yy, HH:MM:SS')]);
    
    % make an empty cell if no functionHandles were passed
    if nargin < 2
        functionInfo = {};
    end

    % make sure that there is not already a preParse file here
    timeStamp = 0; % file was last updated at the beginning of time (so all info found is newer)
    if exist(fullfile(directory, 'preParse.mat'), 'file')
        % make sure the functions are not different
        oldFuns = load(fullfile(directory, 'preParse.mat'), 'functionInfo');
        if isempty(setdiff(oldFuns.functionInfo, functionInfo)) && isempty(setdiff(functionInfo, oldFuns.functionInfo))
            % just update the old file
            timeStamp = dir(fullfile(directory, 'preParse.mat'));
            timeStamp = timeStamp(1).datenum;
            load(fullfile(directory, 'preParse.mat'));
        end
    end
    if ~timeStamp
        headers = [];
        imgHeaders = [];
        parseData = struct('parentNode', nan, 'text', directory(find(directory == filesep, 1, 'last') + 1:end), 'key', directory, 'image', 12);
        parseData(1:5000) = parseData;
        numParsed = 1;    
    else
        numParsed = length(parseData);
        numOriginal = numParsed; % to keep track of whether any are added
    end
    while dirPointer <= numel(dirStack) 
        disp(['Looking at ' dirStack{dirPointer}])
        
        %generate a list of all directories in the current directory
        if numel(dirStack{dirPointer}) >= 7 && strcmp(dirStack{dirPointer}(1:7), 'Desktop')
            fileList = dir(fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'), dirStack{dirPointer}));
        elseif numel(dirStack{dirPointer}) == 2
            % otherwise 'C:' returns the children of the working directory (if
            % it is on C)
            fileList = dir([dirStack{dirPointer} filesep]);
        else
            fileList = dir(dirStack{dirPointer});
        end
        dirCount = 0;

        fileList = fileList([fileList.datenum] > timeStamp);
        [indices indices] = sort([fileList.datenum]);
        fileList = fileList(indices);
        
        % add control characters to the beginning of folders with dates as
        % titles to put them in date order
        whichFiles = [];
        clear tempData;
        for i = 1:length(fileList)
            if fileList(i).isdir && ~strcmpi(fileList(i).name, 'System Volume Information') && fileList(i).name(1) ~= '.'
                dirCount = dirCount + 1;
                tempData{dirCount} = upper(fileList(i).name);
                whichFiles(dirCount) = i;
                for j = 1:12
                    if ~isempty(strfind(tempData{dirCount}, upper(datestr([2005 j 24 12 34 56], 'mmm')))) || ~isempty(strfind(tempData{dirCount}, datestr([2005 j 24 12 34 56], 'mmm')))
                        tempData{dirCount} = [char(j) tempData{dirCount}];
                        spaces = find(tempData{dirCount} == ' ');
                        if length(spaces) > 1 && spaces(2) - spaces(1) == 2
                            tempData{dirCount} = [tempData{dirCount}(1:spaces(1)) char(1) tempData{dirCount}(spaces(1) + 1:end)]; 
                        end
                    end
                end
            end
        end
        if exist('tempData', 'var')
            [junk indices] = sort(tempData);
            for i = 1:length(indices)
                if timeStamp > 0
                    hasMatch = find(strcmp({parseData.key}, [dirStack{dirPointer} fileList(whichFiles(indices(i))).name filesep]));
                    if ~isempty(hasMatch)
                        dirStack{end + 1} = parseData(hasMatch).key;                        
                        parentDirs(end + 1) = hasMatch;
                        continue
                    end
                end
                numParsed = numParsed + 1;
                parseData(numParsed).parentNode = parentDirs(dirPointer);
                parseData(numParsed).text = fileList(whichFiles(indices(i))).name;
                parseData(numParsed).key = [dirStack{dirPointer} fileList(whichFiles(indices(i))).name filesep];
                parseData(numParsed).image = 12;
                parseData(numParsed).episodes = {};
                dirStack{end + 1} = parseData(numParsed).key;
                parentDirs(end + 1) = numParsed;
            end
        end
        
        % parse episodes
        matList = {fileList(~cellfun('isempty', regexp({fileList.name}, '\.S\d*\.E\d*\.[dm]at'))).name};
        cellFull = cellfun(@(x) x{1}, regexp(matList, '.+\..+(?=\.S)', 'match'), 'uniformOutput', false);        
        cellNames = cellfun(@(x) x{1}, regexp(matList, '.+(?=\..+\.S)', 'match'), 'uniformOutput', false);
        sequences = cellfun(@(x) str2double(x), regexp(matList, '(?<=S)[0-9]+(?=\.E)', 'match'));
        
        % parse images
        imgList = {fileList(~cellfun('isempty', regexp({fileList.name}, '.+\..+\..+\.img'))).name}; 
        imgCellNames = cellfun(@(x) x{1}, regexp(imgList, '^.+?(?=\.)', 'match'), 'uniformOutput', false);
        imgCellLocations = cellfun(@(x) x{1}, regexp(imgList, '(?<=\.).+?(?=\.)', 'match'), 'uniformOutput', false);
        
        % parse low-res images
        picList = {fileList(~cellfun('isempty', strfind({fileList.name}, '.pic'))).name}; 
        picCellNames = cellfun(@(x) x{1}, regexp(picList, '^.+?(?=\.)', 'match'), 'uniformOutput', false);

        for cellIndex = unique(cellFull)
            q = cellIndex{1}(1:find(cellIndex{1} == '.', 1, 'first') - 1);
            whichMat = strcmp(cellNames, q);
            whichImg = strcmp(imgCellNames, q);
            whichPic = find(strcmp(picCellNames, q));
            
            whatPresent = 2 * any(whichMat) + any(whichImg) + 4 * ~isempty(whichPic);

            % generate the cell node	
                if whatPresent > 0
                    numParsed = numParsed + 1;                    
                    nodeNum = numParsed;
                    if timeStamp > 0
                        hasMatch = find(strcmp({parseData.key}, [dirStack{dirPointer} q]));
                        if ~isempty(hasMatch)
                            nodeNum = hasMatch;
                            numParsed = numParsed - 1;
                        end
                    end
                    parseData(nodeNum).parentNode = parentDirs(dirPointer);
                    parseData(nodeNum).text = q;
                    parseData(nodeNum).key = [dirStack{dirPointer} q];
                    parseData(nodeNum).image = whatPresent;
                    parseData(nodeNum).episodes = {};
                    parseData(nodeNum).loadWith = [];
                    cellNode = nodeNum;
                    cellName = parseData(nodeNum).key;
                end

            % generate any sequence nodes
                if any(whichMat)
                    for seqIndex = unique(sequences(whichMat))
                        numParsed = numParsed + 1;
                        nodeNum = numParsed;
                        if timeStamp > 0
                            hasMatch = find(strcmp({parseData.key}, [dirStack{dirPointer} cellIndex{1} '.S' sprintf('%0.0f', seqIndex)]));
                            if ~isempty(hasMatch)
                                nodeNum = hasMatch;
                                numParsed = numParsed - 1;
                            end
                        end                        
                        parseData(cellNode).loadWith(end + 1) = nodeNum;
                        parseData(nodeNum).parentNode = cellNode;
                        parseData(nodeNum).text = ['S' sprintf('%0.0f', seqIndex) '  (' sprintf('%3.0f', sum(sequences(whichMat) == seqIndex)) ')'];
                        parseData(nodeNum).key = [dirStack{dirPointer} cellIndex{1} '.S' sprintf('%0.0f', seqIndex)];
                        parseData(nodeNum).image = 13;
                        parseData(nodeNum).episodes = {};

                        for w = matList(sequences == seqIndex & whichMat)
                            w = w{1};
                            %load file
                            protocol = readTrace([dirStack{dirPointer} w], 1);
                            if isempty(protocol)
                                fprintf(logFID, '%s\n', ['*****Error reading file: ', dirStack{dirPointer} w]);  
                                continue
                            end

                            parseData(nodeNum).episodes{end + 1}.fileName = w;
                            for fieldIndex = {'channelNames', 'startingValues', 'drugTime', 'cellTime', 'episodeTime', 'ampStep1Amplitude'}
                                if isfield(protocol, fieldIndex{1})
                                    parseData(nodeNum).episodes{end}.(fieldIndex{1}) = protocol.(fieldIndex{1});
                                else
                                    parseData(nodeNum).episodes{end}.(fieldIndex{1}) = nan;
                                end
                            end

                            % try the extra functions
                            try
                                for functionIndex = find(strcmp({functionInfo{:, 3}}, 'episode'))
                                    parseData(nodeNum).episodes{end}.(functionInfo{functionIndex, 1}) = functionInfo{functionIndex, 2}(protocol);
                                end
                            catch
                                whoops = lasterror;
                                outError = '*****Error:';
                                for errorIndex = 1:numel(whoops.stack)
                                   outError = [outError ' in ' whoops.stack(errorIndex).name ' at line ' num2str(whoops.stack(errorIndex).line) ';'];
                                end
                                fprintf(logFID, '%s\n %s\n', [outError, ' File: ', dirStack{dirPointer} w], whoops.message, char(13));  
                            end

                            % check to see if this header already exists
                            foundHeader = 0;
                            protocol = rmfield(protocol, intersect(fields(protocol), {'fileName', 'channelNames', 'startingValues', 'drugTime', 'cellTime', 'ampStep1Amplitude', 'episodeTime', 'nextEpisode', 'repeatNumber', 'repeatInterval', 'cellName', 'dataFolder'}));
                            for headerIndex = 1:numel(headers)
                                if isequalwithequalnans(protocol, headers(headerIndex))
                                    foundHeader = headerIndex;
                                    break
                                end
                            end

                            if foundHeader > 0
                                matched = matched + 1;
                                parseData(nodeNum).episodes{end}.headerIndex = foundHeader;
                            else
                                if isempty(headers)
                                    headers = protocol;
                                else
                                    try
                                        headers(end + 1) = protocol;
                                    catch
                                        % wrong protocol fields
%                                         setdiff(fields(headers), fields(protocol))
%                                         setdiff(fields(protocol), fields(headers))
%                                         hFields = fields(headers);
%                                         pFields = fields(protocol);
%                                         hFields(~strcmp(hFields, pFields))
%                                         pFields(~strcmp(hFields, pFields))
%                                         'Cell A.11Apr08.S1.E1.mat' has cosineEnable off by 4 fields
%                                         photometryHeader, ampCosineEnable,
                                        disp(['File: ', dirStack{dirPointer} w]);  
                                        disp(setdiff(fields(headers(end)), fields(protocol)));
                                    end
                                end
                                parseData(nodeNum).episodes{end}.headerIndex = numel(headers);
                            end
                        end                       
                        
                        % deal with any function handles that are cell level
                        for functionIndex = find(strcmp({functionInfo{:, 3}}, 'cell'))
                            parseData(cellNode).(functionInfo{functionIndex, 1}) = functionInfo{functionIndex, 2}(~[tempDir.isdir] & ~cellfun('isempty', strfind({tempDir.name}, cellName)));
                        end	                        
                    end
                end

            % generate any pic nodes
                if ~isempty(whichPic)
                    numParsed = numParsed + 1;
                    nodeNum = numParsed;
                    if timeStamp > 0
                        hasMatch = find(strcmp({parseData.key}, [dirStack{dirPointer} q '.pic']));
                        if ~isempty(hasMatch)
                            nodeNum = hasMatch;
                            numParsed = numParsed - 1;
                        end
                    end                      
                    parseData(nodeNum).parentNode = cellNode;
                    parseData(nodeNum).text = ['  (' sprintf('%3.0f', numel(whichPic)) ')'];
                    parseData(nodeNum).key = [dirStack{dirPointer} q '.pic'];
                    parseData(nodeNum).image = 14;
                    parseData(nodeNum).episodes = {};
                end

            % generate any img nodes
                if any(whichImg)
                    numParsed = numParsed + 1;
                    nodeNum = numParsed;
                    if timeStamp > 0
                        hasMatch = find(strcmp({parseData.key}, [dirStack{dirPointer} q '.img']));
                        if ~isempty(hasMatch)
                            nodeNum = hasMatch;
                            numParsed = numParsed - 1;
                        end
                    end                      
                    parseData(nodeNum).parentNode = cellNode;
                    parseData(nodeNum).text = ['  (' sprintf('%3.0f', sum(whichImg)) ')'];
                    parseData(nodeNum).key = [dirStack{dirPointer} q '.img'];
                    parseData(nodeNum).image = 15;
                    parseData(nodeNum).episodes = {};
                    parseData(nodeNum).loadWith = [];
                    imgNode = nodeNum;

                    for imgIndex = unique(imgCellLocations(whichImg))'
                        numParsed = numParsed + 1;
                        nodeNum = numParsed;
                        if timeStamp > 0
                            hasMatch = find(strcmp({parseData.key}, [dirStack{dirPointer} q '.' imgIndex{1}]));
                            if ~isempty(hasMatch)
                                nodeNum = hasMatch;
                                numParsed = numParsed - 1;
                            end
                        end                          
                        parseData(imgNode).loadWith(end + 1) = nodeNum;                        
                        parseData(nodeNum).parentNode = imgNode;
                        parseData(nodeNum).text = [imgIndex{1} '  (' sprintf('%3.0f', numel(strmatch(imgIndex{1}, imgCellLocations(whichImg), 'exact'))) ')'];
                        parseData(nodeNum).key = [dirStack{dirPointer} q '.' imgIndex{1}];
                        parseData(nodeNum).image = 16;
                        parseData(nodeNum).episodes = {};
                        
                        for w = imgList(strcmp(imgIndex{1}, imgCellLocations) & whichImg)
                            w = w{1};
                            %load file
                            protocol = readImage([dirStack{dirPointer} w], 1);
                            if isempty(protocol)
                                fprintf(logFID, '%s\n', ['*****Error reading file: ', dirStack{dirPointer} w]);  
                                continue
                            end

                            parseData(nodeNum).episodes{end + 1}.fileName = w;

                            if isempty(imgHeaders)
                                imgHeaders = protocol.info;
                            else
                                try
                                    imgHeaders(end + 1) = protocol.info;
                                catch
                                    % wrong protocol fields
                                end
                            end
                            parseData(nodeNum).episodes{end}.headerIndex = numel(imgHeaders);
                        end                                  
                    end
                end          
        end      

        dirPointer = dirPointer + 1;
    end   
    
    if timeStamp == 0
        parseData(numParsed + 1:end) = [];
    end

    % close log file
    fprintf(logFID, '%s\n', [sprintf('%1.2f', 100 * matched / (length(parseData) + matched)) '% compressed']);
    fclose(logFID);
    disp([sprintf('%1.2f', 100 * matched / (length(parseData) + matched)) '% compressed']);

    % save database
    try
        if ~timeStamp || length(parseData) > numOriginal
            % The file is only written if there have been changes to it.
            % This keeps the local copies that fileBrowser creates as
            % current.
            save([directory filesep 'preParse.mat'], 'directory', 'headers', 'imgHeaders', 'functionInfo', 'parseData', '-v6')        
%             save([getenv('homedrive') getenv('homepath') filesep 'preParse.mat'], 'directory', 'headers', 'imgHeaders', 'functionInfo', 'parseData', '-v6')                    
        end
    catch
        keyboard
    end    
end