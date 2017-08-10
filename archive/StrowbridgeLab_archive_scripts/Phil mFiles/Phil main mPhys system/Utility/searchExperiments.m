function [whichCell whichEpiText whichHeaders] = searchExperiments(database, headerQuery, episodeQuery)
persistent savedDatabase
persistent headers
persistent parseData

% search through a database and return all cells that match the searchStrings
% cellList = searchExperimtents(databaseLocation, headerSpecs1, headerSpecs2, ...)
% inputs are of the form: [headers.episodeLength] == 5000

% searchExperimentsExample(database = fullfile(tempdir, 'preParse.mat'), '#ampSineAmplitude > 0# & #ampSineFrequency < 30# & #strcmp(ampMatlabCommand,''rand'')# | #cellTime > 1000#')
% always have a space after a keyword (or its indexing)

% gist:
% take a query of the the form #ampSineAmplitude > 0# & #ampFreq < 30# & #strcmp(ampMatlabCommand,'rand')#
% and turn it into [0 1 0] & [1 1 1] & [0 1 1] by generating and evaluating
% a string that is loops
% evaluate it to get the correct episodes [0 1 0]
% determine which cells have these episodes

% surround subqueries with # signs
% for instance:
% #ampSineAmplitude > 0# & #ampFreq < 30# & #strcmp(ampMatlabCommand,'rand')#

% if database is already loaded then don't reload
if strcmp(database, '-appdata')
    parseData = getappdata(getappdata(0, 'fileBrowser'), 'episodeInfo');
    headers = getappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders');
else
    try
        if ~strcmp(savedDatabase, database) || isempty(headers)
            load(database);
            clear directory functionInfo imgHeaders
            savedDatabase = database;
        end
    catch
        if ischar(database)
            error('Database not found')
        else
            error('Error reading database.  Input should be a char array')
        end
    end
end

% remove image and directory nodes
toKeep = ([parseData.image] > 0 & [parseData.image] < 8) | [parseData.image] == 13;

headerFields = fields(headers);
firstWithEpisodes = 0;
episodeFields = [];
while firstWithEpisodes <  size(parseData, 2) && isempty(episodeFields)
    firstWithEpisodes = firstWithEpisodes + 1;
    if toKeep(firstWithEpisodes)
        episodeFields = parseData(firstWithEpisodes).episodes;
    end
end
episodeFields = fields(parseData(firstWithEpisodes).episodes{1});

