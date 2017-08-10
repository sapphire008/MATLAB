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
    timePerPoint = 0.2;
end

if nargin < 5
    showAllTraces = false;
end

window = window / timePerPoint;

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
    for i = 1:numel(protocol.ampType)
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
            
            % preallocate space
            outData = zeros(numel(lastVals{4}), 10 * numel(events), diff(window) * 1000 / protocol.timePerPoint + 1);
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
                    tempData = eventTriggeredAverage(tempEvents, zData.traceData(:, lastVals{4})', window, zData.protocol.timePerPoint ./ 1000, true);            

                    % add the responses to our collection
                    outData(:, dataIndex + (1:size(tempData, 2)), :) = tempData;            
                    dataIndex = dataIndex + size(tempData, 2);
                end
            end

            if ~showAllTraces
                outData = sum(outData, 2)./sum(~isnan(outData), 2);
            else
                % do an event-triggered covariance analysis
                for i = 1:size(outData, 1)
                    tempData = princomp(squeeze(outData(i,:,:)));                    
                    sendData{i} = tempData(:,1:4);
                end
                newScope(sendData, (window(1):protocol.timePerPoint / 1000:window(2))');
                set(gcf, 'name', ['Event-triggered covariance of ' sprintf('%1.0f', dataIndex) ' events']);                
                return
            end

            if nargout == 0
                for i = 1:size(outData, 1)
                    sendData{i} = squeeze(outData(i, :, :))';
                end
                newScope(sendData, (window(1):protocol.timePerPoint / 1000:window(2))');
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

events = events(events > -window(1) & events < size(postTrace, 2) - window(2));

outData = zeros(size(postTrace, 1), numel(events), diff(window) + 1);
xData = window(1):window(2);

for i = 1:numel(events)
    for j = 1:size(postTrace, 1)
        outData(j, i, :) = postTrace(j, int32(events(i) + xData));
    end
end

if ~showAllTraces
    outData = sum(outData, 2)./sum(~isnan(outData), 2);
end

if nargout == 0
    for i = 1:size(outData, 1)
        sendData{i} = squeeze(outData(i,:,:))';
    end
    newScope(sendData, xData'*timePerPoint);
    set(gcf, 'name', 'Event-Triggered Average');
end