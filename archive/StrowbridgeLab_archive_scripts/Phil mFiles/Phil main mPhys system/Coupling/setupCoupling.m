function figHandle = setupCoupling(protocol, windowSize)

figHandle = [];
try
    [stims stimLength channels] = findSteps(protocol);
catch
    return
end

if isempty(stims)
    return
end

samplingRate = 1000 / protocol.timePerPoint; % samples per msec
stims = (stims * samplingRate);
yData = ones(1, 6 * windowSize + 1);

% create display window
figHandle = figure('menu', 'none', 'Name', ['Coupling: ' protocol.fileName(1:find(protocol.fileName == 'S', 1, 'last') - 2)], 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0 .02 1 .94], 'windowButtonMotionFcn', @zoomCoupling, 'busyAction', 'cancel');

f = uimenu(gcf, 'Label', 'Window');
    uimenu(f, 'Label', 'Active Zoom', 'callback', @zoomCheck, 'checked', 'off')
    uimenu(f, 'Label', 'Save As...', 'callback', @saveWindow);
    uimenu(f, 'Label', 'Print', 'callback', @printWindow);
f = uimenu(gcf, 'Label', 'Analysis');
    uimenu(f, 'Label', 'Stats Single Connection...','Callback', @stimStatsClick);  
    uimenu(f, 'Label', 'Significant Stats','Callback', 'generateStats;'); 
    uimenu(f, 'Label', 'View Traces...','Callback', @viewTracesClick); 
    uimenu(f, 'Label', 'Feature vs Potential...', 'Callback', 'featureVsPotential');
    uimenu(f, 'Label', 'Covariance Plots...', 'Callback', @showCovariances);
    uimenu(f, 'Label', 'Show Single Fit...', 'Callback', 'showFit');
    uimenu(f, 'Label', 'Output Traces...','Callback', @outputTracesClick); 
    uimenu(f, 'Label', 'Clean Up Figure','Callback', 'cleanUpCoupling;');   
    uimenu(f, 'Label', 'Episode List','Callback', 'generateEpisodes;'); 
    uimenu(f, 'Label', 'Generate Spreadsheet...', 'callback', @generateSpreadsheet);
    uimenu(f, 'Label', 'View Control Traces...', 'callback', @controlViewTracesClick, 'separator', 'on');
    uimenu(f, 'Label', 'Output Control Traces...', 'callback', @controlOutputTracesClick);    
    uimenu(f, 'Label', 'Control Characterization...', 'callback', @controlCharacterizeClick);
    
for index = 1:length(stims) * length(channels)
    xData(:, index) = stims(mod(index - 1, size(stims, 1)) + 1):stims(mod(index - 1, size(stims, 1)) + 1) + 6 * windowSize;
    axes('buttondownfcn', 'averageCoupling', 'Position', [.02 + mod(index + size(stims, 1) - 1, size(stims, 1)) / (size(stims, 1) / .98) .02 + (size(channels, 2) - 1 - fix((index - 1) / size(stims, 1))) / (size(channels, 2) / .98)  .98 / size(stims, 1) .98 / size(channels, 2)]);
    if index < size(stims, 1) * (size(channels, 2) - 1)
        set(gca, 'xticklabel', '')
    end
    if ~((index + size(stims, 1) - 1) / size(stims, 1) == fix((index + size(channels, 2) * 2 - 1) / size(stims, 1)))
        set(gca, 'yticklabel', '')
    end
    line(xData(:, index) / samplingRate, yData, 'Color', [0 0 0]); % black for pretty
    uicontrol(...
        'Units','normalized',...
        'Position',[.02 + mod(index + size(channels, 2) * 2 - 1, size(stims, 1)) / (size(stims, 1) / .98) .02 + (size(channels, 2) - 1 - fix((index - 1) / size(stims, 1))) / (size(channels, 2) / .98)  .056 .01],...
        'Style','text',...
        'HorizontalAlignment', 'right',...
        'String', '0.0',...
        'ForeGroundColor', [1 0 0]);
    uicontrol(...
        'Units','normalized',...
        'Position',[.08 + mod(index + size(channels, 2) * 2 - 1, size(stims, 1)) / (size(stims, 1) / .98) .02 + (size(channels, 2) - 1 - fix((index - 1) / size(stims, 1))) / (size(channels, 2) / .98)  .056 .01],...
        'Style','text',...
        'HorizontalAlignment', 'right',...
        'String', '0.0',...
        'ForeGroundColor', [0 0 1]);
end

