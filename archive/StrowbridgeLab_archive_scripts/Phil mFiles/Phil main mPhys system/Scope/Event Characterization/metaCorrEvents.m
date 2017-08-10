function enrichmentData = metaCorrEvents(varargin)
persistent correlationBounds
persistent binWidth
    
if nargin == 0
    enrichmentData = 'Metacorrelate';
    return
end

    if isempty(correlationBounds)
		correlationBounds = [-50 50];
    end
	if isempty(binWidth)
		binWidth = 5;
	end    
    handleList = get(gcf, 'userData');
	
	tempData = inputdlg({'Crosscorrelation start (ms)', 'Stop', 'Bin Width (ms)'},'Cross Corr...',1, {num2str(correlationBounds(1)), num2str(correlationBounds(2)), num2str(binWidth)});      
	if numel(tempData) == 0
        return
	end
	correlationBounds = [str2double(tempData(1)) str2double(tempData(2))];
    binWidth = str2double(tempData(3));
    binLocs = correlationBounds(1):binWidth:correlationBounds(2);
    count = zeros(size(binLocs));
    scCount = count;
    
    fromIndex = 1:handleList.axesCount;
    toIndex = fromIndex;

    numEvents = 0;
    numCount = 0;
    numScCount = 0;
    for toAxis = toIndex
        for fromAxis = fromIndex
            if fromAxis ~= toAxis
                fromEvents = getappdata(handleList.axes(fromAxis), 'events');
                toEvents = getappdata(handleList.axes(toAxis), 'events');   
                for i = 1:numel(toEvents)
                    fromEventsSame = find(strcmp(toEvents(i).traceName, {fromEvents.traceName}));    
                    for j = 1:numel(fromEvents)
                        dataStruct = zeros(2, max([length(fromEvents(j).data) length(toEvents(i).data)]));
                        dataStruct(1, 1:length(fromEvents(j).data)) = fromEvents(j).data;
                        dataStruct(2, 1:length(toEvents(i).data)) = toEvents(i).data;
                        spikeTimes = crossCorr(dataStruct', correlationBounds + [-1 1] * (binWidth / 2));
                        if any(fromEventsSame == j)
                            count = count + hist(spikeTimes, binLocs);        
                            numCount = numCount + 1;
                        else
                            scCount = scCount + hist(spikeTimes, binLocs);
                            numScCount = numScCount + 1;
                        end                     
                    end
                    if fromAxis == 1 || (fromAxis == 2 && toAxis == 1)
                        numEvents = numEvents + numel(toEvents(i).data);
                    end                       
                end
            end
        end
    end

    % calculate significance
    count = count / 2; % since we have A->B and B->A
    scCount = scCount * numCount / numScCount / 2; %sum(count) / sum(scCount);
    sigValues = nan(size(count));
    if license('test','Statistics_Toolbox')
        for j = 1:numel(count)
            sigValues(j) = poisscdf(count(j), scCount(j));
        end
    end
    
    % plot histogram
    set(datacursormode(figure('numbertitle', 'off', 'units', 'norm', 'position', [0.5 0 0.5 .9])),'UpdateFcn',@cursorUpdate);
    h(1) = subplot(4,1,3:4);
    enrichmentData = (count - scCount) ./ scCount .* 100;
    enrichment = bar(binLocs, enrichmentData, 'k');
    ylabel('Percent Enrichment');
%     enrichment = bar(binLocs, (count - scCount) ./ 19, 'k');
%     ylabel('Extra events per s');
    xlabel('Time (msec)');
    zoom xon
    datacursormode on
    text(min(get(gca, 'xlim')),min(get(gca, 'ylim'))-.1 * diff(get(gca, 'ylim')),{fromEvents.traceName}, 'verticalAlignment', 'top');

    % display significance
    sigThresh = 0.05;
    maxSig = line(binLocs(sigValues > 1 - (2 * sigThresh / numel(count))), (0.95 * max(get(gca, 'ylim')) + 0.05 * min(get(gca, 'ylim'))) * ones(sum(sigValues > 1 - (2 * sigThresh / numel(count))), 1), 'lineStyle', 'none', 'marker', '*', 'markerEdgeColor', [1 0 0]);
    minSig = line(binLocs(sigValues < (2 * sigThresh / numel(count))), (0.95 * max(get(gca, 'ylim')) + 0.05 * min(get(gca, 'ylim'))) * ones(sum(sigValues < (2 * sigThresh / numel(count))), 1), 'lineStyle', 'none', 'marker', '*', 'markerEdgeColor', [0 0 1]);        
    
    h(2) = subplot(4,1,2);
    bar(binLocs, scCount, 'k');
    ylabel('Background');
    
    h(3) = subplot(4,1,1);
    bar(binLocs, count, 'k');
    ylabel('Uncorrected');
%     title([sprintf('%1.3f', 100 * (count(fix(length(count) / 2) + 1) - scCount(fix(length(count)/2) + 1)) / numEvents) ' % of events correlated'])
    title([sprintf('%1.3f', 50 * count(fix(length(count) / 2) + 1) / numEvents) '% driven, ' sprintf('%1.3f', 50 * scCount(fix(length(count)/2) + 1) / numEvents) '% spont events correlated'])    
    linkaxes(h, 'x');
    
    function outText = cursorUpdate(varargin)
        pos = get(varargin{2}, 'Position');
        switch get(varargin{2}, 'Target')
            case maxSig
                outText = ['p = ' num2str(1 - sigValues(binLocs == pos(1))) ', ' num2str((1 - sigValues(binLocs == pos(1))) * numel(count)/2) ' corrected'];
            case minSig
                outText = ['p = ' num2str(sigValues(binLocs == pos(1))) ', ' num2str(sigValues(binLocs == pos(1)) * numel(count)/2) ' corrected'];
            case enrichment
                outText = {[num2str(pos(1)) ' ms'], [sprintf('%1.2f', pos(2)) '% enrichment']};
            otherwise
                outText = {[num2str(pos(1)) ' ms'], [num2str(pos(2)) ' counts']};
        end
    end
end