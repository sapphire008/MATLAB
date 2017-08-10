function sendText(commaList)
if isempty(commaList)
    return
end
commas = [0 find(commaList == ',') length(commaList) + 1];
fileNames = {};
for i = 1:numel(commas) - 1
    fileNames{end + 1} = strtrim(commaList(commas(i) + 1:commas(i + 1) - 1));
end
if strcmp(fileNames{1}(end - 1:end), 'at')
% add files
    if ~isappdata(0, 'scopes')
        h = newScope(1:10);
        setappdata(0, 'scopes', h.figure);
    end
        % call a refresh for all current figures     
        whichScopes = getappdata(0, 'scopes');        
        whichScopes = whichScopes(ishandle(whichScopes));  

        % executing the next five commands clears up half of the
        % memory used by scopes
%                 evalin('base', 'clear zData');
%                 set(whichScopes, 'windowButtonDownFcn', [], 'windowButtonMotionFcn', [], 'windowButtonUpFcn', [], 'keyPressFcn', []);
%                 for i = whichScopes
%                     setappdata(i, 'updateFunction', []);
%                 end                
        % executing the next three commands clears up all of the
        % memory used by scopes but may take awhile              
%                 for i = whichScopes
%                     newScope([0 1], i);
%                 end       

        if numel(fileNames) > 1
            protocol = readTrace(fileNames{1});
            protocol = protocol.protocol;
            numChannels = numel(protocol.channelNames);
            for channelIndex = 1:numChannels
                zData.traceData{channelIndex} = zeros(protocol.sweepWindow * 1000 / protocol.timePerPoint, numel(fileNames));
            end
            for epiIndex = 1:numel(fileNames)
                tempData = readTrace(fileNames{epiIndex});
                zData.protocol(epiIndex) = tempData.protocol;
                if tempData.protocol.timePerPoint ~= protocol.timePerPoint
                    tempData.traceData = resample(tempData.traceData, tempData.protocol.timePerPoint, protocol.timePerPoint);
                end
                if numChannels > size(tempData.traceData, 2)
                    for i = size(tempData.traceData, 2) + 1:numChannels
                        zData.traceData(i) = [];
                    end
                    numChannels = size(tempData.traceData, 2);                    
                end
                if size(zData.traceData{1}, 1) == size(tempData.traceData, 1)
                    for channelIndex = 1:numChannels
                        zData.traceData{channelIndex}(:, epiIndex) = tempData.traceData(:, channelIndex);
                    end
                    zData.protocol(epiIndex).timePerPoint = protocol.timePerPoint;
                elseif size(zData.traceData{1}, 1) > size(tempData.traceData, 1)
                    % pad tempData
                    for channelIndex = 1:numChannels
                        zData.traceData{channelIndex}(:, epiIndex) = [tempData.traceData(:, channelIndex); nan(size(zData.traceData{channelIndex}, 1) - size(tempData.traceData, 1), 1)];
                    end
                    zData.protocol(epiIndex).sweepWindow = protocol.sweepWindow;
                else
                    % pad traceData
                    for channelIndex = 1:numChannels
                        zData.traceData{channelIndex} = [[zData.traceData{channelIndex}(:, 1:epiIndex - 1); nan(size(tempData.traceData, 1) - size(zData.traceData{channelIndex}, 1), epiIndex - 1)] tempData.traceData(:, channelIndex)];
                    end
                    for j = 1:(epiIndex - 1)
                        zData.protocol(j).sweepWindow = tempData.protocol.sweepWindow;
                    end
                end
            end

            % concatenate the episodes into the standard list format
            episodeName = zData.protocol(1).fileName;
            nameEnd = find(episodeName == 'S', 1, 'last') - 2;
            episodeName = episodeName(1:nameEnd + 1);

            % put the data into matrices
            seqData = zeros(epiIndex, 1);
            epiData = seqData;
            for i = 1:epiIndex
                seqEnd = find(zData.protocol(i).fileName == 'E', 1, 'last') - 2;
                epiEnd = find(zData.protocol(i).fileName == '.', 1, 'last') - 1;
                seqData(i) = str2double(zData.protocol(i).fileName(nameEnd + 3:seqEnd));
                epiData(i) = str2double(zData.protocol(i).fileName(seqEnd + 3:epiEnd));
            end

            % sort the data sets
            whichSeqs = unique(seqData);
            for i = 1:length(whichSeqs)
                whichEpis = sort(epiData(seqData == whichSeqs(i)));
                % concatenate consecutive runs
                episodeName = strcat(episodeName, 'S', num2str(whichSeqs(i)), '.E', sprintf('%0.0d',whichEpis(1)));
                lastEpi = whichEpis(1);
                inRun = 0;
                for j = 2:length(whichEpis)
                    if whichEpis(j) - lastEpi == 1
                        inRun = 1;
                    else
                        if inRun
                            episodeName = strcat(episodeName, '-', sprintf('%0.0d',lastEpi));
                            inRun = 0;
                        end
                        episodeName = strcat(episodeName, ',', sprintf('%0.0d',whichEpis(j)));
                    end
                    lastEpi = whichEpis(j);
                end
                if inRun
                    episodeName = strcat(episodeName, '-', sprintf('%0.0d',lastEpi));
                end
                episodeName = [episodeName '; '];
            end
            episodeName = episodeName(1:end - 2);                    
        else
            tempData = readTrace(fileNames{1});
            for i = 1:size(tempData.traceData, 2)
                zData.traceData{i} = tempData.traceData(:,i);
            end
            zData.protocol = tempData.protocol;
            episodeName = fileNames{1};
%             listHandle.scrollRectToVisible(listHandle.getCellRect(whichSelected, 0, 1));
        end

        set(whichScopes, 'name', episodeName);

        assignin('base', 'zData', zData);

        % delete old events
        for i = whichScopes
            for j = findobj(i, 'type', 'axes')'
                if isappdata(j, 'events')
                    rmappdata(j, 'events');
                    kids = get(j, 'children');
                    delete(kids(strcmp(get(kids, 'userData'), 'events')));
                end
            end
        end

        % call a refresh for all current figures (and any new ones
        % being created)
        for i = getappdata(0, 'scopes')'
            newScope(zData.traceData, zData.protocol, i);
            set(i, 'name', episodeName);
        end
    end % isappdata(0, 'scopes')

% add protocol data if necessary
    if isappdata(0, 'protocolViewer')
        set(0, 'currentFigure', getappdata(0, 'fileBrowser'));
        loadProtocol(listHandle.getModel.getValueAt(listHandle.getSelectedRow, 0));
    end