% set userData of figure to include all of our info
set(gcf, 'userData', {channels, zeros(size(stims, 1) + size(channels, 2), 1), stims, zeros(size(channels, 2), size(stims, 1) + 1, 9, 1), stimLength * samplingRate, 100});
setappdata(gcf, 'zoomLocation', 0);

function zoomCheck(varargin)
    if strcmp(get(gcbo, 'Checked'),'on')
        set(gcf, 'currentPoint', [0 0]);
        zoomCoupling(gcf);
        set(gcbo, 'Checked', 'off');        
    else 
        set(gcbo, 'Checked', 'on');
    end

function stimStatsClick(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'1', '2'};
    end
    
    tempBounds = inputdlg({'Presynaptic Cell', 'Postsynaptic Cell'},'Stats',1, lastBounds);
    PSPdata = get(gcf, 'userData');
    
    whereBounds = str2double(tempBounds);
    if ~isempty(whereBounds) &&...
            whereBounds(1) <= size(PSPdata{4}, 1) &&...
            whereBounds(1) > 0 &&...
            whereBounds(2) <= (size(PSPdata{4}, 2) - 1)/2 &&...
            whereBounds(2) > 0
        stimStats(whereBounds(1), whereBounds(2));
        lastBounds = tempBounds;
    else
        msgbox('Improper input values')
    end
    
function viewTracesClick(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'1', '2', '1', '-2', '30', '1'};
    end
	tempBounds = inputdlg({'Stim Number', 'Postsynaptic Cell', 'PSPs Down (0 or 1)', 'Start Time', 'End Time', 'Rezero(0 or 1)'},'Traces',1, lastBounds);
    PSPdata = get(gcf, 'userData');
    
    whereBounds = str2double(tempBounds);
    if ~isempty(whereBounds) &&...
            whereBounds(1) < size(PSPdata{4}, 2) &&...
            whereBounds(1) > 0 &&...
            whereBounds(2) <= size(PSPdata{4}, 1) &&...
            whereBounds(2) > 0 &&...
            (whereBounds(3) == 0 || whereBounds(3) == 1) &&...
            (whereBounds(6) == 0 || whereBounds(6) == 1)
        generateTraces(whereBounds(1), whereBounds(2), whereBounds(3), [whereBounds(4) whereBounds(5)], whereBounds(6));
        lastBounds = tempBounds;
    else
        msgbox('Improper input values')
    end
        
function outputTracesClick(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'1', '2', '1', '-2', '30', 'newData'};
    end
	tempBounds = inputdlg({'Stim Number', 'Postsynaptic Cell', 'PSPs Down (0 or 1)', 'Start Time', 'End Time', 'Matrix Name'},'Output',1, lastBounds);
    PSPdata = get(gcf, 'userData');
    
    if ~isempty(tempBounds)
        dataName = tempBounds(6);
        whereBounds = str2double(tempBounds(1:5));
        if whereBounds(1) < size(PSPdata{4}, 2) &&...
                whereBounds(1) > 0 &&...
                whereBounds(2) <= size(PSPdata{4}, 1) &&...
                whereBounds(2) > 0 &&...
                (whereBounds(3) == 0 || whereBounds(3) == 1)
            assignin('base', dataName{1}, generateTraces(whereBounds(1), whereBounds(2), whereBounds(3), [whereBounds(4) whereBounds(5)], 0));
            lastBounds = tempBounds;
        else
            msgbox('Improper input values')
        end
    end
    
