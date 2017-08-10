function updateAverage
% updates what frames are available for a given set of averaging specs

handleList = get(getappdata(0, 'imageBrowser'), 'userData');
info = getappdata(getappdata(0, 'imageBrowser'), 'info');

% update the number of frames that can be averaged
lastAverageNumber = get(handleList.cboAverageNumber, 'string');
try
    lastAverageNumber = str2double(lastAverageNumber(get(handleList.cboAverageNumber, 'value')));
catch
    % wasn't being rendered due to an error
    lastAverageNumber = numel(lastAverageNumber);
end

averageIndex = 0;
switch get(handleList.cboAverageLocation, 'value')
    case {1 3} % start, finish
        for i = 1:info.NumImages
            averageData{i,1} = sprintf('%1.0f', i);
            if averageIndex == 0 && i >= lastAverageNumber
                averageIndex = i;
                lastAverageNumber = i;
            end
        end
        % we couldn't get where we wanted, so get as close as possible
        if averageIndex == 0
            averageIndex = numel(averageData);
            lastAverageNumber = info.NumImages;
        end        
    case 2 % center
        for i = 1:2:info.NumImages
            averageData{(i + 1) / 2,1} = sprintf('%1.0f', i);
            if averageIndex == 0 && i >= lastAverageNumber
                averageIndex = (i + 1) / 2;
                lastAverageNumber = i;
            end
        end
        % we couldn't get where we wanted, so get as close as possible
        if averageIndex == 0
            averageIndex = numel(averageData) + 1;
            lastAverageNumber = (info.NumImages - 1) / 2;
        end          
end

set(handleList.cboAverageNumber, 'string', averageData, 'value', averageIndex);

% update the frame that can be viewed
lastFrameNumber = get(handleList.cboFrame, 'string');
lastFrameNumber = str2double(lastFrameNumber(get(handleList.cboFrame, 'value')));

clear averageData;
averageIndex = 0;
switch get(handleList.cboAverageLocation, 'value')
    case 1 % start
        for i = 1:info.NumImages - lastAverageNumber + 1
            averageData{i,1} = sprintf('%1.0f', i);
            if averageIndex == 0 && i >= lastFrameNumber
                averageIndex = i;
            end
        end          
    case 2 % center
        for i = (lastAverageNumber + 1) / 2:info.NumImages - (lastAverageNumber - 1) / 2
            averageData{i - (lastAverageNumber - 1) / 2,1} = sprintf('%1.0f', i);
            if averageIndex == 0 && i >= lastFrameNumber
                averageIndex = i - lastAverageNumber + 1;
            end
        end
    case 3 % finish
        for i = lastAverageNumber:info.NumImages
            averageData{i - lastAverageNumber + 1,1} = sprintf('%1.0f', i);
            if averageIndex == 0 && i >= lastFrameNumber
                averageIndex = i - lastAverageNumber + 1;
            end
        end      
end

% we couldn't get where we wanted, so set as first possible
if averageIndex == 0
    averageIndex = 1;
end

set(handleList.cboFrame, 'string', averageData, 'value', averageIndex);