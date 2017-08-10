function handle = characterizePSPs(PSPs, totalTime)
handle = [];

% sort into I and E PSPs
IPSPs = find(PSPs(:, 1) < 0);
EPSPs = find(PSPs(:, 1) > 0);

% make a figure of IPSPs
if ~isempty(IPSPs)
    handle = figure('units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off', 'name', 'Downward PSP summary');
    subplot(2,2,1)
    histfit(PSPs(IPSPs, 1), min([max([5 sum(IPSPs)/10]) 400]));
    xlabel('Amp (pA\mV)') 
    title(['Mean = ' sprintf('%3.2f', mean(PSPs(IPSPs,1))) ', SD = ' sprintf('%3.2f', std(PSPs(IPSPs,1))) ', median = ' sprintf('%3.2f', median(PSPs(IPSPs,1)))]);
    set(gca, 'buttondownfcn', @ampVsTime);
    
    subplot(2,2,2)
    if numel(IPSPs) > 1000
        histfit(PSPs(IPSPs, 2), min(PSPs(IPSPs, 2)):0.2:max(PSPs(IPSPs, 2)))
    else
        histfit(PSPs(IPSPs, 2), max([5 sum(IPSPs)/10]))
    end
    xlabel('Rise Time (msec)')
    title(['Mean = ' sprintf('%3.2f', mean(PSPs(IPSPs,2))) ', SD = ' sprintf('%3.2f', std(PSPs(IPSPs,2))) ', median = ' sprintf('%3.2f', median(PSPs(IPSPs,2)))]);
    set(gca, 'buttondownfcn', @riseVsTime);
    
    if ~isnan(PSPs(1,4))
        subplot(2,2,3)
        if numel(IPSPs) > 1000
            histfit(PSPs(IPSPs, 4), min(PSPs(IPSPs, 4)):0.2:max(PSPs(IPSPs, 4)))
        else
            histfit(PSPs(IPSPs, 4), max([5 sum(IPSPs)/10]))
        end
        xlabel('Decay Time (msec)')
        title(['Mean = ' sprintf('%3.2f', mean(PSPs(IPSPs,4))) ', SD = ' sprintf('%3.2f', std(PSPs(IPSPs,4))) ', median = ' sprintf('%3.2f', median(PSPs(IPSPs,4)))]);
        set(gca, 'buttondownfcn', @decayVsTime);

        subplot(2,2,4)
    else
        subplot(2,2,3:4)
    end
    if length(IPSPs) > 1
        if all(diff(PSPs(IPSPs, 3)) > 0)
            % these appear to all be from the same trace
            yData = [1000 ./ diff(PSPs(IPSPs(1:2), 3)); 1000 ./ diff(PSPs(IPSPs, 3))];
            plot(PSPs(IPSPs, 3), yData)

            hold on
            % median filtering
            plot(PSPs(IPSPs, 3), medfilt1(yData, 30), 'color', [1 0 0])
            if exist('totalTime', 'var')
                title(['Frequency (Hz), mean = ' num2str(length(IPSPs) ./ totalTime, '%4.2f') ' Hz, count = ' num2str(length(IPSPs))])
            else
                title('Frequency (Hz)')            
            end
        elseif range(diff(PSPs(IPSPs, 3))) < 10
             % these appear to all be from the same trace        
            yData = PSPs(IPSPs, 1);
            yData(isnan(yData)) = 0;
            plot(1:size(IPSPs, 1), yData, 'color', [0 0 0], 'linestyle', 'none', 'marker', '.', 'markerSize', 18)
            title('Amplitude, non-detects shown as zero')
            xlabel('Trace Index')    
		else
			averageFrequencies(PSPs(IPSPs, 3));
            if exist('totalTime', 'var')
                title(['Frequency (Hz), mean = ' num2str(length(IPSPs) ./ totalTime ./ (1 + sum(diff(PSPs(IPSPs, 3)) < 0)), '%4.2f') ' Hz, count = ' num2str(length(IPSPs))])
            else
                title('Frequency (Hz)')            
            end			
        end
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    set(gcf, 'userData', PSPs(IPSPs, :));
end