function generateSpreadsheet(varargin)
    figName = get(gcf, 'name');
    [fileName pathName] = uiputfile({'*.xls','Excel Files (*.xls)';'*.*', 'All Files (*.*)'},'Select location for spreadsheet',figName(find(figName=='\', 1, 'last'):end));
    if ~isempty(fileName)
        PSPdata = get(gcf, 'userData');
        excelCoupling(PSPdata{4}, [pathName fileName]); 
    end
    
function controlViewTracesClick(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'1', '1', '-2', '30', '1'};
    end
	tempBounds = inputdlg({'Postsynaptic Cell', 'PSPs Down (0 or 1)', 'Start Time', 'End Time', 'Rezero(0 or 1)'},'Traces',1, lastBounds);
    PSPdata = get(gcf, 'userData');
    
    whereBounds = str2double(tempBounds);
    if ~isempty(whereBounds) &&...
            whereBounds(2) <= size(PSPdata{4}, 1) &&...
            whereBounds(1) > 0 &&...
            (whereBounds(2) == 0 || whereBounds(2) == 1) &&...
            (whereBounds(5) == 0 || whereBounds(5) == 1)
        generateTraces(size(PSPdata{4}, 2), whereBounds(1), whereBounds(2), [whereBounds(3) whereBounds(4)], whereBounds(5));
        lastBounds = tempBounds;
    else
        msgbox('Improper input values')
    end    
    
function controlOutputTracesClick(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'2', '1', '-2', '30', 'newData'};
    end
	tempBounds = inputdlg({'Postsynaptic Cell', 'PSPs Down (0 or 1)', 'Start Time', 'End Time', 'Matrix Name'},'Output',1, lastBounds);
    PSPdata = get(gcf, 'userData');
    
    dataName = tempBounds(5);
    whereBounds = str2double(tempBounds(1:4));
    if ~isempty(whereBounds) &&...
            whereBounds(1) <= size(PSPdata{4}, 1) &&...
            whereBounds(1) > 0 &&...
            (whereBounds(2) == 0 || whereBounds(2) == 1)
        assignin('base', dataName{1}, generateTraces(size(PSPdata{4}, 2), whereBounds(1), whereBounds(2), [whereBounds(3) whereBounds(4)], 0));
        lastBounds = tempBounds;
    else
        msgbox('Improper input values')
    end

function controlCharacterizeClick(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'2', '1'};
    end
    tempBounds = inputdlg({'Postsynaptic Cell', 'PSP Down (0 or 1)'},'Control',1, lastBounds);
    
    if isempty(tempBounds)
        return
    end
    lastBounds = tempBounds;
    whereBounds = str2double(tempBounds);

    % get all of the data we need
    tempData = get(gcf, 'userData');
    PSPdata = tempData{4};
    numProcessed = tempData{2}(size(PSPdata, 2) + whereBounds(1));

    % check to make sure we have enough data to act on
    if ~isempty(whereBounds) && whereBounds(1) > 0 && whereBounds(1) < size(PSPdata, 1) && (whereBounds(2) == 0 || whereBounds(2) == 1)
        if whereBounds(2) == 1
            PSPdata = squeeze(PSPdata(whereBounds(1), end, :, PSPdata(whereBounds(1), end, 3, :) < 0));
        else
            PSPdata = squeeze(PSPdata(whereBounds(1), end, :, PSPdata(whereBounds(1), end, 3, :) > 0));
        end
    else
        return
    end
    if ~isempty(PSPdata)
        cellName = get(gcf, 'name');
        % plot histograms of tau and amp above a frequency vs time plot
        figure('units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off');
        if whereBounds(2) == 1
            set(gcf, 'name', ['Control Down-PSPs in cell ' num2str(whereBounds(1)) ' of ' cellName(11:end)]);
        else
            set(gcf, 'name', ['Control Up-PSPs in cell ' num2str(whereBounds(1)) ' of ' cellName(11:end)]);
        end
        subplot(2,3,1)
        histfit(PSPdata(3,:));
        xlabel('Amplitude (pA/mV)') 
        set(gca, 'buttondownfcn', @ampVsTime);

        subplot(2,3,2)
        histfit(PSPdata(4,:))
        xlabel('Rise time (msec)')
        set(gca, 'buttondownfcn', @riseVsTime);

        subplot(2,3,3)
        histfit(PSPdata(6,:))
        xlabel('Decay time (msec)')   
        set(gca, 'buttondownfcn', @decayVsTime);

        subplot(2,3,4:6)
        if size(PSPdata, 2) > 5
            [sortedXData indexOrders] = sort(PSPdata(7,:));
            yData = 100 * [1 / diff(PSPdata(7, indexOrders(1:2))); (1 ./ diff(PSPdata(7, indexOrders)))'];
            plot(sortedXData, yData, 'linestyle', 'none', 'marker', '.');
            hold on
            % savitsky-golay filtering
            notNum = ~isinf(yData) & ~isnan(yData);
            plot(sortedXData(notNum), sgolayfilt(yData(notNum), 3, round(sum(notNum) / 5) * 2 + 1), 'color', [1 0 0])
            title(['Successes (%), mean = ' num2str(mean(size(PSPdata, 2) ./ numProcessed), '%4.2f') ' per trace'])
            xlabel('Time Since WC (sec)')
            set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
        else
            text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
        end
        set(gcf, 'userData', PSPdata');
    else
        disp('****** Insufficient events in window for figure generation')
    end


function dataVals = generateTraces(from, to, pspType, timeWindow, rezero)
    persistent newRoot
    persistent numChars
    
    PSPdata = get(gcf, 'userData');
    channels = PSPdata{1};    
    PSPdata = PSPdata{4};
    tempData = squeeze(PSPdata(to, from, :, :));
    if pspType == 0
        resultData = tempData(:, tempData(3,:) > 0)';
    else
        resultData = tempData(:, tempData(3,:) < 0)';
    end
    if isempty(resultData)
        disp('No responses to show');
        return
    end
    
    traceIndex = 1;
    cellName = get(gcf, 'name');
    % open the files and add their plots
    for i = 1:size(resultData, 1)
        if ~isempty(numChars)
            zData = readTrace([newRoot cellName(11 + numChars:end) '.S' num2str(resultData(i,1)) '.E' num2str(resultData(i,2)) '.dat']);
        else
            zData = readTrace([cellName(11:end) '.S' num2str(resultData(i,1)) '.E' num2str(resultData(i,2)) '.dat']);
        end
        if isempty(zData)
            options.Resize = 'on';
            outputArgs = inputdlg({'Please truncate to old metaroot', 'Please enter new root'}, 'File not found', 2, {cellName(11:end), 'Y:\Larimer\Data\2005\Multidata'}, options);
            numChars = numel(outputArgs{1});
            newRoot = outputArgs{2};
            zData = readTrace([newRoot cellName(11 + numChars:end) '.S' num2str(resultData(i,1)) '.E' num2str(resultData(i,2)) '.dat']);            
        end
        if i == 1
            timeWindow = timeWindow(1) / (zData.protocol.timePerPoint / 1000):timeWindow(2) / (zData.protocol.timePerPoint / 1000);
        end
        
        if ~isnan(resultData(i,9))
            if rezero
                dataVals(traceIndex,:) = zData.traceData(resultData(i,9) + timeWindow, channels(to)) - mean(zData.traceData(resultData(i, 9) - 10:resultData(i,9), channels(to)));
            else
                dataVals(traceIndex,:) = zData.traceData(resultData(i,9) + timeWindow, channels(to));
            end
        else
            if rezero
                dataVals(traceIndex,:) = zData.traceData(round(resultData(i,5)*1000/zData.protocol.timePerPoint) + timeWindow, channels(to)) - mean(zData.traceData(round(resultData(i,5)*1000/zData.protocol.timePerPoint) - 10:round(resultData(i,5)*1000/zData.protocol.timePerPoint), channels(to)));
            else
                dataVals(traceIndex,:) = zData.traceData(round(resultData(i,5)*1000/zData.protocol.timePerPoint) + timeWindow, channels(to));
            end        
        end
        traceIndex = traceIndex + 1;
    end

    if nargout == 0
        % plot the traces
        channelType = zData.protocol.ampTypeName{1}(end - 1);
        if channelType == 'V'
            newScope(dataVals', ((0:size(dataVals, 2) - 1) + timeWindow(1)) * zData.protocol.timePerPoint / 1000, 'Trace I');
        else
            newScope(dataVals', ((0:size(dataVals, 2) - 1) + timeWindow(1)) * zData.protocol.timePerPoint / 1000, 'Trace V');
        end
        if from == size(PSPdata, 2)
            set(gcf, 'name', [cellName ': control window of cell ' num2str(to)]);
        else
            set(gcf, 'name', [cellName ': stim ' num2str(from) ' onto cell ' num2str(to)]);
        end        
    end
    
function showCovariances(varargin)
    persistent lastBounds
    if isempty(lastBounds)
        lastBounds = {'1', '2', '1'};
    end
	whereBounds = round(str2double(inputdlg({'Stim Number', 'Postsynaptic Cell', 'PSPs Down (0 or 1)'},'Covariance',1, lastBounds)));
    if isnan(whereBounds)
        return
    end
    lastBounds = whereBounds;
    PSPdata = get(gcf, 'userData');
    if whereBounds(1) > size(PSPdata{4}, 2) || whereBounds(1) < 1 ||...
            whereBounds(2) > size(PSPdata{4}, 1) || whereBounds(2) < 1 ||...
            ~ismember(whereBounds(3), [0 1])
        error('Inappropriate input')
    end
    
    if whereBounds(3)
        covPlot(squeeze(PSPdata{4}(whereBounds(2),whereBounds(1),3:6,PSPdata{4}(whereBounds(2),whereBounds(1),3,:) < 0))', {'Amp', 'Rise', 'Latency', 'Decay'});
    else
        covPlot(squeeze(PSPdata{4}(whereBounds(2),whereBounds(1),3:6,PSPdata{4}(whereBounds(2),whereBounds(1),3,:) > 0))', {'Amp', 'Rise', 'Latency', 'Decay'});
    end        
    
function saveWindow(varargin)
    [FileName,PathName] = uiputfile({'*.fig','Figure Files (*.fig)'}, 'Save Figure As...', 'couplingWindow');
    
    if ~isempty(FileName)
        hgsave([PathName FileName]);
    end
    
function printWindow(varargin)  
    % prep the figure
    set(gcf, 'inverthardcopy', 'off', 'color', [1 1 1], 'paperorientation', 'landscape', 'paperposition', [.5 .5 10 7.5]);
    kids = get(gcf, 'children');
    kidAxes = kids(~cellfun('isempty', strfind(get(kids, 'type'), 'axes'))); 
    set(kids(~cellfun('isempty', strfind(get(kids, 'type'), 'uimenu'))), 'visible', 'off');
    set(kidAxes, 'xcolor', [1 1 1], 'ycolor', [1 1 1]);
    numCells = sqrt(length(kidAxes) / 2);
    
    % set the scale for a given cell to be constant for psps/spikes
    % and make a scale bar
    for i = 0:numCells - 1
        % determine scale
        pspScale = max(diff(cell2mat(get(kidAxes([i * numCells * 2 + 1:i * numCells * 2 + i * 2 i * numCells * 2 + 1 + (i + 1) * 2:(i + 1) * numCells * 2]), 'ylim')), 1, 2));
        spikeScale = max(diff(cell2mat(get(kidAxes(i * numCells * 2 + i * 2 + 1:i * numCells * 2 + 1 + (i + 1) * 2 - 1), 'ylim')), 1, 2));        
        
        % set limits of psps  
        for j = [i * numCells * 2 + 1:i * numCells * 2 + i * 2 i * numCells * 2 + 1 + (i + 1) * 2:(i + 1) * numCells * 2]
            yData = cell2mat((get(cell2mat(get(kidAxes(j), 'children')), 'yData'))');
            middleVal = min(yData) + range(yData) / 2;
            if isempty(middleVal)
                middleVal = 0;
            end   
            set(kidAxes(j), 'ylim', [middleVal - pspScale / 2 middleVal + pspScale / 2]);            
        end

        % set limits of spikes
        yData = cell2mat((get(cell2mat(get(kidAxes(i * numCells * 2 + i * 2 + 1:i * numCells * 2 + 1 + (i + 1) * 2 - 1), 'children')), 'yData'))');
        middleVal = min(yData) + range(yData) / 2;
        if isempty(middleVal)
            middleVal = 0;
        end
        set(kidAxes(i * numCells * 2 + i * 2 + 1:i * numCells * 2 + 1 + (i + 1) * 2 - 1), 'ylim', [middleVal - spikeScale / 2 middleVal + spikeScale / 2]);
        
        % draw scale bars
        prepForPrint(kidAxes((i + 1) * numCells * 2), 'V', 'yOnly', 'openRight', 'location', [0 .2]);
        if i == 0
            prepForPrint(kidAxes(i * numCells * 2 + 1), 'V', 'location', [1 .2]);
        else
            prepForPrint(kidAxes(i * numCells * 2 + 1), 'V', 'yOnly', 'location', [1 .2]);
        end
    end
    
    if isdeployed
        deployprint('-noui');
    else
        print('-v', '-noui', gcf)
    end
    
    % set things back as they were
    set(kids(~cellfun('isempty', strfind(get(kids, 'type'), 'uimenu'))), 'visible', 'on');
    set(kidAxes, 'xcolor', [0 0 0], 'ycolor', [0 0 0]);
    set(gcf, 'color', [0.8 0.8 0.8]);
    for i = 0:numCells - 1
       kidKids = get(kidAxes((i + 1) * numCells * 2), 'children');
       delete(kidKids(1:2))
       kidKids = get(kidAxes(i * numCells * 2 + 1), 'children');
       if i == 0
           delete(kidKids(1:4))    
       else
           delete(kidKids(1:2))
       end
    end
    
function ampVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 1) > 1
        plot(PSPdata(:,7), PSPdata(:,3), 'linestyle', 'none', 'marker', '.');
        hold on
        title(['Amplitude, mean = ' num2str(mean(PSPdata(:,3)), '%4.2f') ' mV\\pA'])
        xlabel('Time (msec)')
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function riseVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 1) > 1
        plot(PSPdata(:,7), PSPdata(:,4), 'linestyle', 'none', 'marker', '.');
        hold on
        title(['Rise Time, mean = ' num2str(mean(PSPdata(:,4)), '%4.2f') ' msec'])
        xlabel('Time (msec)')
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function decayVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 1) > 1
        plot(PSPdata(:,7), PSPdata(:,6), 'linestyle', 'none', 'marker', '.');
        hold on
        title(['Decay Tau, mean = ' num2str(mean(PSPdata(:,6)), '%4.2f') ' msec'])
        xlabel('Time (msec)')
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end    