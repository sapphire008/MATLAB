function outText = crosscorrelateSetup(varargin)
if ~nargin
    outText = 'Crosscorrelate with';
else
    handleList = get(gcf, 'userData');
    stringData = get(handleList.channelControl(1).channel, 'string');
    ourVals = {stringData{cell2mat((get([handleList.channelControl.channel], 'value'))')}};
	kids = get(varargin{1}, 'children');
	if numel(kids) > numel(ourVals)
		delete(kids(end - numel(ourVals) + numel(kids):end));
	end
	for i = 1:numel(kids)
		set(kids(i), 'label', ourVals{i});
	end
    for i = numel(kids) + 1:numel(ourVals)
		uimenu(varargin{1}, 'Label', ourVals{i}, 'callback', {@crosscorrelateEvents, varargin{3}, varargin{4}, varargin{5}});
    end
end

function crosscorrelateEvents(varargin)
	persistent correlationBounds
    persistent coincidenceBounds
    if isempty(correlationBounds)
		correlationBounds = [-100 100];
    end
	if isempty(coincidenceBounds)
		coincidenceBounds = [-3 3];
	end    
    handleList = get(gcf, 'userData');
        
    % from events 
    fromAxis = gca;
    fromEvents = getappdata(fromAxis, 'events');
    fromName = get(handleList.channelControl(handleList.axes == fromAxis).channel, 'string');
    fromName = fromName{get(handleList.channelControl(handleList.axes == fromAxis).channel, 'value')};
    
    % to events
    whichKid = get(varargin{1}, 'Label');
    stringData = get(handleList.channelControl(1).channel, 'string');    
    ourVals = {stringData{cell2mat((get([handleList.channelControl.channel], 'value'))')}};    
    for i = 1:numel(ourVals)
        if strcmp(whichKid, ourVals{i})
            whichTrace = i;
            break
        end
    end
    
    toEvents = getappdata(handleList.axes(whichTrace), 'events');   
    toEventsSame = strcmp(fromEvents(varargin{5}).traceName, {toEvents.traceName});
    toEventsDiff = find(~toEventsSame);
    toEventsSame = find(toEventsSame);
	
	tempData = inputdlg({'Crosscorrelation start (ms)', 'Stop', 'Coincidence start (ms)', 'Stop'},'Cross Corr...',1, {num2str(correlationBounds(1)), num2str(correlationBounds(2)), num2str(coincidenceBounds(1)), num2str(coincidenceBounds(2))});      
	if numel(tempData) == 0
        return
	end
	correlationBounds = [str2double(tempData(1)) str2double(tempData(2))];
    coincidenceBounds = [str2double(tempData(3)) str2double(tempData(4))];
    
    if numel(toEvents) - numel(toEventsSame) > 0
        choiceNames{1} = 'None';
        for i = 1:numel(toEventsDiff)
            choiceNames{i + 1} = [toEvents(toEventsDiff(i)).type ', ' toEvents(toEventsDiff(i)).traceName];
        end
        [shiftCorr okTrue] = listdlg('PromptString','Select events for shift correction:',...
                    'SelectionMode','single',...
                    'ListSize', [600 80],...
                    'ListString',choiceNames);
        if ~okTrue
            shiftCorr = 1;
        end     
    else
        shiftCorr = 1;
    end
    
    for i = toEventsSame
        dataStruct = zeros(2, max([length(fromEvents(varargin{5}).data) length(toEvents(i).data)]));
        dataStruct(1, 1:length(fromEvents(varargin{5}).data)) = fromEvents(varargin{5}).data;
        dataStruct(2, 1:length(toEvents(i).data)) = toEvents(i).data;
        [spikeTimes title sameEvents] = crossCorr(dataStruct', correlationBounds, coincidenceBounds);
        if ~isempty(sameEvents)
            toEvents(end + 1).data = sameEvents;
            toEvents(end).traceName = toEvents(i).traceName;
            toEvents(end).type = ['Coincident events with ' fromEvents(varargin{5}).type ' of ' fromName];
            fromEvents(end + 1).data = sameEvents;
            fromEvents(end).traceName = toEvents(i).traceName;
            fromEvents(end).type = ['Coincident events with ' toEvents(i).type ' of ' whichKid];
        end
        [count whereBins] = hist(spikeTimes, max([2 min([round(length(spikeTimes) / 5) 300])]));
        sigValues = nan(size(count));
        
        if shiftCorr > 1
            dataStruct = zeros(2, max([length(fromEvents(varargin{5}).data) length(toEvents(toEventsDiff(shiftCorr - 1)).data)]));
            dataStruct(1, 1:length(fromEvents(varargin{5}).data)) = fromEvents(varargin{5}).data;
            dataStruct(2, 1:length(toEvents(toEventsDiff(shiftCorr - 1)).data)) = toEvents(toEventsDiff(shiftCorr - 1)).data;
            scSpikes = crossCorr(dataStruct', correlationBounds, coincidenceBounds);            
            [scCount whereBins] = hist(scSpikes, whereBins);
            scCount = scCount * numel(spikeTimes) / numel(scSpikes); % normalized by total spikes
            
            if license('test','Statistics_Toolbox')
                % calculate significance if we have the toolbox
                for j = 1:numel(count)
                    sigValues(j) = poisscdf(count(j), scCount(j));
                end
            end
            
            count = count - scCount;
        end

        % plot histogram
        figure('numbertitle', 'off', 'Name', title);
        bar(whereBins, count, 'k');
%         smoothData = hist(spikeTimes, diff(correlationBounds) + 1);
%         smoothData = movingAverage(smoothData, (diff(correlationBounds) + 1) / 10);
%         line(correlationBounds(1):correlationBounds(2), smoothData / sum(smoothData) * length(spikeTimes), 'color', [1 0 0]);
        xlabel('Time (msec)');
        ylabel('Number of spikes');
        
        % display significance
        sigLevel = 0.01 / numel(count);
        line(whereBins(sigValues > 1 - sigLevel), (0.95 * max(get(gca, 'ylim')) + 0.05 * min(get(gca, 'ylim'))) * ones(sum(sigValues > 1 - sigLevel), 1), 'lineStyle', 'none', 'marker', '*', 'markerEdgeColor', [1 0 0]);
        line(whereBins(sigValues < sigLevel), (0.95 * max(get(gca, 'ylim')) + 0.05 * min(get(gca, 'ylim'))) * ones(sum(sigValues < sigLevel), 1), 'lineStyle', 'none', 'marker', '*', 'markerEdgeColor', [0 0 1]);        
    end
    setappdata(fromAxis, 'events', fromEvents);
    setappdata(handleList.axes(whichTrace), 'events', toEvents);
    showEvents(fromAxis);
    showEvents(handleList.axes(whichTrace));