% make a figure of EPSPs
if ~isempty(EPSPs)
    handle = [handle figure('units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off', 'name', 'Upward PSP summary')];
    subplot(2,2,1)
    histfit(PSPs(EPSPs, 1), min([max([5 sum(EPSPs)/10]) 400]));    
    xlabel('Amp (pA\mV)') 
    title(['Mean = ' sprintf('%3.2f', mean(PSPs(EPSPs,1))) ', SD = ' sprintf('%3.2f', std(PSPs(EPSPs,1))) ', median = ' sprintf('%3.2f', median(PSPs(EPSPs,1)))]);    
    set(gca, 'buttondownfcn', @ampVsTime);
    
    subplot(2,2,2)
    if numel(EPSPs) > 1000
        histfit(PSPs(EPSPs, 2), min(PSPs(EPSPs, 2)):0.2:max(PSPs(EPSPs, 2)))
    else
        histfit(PSPs(EPSPs, 2), max([5 sum(EPSPs)/10]))
    end
    xlabel('Rise Time (msec)')
    title(['Mean = ' sprintf('%3.2f', mean(PSPs(EPSPs,2))) ', SD = ' sprintf('%3.2f', std(PSPs(EPSPs,2))) ', median = ' sprintf('%3.2f', median(PSPs(EPSPs,2)))]);        
    set(gca, 'buttondownfcn', @riseVsTime);
    
    if ~isnan(PSPs(1,4))
        subplot(2,2,3)
        if numel(EPSPs) > 1000
            histfit(PSPs(EPSPs, 4), min(PSPs(EPSPs, 4)):0.2:max(PSPs(EPSPs, 4)))
        else
            histfit(PSPs(EPSPs, 4), max([5 sum(EPSPs)/10]))
        end
        xlabel('Decay Time (msec)')    
        title(['Mean = ' sprintf('%3.2f', mean(PSPs(EPSPs,4))) ', SD = ' sprintf('%3.2f', std(PSPs(EPSPs,4))) ', median = ' sprintf('%3.2f', median(PSPs(EPSPs,4)))]);    
        set(gca, 'buttondownfcn', @decayVsTime);

        subplot(2,2,4)
    else
        subplot(2,2,3:4)
    end
    
    if length(EPSPs) > 1
        if all(diff(PSPs(EPSPs, 3)) > -10)
            % these appear to all be from the same trace        
            yData = [1000 ./ diff(PSPs(EPSPs(1:2), 3)); 1000 ./ diff(PSPs(EPSPs, 3))];
            plot(PSPs(EPSPs, 3), yData)

            hold on
            % median filtering
            plot(PSPs(EPSPs, 3), medfilt1(yData, 30), 'color', [1 0 0])
            if exist('totalTime', 'var')
                title(['Frequency (Hz), mean = ' num2str(length(EPSPs) ./ totalTime, '%4.2f') ' Hz, count = ' num2str(length(EPSPs))])
            else
                title('Frequency (Hz)')            
            end
            xlabel('Time (msec)')
		elseif range(diff(PSPs(EPSPs, 3))) < 10
             % these appear to all be from the same trace        
            yData = PSPs(:, 1);
            yData(isnan(yData)) = 0;
            plot(1:size(PSPs, 1), yData, 'color', [0 0 0], 'linestyle', 'none', 'marker', '.', 'markerSize', 18)
            title('Amplitude, non-detects shown as zero')
            xlabel('Trace Index')    
		else
			averageFrequencies(PSPs(EPSPs, 3));
            if exist('totalTime', 'var')
                title(['Frequency (Hz), mean = ' num2str(length(EPSPs) ./ totalTime ./ (1 + sum(diff(PSPs(EPSPs, 3)) < 0)), '%4.2f') ' Hz, count = ' num2str(length(EPSPs))])
            else
                title('Frequency (Hz)')            
            end			
        end			
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    set(gcf, 'userData', PSPs(EPSPs, :));
end