metaVar = 65; % letter indices of variables that tokens get evaluated to
varDefs = ''; % char array that will get evaluated containing token reductions 
% find keywords that are header fields
if ~isempty(headerQuery)
    if isempty(strfind(headerQuery, '#'))
        % assume that can be evaluated whole
        headerQuery = ['#' headerQuery '#'];
    end    
    
	% look for each field of headerFields
    tokens = regexp(headerQuery, '#.*?#', 'match');
    
    for tokenIndex = 1:numel(tokens)
        % find the header field
        try
            whichField = headerFields{cellfun(@(x) ~isempty(x), regexp(tokens{tokenIndex}, headerFields, 'match'))};
        catch
            % either a mistake or a episode field
            warning([tokens{tokenIndex} ' is not a valid query, in headers query']);            
            continue
        end
        % replace the boolean token with a variable
        headerQuery = regexprep(headerQuery, regexptranslate('escape', tokens{tokenIndex}), char(metaVar));
        
        whereStart = strfind(tokens{tokenIndex}, whichField);

        varIndex = 97;
        defStart = [char(metaVar) ' = false(numel(headers), 1);' char(13) 'for headerIndex = 1:numel(headers)' char(13) ];
        defMiddle = ['headers(headerIndex).' whichField];
        defEnd = ['end' char(13)];
        
        switch class(headers(1).(whichField))
            case 'cell'
                if numel(tokens{tokenIndex}) >= whereStart + numel(whichField) + 1 && strcmp(tokens{tokenIndex}(whereStart + numel(whichField) + 1), '{')
                    % assume that they have specified which ones they want
                    parenEnd = find(tokens{tokenIndex}(whereStart + numel(whichField) + 2:end) == '}', 1, 'first');
                    whereCommas = [0 find(tokens{tokenIndex}(whereStart + numel(whichField) + 2):parenEnd - 1 == ',') parenEnd - 1];
                    defMiddle = [defMiddle '{'];
                    
                    for dimIndex = 2:numel(whereCommas)
                        whatNums = str2num(tokens{tokenIndex}(whereStart + numel(whichField) + whereCommas(dimIndex - 1):whereCommas(dimIndex)));
                        if isnan(whatNums)
                            % whatever it was it will be treated as a ':'
                            defStart = [defStart 'for ' char(varIndex) ' = 1:size(headers(headerIndex).' whichField ', ' sprintf('%0.0f', dimIndex - 1) ')' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        else
                            defStart = [defStart 'for ' char(varIndex) ' = [' num2str(whatNums) ']' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        end
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) '}'];
                else
                    % assume that they want them all
                    defMiddle = [defMiddle '{'];
                    
                    for dimIndex = 1:ndims(headers(1).(whichField))
                        defStart = [defStart 'for ' char(varIndex) ' = 1:size(headers(headerIndex).' whichField ', ' sprintf('%0.0f', dimIndex) ')' char(13)];
                        defMiddle = [defMiddle varIndex ', '];
                        defEnd = [defEnd 'end' char(13)];
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) '}'];
                end                        
            case 'struct'
                % need to recur into this function for structures
                % ***********************************************
                % ****** NOT YET IMPLEMENTED ********************
                % ***********************************************
                
            case 'char'
                % no need to do anything
            otherwise
                % assume is a vector
                if strcmp(tokens{tokenIndex}(whereStart + numel(whichField) + 1), '(')
                    % assume that they have specified which ones they want
                    parenEnd = find(tokens{tokenIndex}(whereStart + numel(whichField) + 2:end) == '}', 1, 'first');
                    whereCommas = [0 find(tokens{tokenIndex}(whereStart + numel(whichField) + 2):parenEnd - 1 == ',') parenEnd - 1];
                    defMiddle = [defMiddle '('];
                    
                    for dimIndex = 2:numel(whereCommas)
                        whatNums = str2num(tokens{tokenIndex}(whereStart + numel(whichField) + whereCommas(dimIndex - 1):whereCommas(dimIndex)));
                        if isnan(whatNums)
                            % whatever it was it will be treated as a ':'
                            defStart = [defStart 'for ' char(varIndex) ' = 1:size(headers(headerIndex).' whichField ', ' sprintf('%0.0f', dimIndex - 1) ')' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        else
                            defStart = [defStart 'for ' char(varIndex) ' = [' num2str(whatNums) ']' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        end
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) ')'];
                else
                    % assume that they want them all
                    defMiddle = [defMiddle '('];
                    
                    for dimIndex = 1:ndims(headers(1).(whichField))
                        defStart = [defStart 'for ' char(varIndex) ' = 1:size(headers(headerIndex).' whichField ', ' sprintf('%0.0f', dimIndex) ')' char(13)];
                        defMiddle = [defMiddle varIndex ', '];
                        defEnd = [defEnd 'end' char(13)];
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) ')'];
                end      
        end
        
        % add in the text to the command
        varDefs = [varDefs defStart char(metaVar) '(headerIndex) = ' char(metaVar) '(headerIndex) || ' regexprep(tokens{tokenIndex}(2:end - 1), whichField, defMiddle) ';' char(13) defEnd];        
        metaVar = metaVar + 1;
    end

    % determine which episodes qualify
%     eval([varDefs 'whichHeaders = find(' headerQuery ');']);    
    whichCell = [];
    whichEpi = {};
%     for cellIndex = find(toKeep)
%         numEpis = 0;
%         for epiIndex = 1:numel(parseData(cellIndex).episodes)
%             if ismember(parseData(cellIndex).episodes{epiIndex}.headerIndex, whichHeaders)
%                 numEpis = numEpis + 1;
%                 whichEpi{numel(whichCell) + 1}(numEpis) = epiIndex;
%             end
%         end
%         if numEpis
%             whichCell(end + 1) = cellIndex;
%         end
%     end    
else
    whichCell = [];
    whichEpi = {};
    for cellIndex = find(toKeep)
        whichEpi{numel(whichCell) + 1} = 1:numel(parseData(cellIndex).episodes);
        whichCell(end + 1) = cellIndex;
    end  
end


