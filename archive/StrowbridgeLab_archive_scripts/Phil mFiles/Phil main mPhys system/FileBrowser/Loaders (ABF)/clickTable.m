function clickTable(fileNames)
if isempty(fileNames)
    return
end

% add files
    if isappdata(0, 'scopes')
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
    handles = get(getappdata(0, 'fileBrowser'), 'userData');
        if strcmp(get(handles{4}, 'name'), 'Episodic')
            whichTrace = [];
            for i = 1:numel(fileNames)
                whichTrace(end + 1) = str2double(fileNames{i}(find(fileNames{i} == 'E', 1, 'last') + 1:end));
            end
            tempData = readABF(fileNames{1}(1:find(fileNames{1} == 'E', 1, 'last') - 2), 'sweeps', whichTrace);
            for i = 1:size(tempData.traceData, 2)
                zData.traceData{i} = squeeze(tempData.traceData(:,i, :));
            end
            zData.protocol = tempData.protocol;
        else
            if numel(fileNames) > 1
                tempData = readABF(fileNames{1});
                numChannels = numel(tempData.protocol.channelNames);
                lastEpi = 0;
                for channelIndex = 1:numChannels
                    zData.traceData{channelIndex} = zeros(size(tempData.traceData, 1), numel(fileNames));
                end
                for epiIndex = 1:numel(fileNames)
                    tempData = readABF(fileNames{epiIndex});
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
                            zData.traceData{channelIndex}(:, lastEpi + (1:size(tempData.traceData, 3))) = squeeze(tempData.traceData(:, channelIndex, :));
                        end
                        zData.protocol(epiIndex).timePerPoint = zData.protocol(1).timePerPoint;                        
                    elseif size(zData.traceData{1}, 1) > size(tempData.traceData, 1)
                        % pad tempData
                        for channelIndex = 1:numChannels
                            zData.traceData{channelIndex}(:, lastEpi + (1:size(tempData.traceData, 3))) = [squeeze(tempData.traceData(:, channelIndex, :)); nan(size(zData.traceData{channelIndex}, 1) - size(tempData.traceData, 1), size(tempData.traceData, 3))];
                        end
                        zData.protocol(epiIndex).sweepWindow = zData.protocol(1).sweepWindow;                        
                    else
                        % pad traceData
                        for channelIndex = 1:numChannels
                            zData.traceData{channelIndex} = [[zData.traceData{channelIndex}(:, 1:lastEpi); nan(size(tempData.traceData, 1) - size(zData.traceData{channelIndex}, 1), lastEpi)] squeeze(tempData.traceData(:, channelIndex, :))];
                        end
                        for j = 1:(epiIndex - 1)
                            zData.protocol(j).sweepWindow = tempData.protocol.sweepWindow;
                        end                        
                    end
                    lastEpi = lastEpi + size(tempData, 3);
                end             
            else
                tempData = readABF(fileNames{1});
                for i = 1:size(tempData.traceData, 2)
                    zData.traceData{i} = squeeze(tempData.traceData(:,i, :));
                end
                zData.protocol = tempData.protocol;                
            end
        end

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
            set(i, 'name', fileNames{1});
        end
    end % isappdata(0, 'scopes')