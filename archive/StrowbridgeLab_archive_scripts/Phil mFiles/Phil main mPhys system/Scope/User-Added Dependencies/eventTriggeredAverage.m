function outData = eventTriggeredAverage(events, postTrace, window, timePerPoint, showAllTraces)
% calculate the event-triggered average in postTrace using preTrace's spikes
% outData = eventTriggeredAverage(events, postTraces, [startTime endTime], timePerPoint, showAllTraces);
% outData = eventTriggeredAverage(tracePaths, [preCell postCell1 postCell 2], [startTime endTime], timePerPoint, showAllTraces);
% defaults:
%   window = [-10 100] ms
%   timePerPoint = 0.2 ms
%   showAllTraces = false

persistent lastVals
persistent userAdded

if nargin < 3
    window = [-10 100];
end

if nargin < 4
    timePerPoint = repmat(0.2, length(postTrace), 1);
end

if nargin < 5
    showAllTraces = false;
end

if ischar(events)
    % outData = eventTriggeredAverage(tracePath, [preCell postCell],...)
    events = {events}; % make it a cell
end

if iscell(events)
    if isempty(lastVals)
        lastVals = {'-10', '100', '', [], {}};
        userAdded = [];
    end
    
    protocol = readTrace(events{1}, 1);

    % detect events
    lastVals{3} = lastVals{3}(userAdded);
    for i = find(cellfun(@(x) x~=0, protocol.ampEnable))'
        switch protocol.channelNames{whichChannel(protocol, i)}(end)
            case 'V'
                % whole cell action potentials
                lastVals{3}{end + 1} = ['detectSpikes(zData.traceData(:, whichChannel(zData.protocol, ' sprintf('%0.0f', i) ', ''V'')));'];
            case 'I'
                % cell-attached spikes
                lastVals{3}{end + 1} = ['MTEO(zData.traceData(:, whichChannel(zData.protocol, ' sprintf('%0.0f', i) ', ''I'')), 14, -10);'];
        end
    end
    for i = 1:numel(protocol.channelNames)
        if numel(protocol.channelNames{i}) > 4 && strcmp(protocol.channelNames{i}(1:5), 'Field')
            % extracellular MUA
            lastVals{3}{end + 1} = ['MTEO(zData.traceData(:, ' sprintf('%0.0f', i) '), 14, -1);'];
        end
    end
    lastVals{3}{end + 1} = 'Other...';
    
    [whereBounds tempVals] = inputdlg({'Window Start (ms)', 'Window End (ms)', 'Events'},'',1, lastVals(1:3));    
    if ~isempty(whereBounds)
        lastVals(1:3) = tempVals;

        % find which channels match from before
        newVals = [];
        for i = lastVals{4}
            whichNew = find(strcmp(lastVals{5}{i}, protocol.channelNames));
            if ~isempty(whichNew)
                newVals(end + 1) = whichNew;
            end
        end
        tempPost = listdlg('ListString', protocol.channelNames, 'SelectionMode', 'multiple', 'InitialValue', newVals, 'ListSize', [160 160], 'Name', 'Post Traces');

        if ~isempty(tempPost)
            lastVals{4} = tempPost;
            lastVals{5} = protocol.channelNames;
            window = [str2double(lastVals{1}) str2double(lastVals{2})];
            for channelIndex = lastVals{4}
                outData{channelIndex} = zeros(diff(window) * 1000 / protocol.timePerPoint + 1, 0);
            end
            dataIndex = 0;

            for traceIndex = 1:numel(events)
                zData = readTrace(events{traceIndex});

                try
                    tempEvents = eval(whereBounds{3});
                catch
                    warning(['Error evaluating event command, "' lastVals{3} '" on: ' events{traceIndex}]);
                end

                % send off for the post responses
                if numel(tempEvents)
                    for channelIndex = lastVals{4}
                        tempData = eventTriggeredAverage(tempEvents, {zData.traceData(:, channelIndex)}, window, zData.protocol.timePerPoint ./ 1000, true);            

                        % add the responses to our collection
                        outData{channelIndex}(:, end + (1:size(tempData{1}, 2))) = tempData{1};       
                    end
                    dataIndex = dataIndex + length(tempEvents);
                end
            end

            switch showAllTraces
                case 0
                    % do an event-triggered average
                    for j = 1:numel(outData)
                        outData{j} = sum(outData{j}, 2)./sum(~isnan(outData{j}), 2);
                    end
                case 1
                    % do an event-triggered overlay
                    
                case -1
                    % do an event-triggered covariance analysis
                    for i = 1:size(outData, 2)
                        tempData = princomp(outData{i}');                    
                        sendData{i} = tempData(:,1:4);
                    end
                    newScope(sendData, repmat([window(1) protocol.timePerPoint / 1000 window(2)], numel(outData), 1), lastVals{5}(lastVals{4}));
                    set(gcf, 'name', ['Event-triggered covariance of ' sprintf('%1.0f', dataIndex) ' events.  Four most important components.']);                
                    return
            end

            if nargout == 0
                newScope(outData, repmat([window(1) protocol.timePerPoint / 1000 window(2)], numel(outData), 1), lastVals{5}(lastVals{4}));
                set(gcf, 'name', ['Event-triggered response of ' sprintf('%1.0f', dataIndex) ' events']);
            end   
            
            return
        else
            return
        end 
    else
        return
    end
end    

for j = 1:size(postTrace, 2)
    tempEvents = events(events > -window(1)/timePerPoint(j) & events < size(postTrace{j}, 1) - window(2)/timePerPoint(j));
    outData{j} = zeros(diff(window)/timePerPoint(j) + 1, numel(events));    
    xData = (window(1)/timePerPoint(j)):(window(2)/timePerPoint(j));
    for i = 1:numel(tempEvents)
        outData{j}(:,i) = postTrace{j}(int32(tempEvents(i) + xData));
    end
    if ~showAllTraces
        outData{j} = sum(outData{j}, 2)./sum(~isnan(outData{j}), 2);
    end    
end

if nargout == 0
    newScope(outData, [repmat(window(1), numel(outData), 1) timePerPoint repmat(window(2), numel(outData), 1)]);
    set(gcf, 'name', 'Event-Triggered Average');
end