if nargin > 2
    % there are further stipulations so figure that out
    if isempty(strfind(episodeQuery, '#'))
        % assume that can be evaluated whole
        episodeQuery = ['#' episodeQuery '#'];
    end    
    
	% look for each field of episodeFields
    tokens = regexp(episodeQuery, '#.*?#', 'match');
    
    varDefs = '';
    for tokenIndex = 1:numel(tokens)
        % find the episode field
        try
            whichField = episodeFields{cellfun(@(x) ~isempty(x), regexp(tokens{tokenIndex}, episodeFields, 'match'))};
        catch
            % either a mistake or a episode field
            warning([tokens{tokenIndex} ' is not a valid query, in episode query']);
            continue
        end        
        whereStart = strfind(tokens{tokenIndex}, whichField);

        varIndex = 97;
        defStart = ['keep = false;' char(13)];
        defMiddle = ['parseData(whichCell(cellIndex)).episodes{whichEpi{cellIndex}(epiIndex)}.' whichField];
        defEnd = '';
        
        switch class(parseData(firstWithEpisodes).episodes{1}.(whichField))
            case 'cell'
                if strcmp(tokens{tokenIndex}(whereStart + numel(whichField) + 1), '{')
                    % assume that they have specified which ones they want
                    parenEnd = find(tokens{tokenIndex}(whereStart + numel(whichField) + 2:end) == '}', 1, 'first');
                    whereCommas = [0 find(tokens{tokenIndex}(whereStart + numel(whichField) + 2):parenEnd - 1 == ',') parenEnd - 1];
                    defMiddle = [defMiddle '{'];
                    
                    for dimIndex = 2:numel(whereCommas)
                        whatNums = str2num(tokens{tokenIndex}(whereStart + numel(whichField) + whereCommas(dimIndex - 1):whereCommas(dimIndex)));
                        if isnan(whatNums)
                            % whatever it was it will be treated as a ':'
                            defStart = [defStart 'for ' char(varIndex) ' = 1:size(parseData(whichCell(cellIndex)).episodes{whichEpi{cellIndex}(epiIndex)}.' whichField ', ' sprintf('%0.0f', dimIndex - 1) ')' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        else
                            defStart = [defStart 'for ' char(varIndex) ' = [' num2str(whatNums) ']' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        end
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) '}'];
                else
                    % assume that they want them all
                    defMiddle = [defMiddle '{'];
                    
                    for dimIndex = 1:ndims(parseData(firstWithEpisodes).episodes{1}.(whichField))
                        defStart = [defStart 'for ' char(varIndex) ' = 1:size(parseData(whichCell(cellIndex)).episodes{whichEpi{cellIndex}(epiIndex)}.' whichField ', ' sprintf('%0.0f', dimIndex) ')' char(13)];
                        defMiddle = [defMiddle varIndex ', '];
                        defEnd = [defEnd 'end' char(13)];
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) '}'];
                end                        
            case 'struct'
                % need to recur into this function for structures
                % ***********************************************
                % ****** NOT YET IMPLEMENTED ********************
                % ***********************************************
                
            case 'char'
                % no need to do anything
            otherwise
                % assume is a vector
                if strcmp(tokens{tokenIndex}(whereStart + numel(whichField) + 1), '(')
                    % assume that they have specified which ones they want
                    parenEnd = find(tokens{tokenIndex}(whereStart + numel(whichField) + 2:end) == '}', 1, 'first');
                    whereCommas = [0 find(tokens{tokenIndex}(whereStart + numel(whichField) + 2):parenEnd - 1 == ',') parenEnd - 1];
                    defMiddle = [defMiddle '('];
                    
                    for dimIndex = 2:numel(whereCommas)
                        whatNums = str2num(tokens{tokenIndex}(whereStart + numel(whichField) + whereCommas(dimIndex - 1):whereCommas(dimIndex)));
                        if isnan(whatNums)
                            % whatever it was it will be treated as a ':'
                            defStart = [defStart 'for ' char(varIndex) ' = 1:size(parseData(whichCell(cellIndex)).episodes{whichEpi{cellIndex}(epiIndex)}.' whichField ', ' sprintf('%0.0f', dimIndex - 1) ')' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        else
                            defStart = [defStart 'for ' char(varIndex) ' = [' num2str(whatNums) ']' char(13)];
                            defMiddle = [defMiddle varIndex ', '];
                            defEnd = [defEnd 'end' char(13)];
                        end
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) ')'];
                else
                    % assume that they want them all
                    defMiddle = [defMiddle '('];
                    
                    for dimIndex = 1:ndims(parseData(firstWithEpisodes).episodes{1}.(whichField))
                        defStart = [defStart 'for ' char(varIndex) ' = 1:size(parseData(whichCell(cellIndex)).episodes{whichEpi{cellIndex}(epiIndex)}.' whichField ', ' sprintf('%0.0f', dimIndex) ')' char(13)];
                        defMiddle = [defMiddle varIndex ', '];
                        defEnd = [defEnd 'end' char(13)];
                        varIndex = varIndex + 1;
                    end
                    defMiddle = [defMiddle(1:end - 2) ')'];
                end      
        end
        
        % add in the text to the command
        varDefs = [varDefs defStart 'keep = keep || ' regexprep(tokens{tokenIndex}(2:end - 1), whichField, defMiddle) ';' char(13) defEnd];        
    end
    
    cellIndex = 1;
    while cellIndex <= numel(whichCell)
        epiIndex = 1;
        while epiIndex <= numel(whichEpi{cellIndex})
            eval(varDefs);
            if ~keep
                whichEpi{cellIndex}(epiIndex) = [];
            else
                epiIndex = epiIndex + 1;
            end
        end
        if isempty(whichEpi{cellIndex})
            whichCell(cellIndex) = [];
            whichEpi(cellIndex) = [];
        else
            cellIndex = cellIndex + 1;
        end
    end      
end

% if requested then find the episodes
if nargout > 1
    whichEpiText = {};
    for cellIndex = 1:numel(whichCell)
        for epiIndex = whichEpi{cellIndex}
            whichEpiText{end + 1, 1} = [parseData(whichCell(cellIndex)).key(1:find(parseData(whichCell(cellIndex)).key == filesep, 1, 'last')) parseData(whichCell(cellIndex)).episodes{epiIndex}.fileName];
        end
    end    
end
whichCell = {parseData(whichCell).key}';