function averageFrequencies(PSPdata)
    persistent filterLength
    
	% reshape the input data into columns
	eventChanges = [1; find(diff(PSPdata) < 0); length(PSPdata)];
	for i = 1:numel(eventChanges) - 1
		events{i} = PSPdata(eventChanges(i):eventChanges(i + 1))';
	end
    % plot the frequency data
	xData = min(PSPdata):max(PSPdata);    
    if isempty(filterLength)
        % suggest a window that has, on average, 5 events in it
    	filterLength = round(length(xData) / range(PSPdata) * 2.5) * 10;
        howManyDigits = floor(log10(filterLength));
        filterLength = round(filterLength / 10^howManyDigits) * 10^howManyDigits;
    end
    tempData = inputdlg({'Boxcar length (msec)'},'Plot Freq...',1, {num2str(filterLength)});      
    if numel(tempData) == 0
        return
    end
    filterLength = round(str2double(tempData));
    if filterLength > range(PSPdata)
        % just give them the mean
        line([xData(1) xData(end)], numel(PSPdata) ./ filterLength + [0 0], 'color', [0 0 0], 'linewidth', 1);
        xlabel('Window longer than data has affected frequency calculation');
        return
    end
    yData = zeros(numel(events), size(xData, 2));    
	firstEvent = round(min(PSPdata));
    for i = 1:numel(events)
        if numel(events{i}) > 1
            % this is simply a boxcar filter, but implemented using the
            % filter command it took 100x longer
            changeData = ones(1, 2 * numel(events{i}));
            changeData(end/2 + 1:end) = -1;
            whereData = [round(events{i} - filterLength / 2) round(events{i} + filterLength / 2) + 1] - firstEvent;
            [whereData indices] = sort(whereData);           
            lastSum = sum(whereData <= 0);
            yData(i, 1:whereData(lastSum + 1)) = lastSum / (filterLength);
            for j = lastSum + 1:min([find(whereData < length(yData), 1, 'last') - 1 size(whereData, 2) - 1]);
                lastSum = lastSum + changeData(indices(j));
                yData(i, whereData(j):whereData(j + 1)) = lastSum / (filterLength) * 1000;
            end
        end
    end
%     line(xData, mean(yData, 1) + std(yData, 1) / sqrt(numel(events)), 'color', [0 0 0]);
%     line(xData, mean(yData, 1) - std(yData, 1) / sqrt(numel(events)), 'color', [0 0 0]);    
%     patch([xData xData(end:-1:1)]', [mean(yData, 1) + std(yData, 1) / sqrt(numel(events)) mean(yData(:, end:-1:1), 1) - std(yData(:, end:-1:1), 1) / sqrt(numel(events))]', [.8 .8 .8], 'edgecolor', 'none');
    line(xData, mean(yData, 1), 'color', [0 0 0], 'linewidth', 1);


function ampVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 1) > 1
        plot(PSPdata(:,3), PSPdata(:,1), 'linestyle', 'none', 'marker', '.');
        hold on
        title(['Amplitude, mean = ' num2str(mean(PSPdata(:,1)), '%4.2f') ' mV\\pA'])
        xlabel('Time (msec)')
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function riseVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 1) > 1
        plot(PSPdata(:,3), PSPdata(:,2), 'linestyle', 'none', 'marker', '.');
        hold on
        title(['Rise Time, mean = ' num2str(mean(PSPdata(:,2)), '%4.2f') ' msec'])
        xlabel('Time (msec)')
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function decayVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 1) > 1
        plot(PSPdata(:,3), PSPdata(:,4), 'linestyle', 'none', 'marker', '.');
        hold on
        title(['Decay Tau, mean = ' num2str(mean(PSPdata(:,4)), '%4.2f') ' msec'])
        xlabel('Time (msec)')
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function y = range(x, dim)
    if nargin < 2
        y = max(x) - min(x);
    else
        y = max(x,[],dim) - min(x,[],dim);
    end