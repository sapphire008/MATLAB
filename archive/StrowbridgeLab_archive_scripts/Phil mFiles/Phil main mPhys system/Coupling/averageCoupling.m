function averageCoupling

    if strcmp(get(gcf, 'SelectionType'), 'normal') % left mouse button
         % get all of the data we need
        tempData = get(gcf, 'userData');
        channels = tempData{1};
        stims = tempData{3};
        currentAxis = circshift([1 length(channels) + 1] - round((get(gcf, 'CurrentPoint') - .02) .* [-length(stims) length(channels)] + 0.5), [0 1]);

        cellPath = get(gcf, 'name');
        
        figHandle = figure;
        set(copyobj(gcbo, figHandle), 'units', 'normal', 'position', [0.05 0.05 .9 .9], 'xticklabelmode', 'auto', 'yticklabelmode', 'auto');
        set(figHandle, 'units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off', 'name', ['Cell ' num2str(currentAxis(1)) ' from stim ' num2str(currentAxis(2)) ' in ' cellPath(11:end)]);
        set(gca, 'buttondownfcn', '');
        kids = get(figHandle, 'children');
        kids = get(kids(1), 'children');
        kids = kids(strcmp(get(kids, 'type'), 'line'));
        kidData = get(kids, 'xData');
        kidColor = get(kids, 'color');
        minLengthI = 1000;
        minLengthE = 1000;

        % if cleanupCoupling has been run then add back in the black line as a kid
        if any(get(kids(length(kids)), 'color') ~= [0 0 0])
            kids(length(kids) + 1) = line(1,1, 'linewidth', 4, 'color', [1 0 0]);
            kids(length(kids) + 1) = line(1,1, 'linewidth', 4, 'color', [0 0 1]);
        else
            set(kids(length(kids)), 'linewidth', 4, 'color', [1 0 0]);
            kids(length(kids) + 1) = line(1,1, 'linewidth', 4, 'color', [0 0 1]);
        end

        % subtract off the offset so that x axis is in time post spike
        % also find the shortest one for averaging later
        for xIndex = 1:length(kids) - 2
            set(kids(xIndex), 'xData', kidData{xIndex} - min(kidData{xIndex}));
            if length(kidData{xIndex}) < minLengthI && all(kidColor{xIndex} == [0 0 1])
                minLengthI = length(kidData{xIndex});
            end
            if length(kidData{xIndex}) < minLengthE && all(kidColor{xIndex} == [1 0 0])
                minLengthE = length(kidData{xIndex});
            end
        end
        % tempXDataI = kidData{1} - min(kidData{1});
        % tempXDataE = kidData{1} - min(kidData{1});

        meanLineI = zeros(1, minLengthI);
        meanLineE = zeros(1, minLengthE);

        numI = 0;
        numE = 0;
        for xIndex = 1:length(kids) - 2
            tempData = get(kids(xIndex), 'yData');
            if all(kidColor{xIndex} == [0 0 1])
                meanLineI = meanLineI + tempData(1:minLengthI);
                numI = numI + 1;
            else
                meanLineE = meanLineE + tempData(1:minLengthE);
                numE = numE + 1;
            end
        end

        if numI > 0
            set(kids(length(kids)), 'yData', meanLineI / numI, 'xData', (0:minLengthI - 1)*diff(kidData{1}(1:2)));
        else
            delete(kids(length(kids)));
        end

        if numE > 0
            set(kids(length(kids) - 1), 'yData', meanLineE / numE, 'xData', (0:minLengthE - 1)*diff(kidData{1}(1:2)));
        else
            delete(kids(length(kids) - 1));
        end

        xlabel('Time Post Action Potential')
    elseif strcmp(get(gcf, 'SelectionType'), 'alt') % right mouse button for EPSPs
        % get all of the data we need
        tempData = get(gcf, 'userData');
        channels = tempData{1};
        numProcessed = tempData{2};
        stims = tempData{3};
        % this is of the format (axis number, [sequence, episode, amp,
        % tau, timePostSpike, yOffset, time since whole cell, drug #], :)
        PSPdata = tempData{4};
        
        % check to make sure we have enough data to act on
        currentAxis = circshift(round((get(gcf, 'CurrentPoint') - .02) .* [length(stims) length(channels)] + 0.5), [0 1]);
        whichPSPs = find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0);
        if ~isempty(whichPSPs)
            % plot histograms of tau and amp above a frequency vs time plot
            figure('units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off', 'name', ['EPSPs in cell ' num2str(length(channels) + 1 - currentAxis(1)) ' from stim ' num2str(currentAxis(2)) ' in ' get(gcf, 'name')]);
            subplot(2,3,1)
%             set(histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0))),'FaceColor','r','EdgeColor','w')
            histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, whichPSPs));
            xlabel('Amplitude (pA\\mV)') 
            set(gca, 'buttondownfcn', @ampVsTime);

            subplot(2,3,2)
%             set(histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 4, find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0))),'FaceColor','r','EdgeColor','w')    
            histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 4, whichPSPs))
            xlabel('Rise time (msec)')
            set(gca, 'buttondownfcn', @riseVsTime);
            
            subplot(2,3,3)
%             set(histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 4, find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0))),'FaceColor','r','EdgeColor','w')    
            if ~all(isnan(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 6, whichPSPs)))
                histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 6, whichPSPs))
                xlabel('Decay time (msec)')   
                set(gca, 'buttondownfcn', @decayVsTime);
            else
                text(.2, .5, 'Decay times not fit', 'FontSize', 20)   
            end                
            
            subplot(2,3,4)
            histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 5, whichPSPs))
            xlabel('Time post spike (msec)')
            set(gca, 'buttondownfcn', @delayVsTime);
            
            subplot(2,3,5:6)
            if length(whichPSPs) > 5
                [sortedXData indexOrders] = sort(squeeze(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 7, whichPSPs)));
                plot(sortedXData, 100 * [1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders(1:2)))); squeeze(1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders))))], 'linestyle', 'none', 'marker', '.');
                hold on
                % savitsky-golay filtering
                plot(sortedXData, sgolayfilt(100 * [1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders(1:2)))); squeeze(1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders))))], 3, round(length(sortedXData) / 5) * 2 + 1), 'color', [1 0 0])
                title(['Successes (%), mean = ' num2str(mean(100 .* length(whichPSPs) ./ numProcessed), '%4.2f') '%'])
                xlabel('Time Since WC (sec)')
                set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
            else
                text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
            end
            set(gcf, 'userData', squeeze(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), :, whichPSPs)));
        else
            disp('****** Insufficient events in window for figure generation')
        end
    elseif strcmp(get(gcf, 'SelectionType'), 'extend') % middle mouse button for IPSPs
        % get all of the data we need
        tempData = get(gcf, 'userData');
        channels = tempData{1};
        numProcessed = tempData{2};
        stims = tempData{3};
        % this is of the format (axis number, [sequence, episode, amp,
        % tau, timePostSpike, yOffset, time since whole cell, drug #], :)
        PSPdata = tempData{4};
        
        % check to make sure we have enough data to act on
        currentAxis = circshift(round((get(gcf, 'CurrentPoint') - .02) .* [length(stims) length(channels)] + 0.5), [0 1]);
        whichPSPs = find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) < 0);
        if ~isempty(whichPSPs)
            % plot histograms of tau and amp above a frequency vs time plot
            figure('units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off', 'name', ['IPSPs in cell ' num2str(length(channels) + 1 - currentAxis(1)) ' from stim ' num2str(currentAxis(2)) ' in ' get(gcf, 'name')]);
            subplot(2,3,1)
%             set(histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0))),'FaceColor','r','EdgeColor','w')
            histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, whichPSPs));
            xlabel('Amplitude (pA\\mV)') 
            set(gca, 'buttondownfcn', @ampVsTime);

            subplot(2,3,2)
%             set(histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 4, find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0))),'FaceColor','r','EdgeColor','w')    
            histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 4, whichPSPs))
            xlabel('Rise time (msec)')
            set(gca, 'buttondownfcn', @riseVsTime);

            subplot(2,3,3)
%             set(histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 4, find(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 3, :) > 0))),'FaceColor','r','EdgeColor','w')    
            if ~all(isnan(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 6, whichPSPs)))
                histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 6, whichPSPs))
                xlabel('Decay time (msec)')      
                set(gca, 'buttondownfcn', @decayVsTime);
            else
                text(.2, .5, 'Decay times not fit', 'FontSize', 20)   
            end
            
            subplot(2,3,4)
            histfit(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 5, whichPSPs))
            xlabel('Time post spike (msec)')
            set(gca, 'buttondownfcn', @delayVsTime);
            
            subplot(2,3,5:6)
            if length(whichPSPs) > 5
                [sortedXData indexOrders] = sort(squeeze(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 7, whichPSPs)));
                plot(sortedXData, 100 * [1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders(1:2)))); squeeze(1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders))))], 'linestyle', 'none', 'marker', '.');
                hold on
                % savitsky-golay filtering
                plot(sortedXData, sgolayfilt(100 * [1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders(1:2)))); squeeze(1 / diff(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), 2, whichPSPs(indexOrders))))], 3, round(length(sortedXData) / 5) * 2 + 1), 'color', [1 0 0])
                title(['Successes (%), mean = ' num2str(mean(100 .* length(whichPSPs) ./ numProcessed), '%4.2f') '%'])
                xlabel('Time Since WC (sec)')
                set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
            else
                text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
            end
            set(gcf, 'userData', squeeze(PSPdata(length(channels) + 1 - currentAxis(1), currentAxis(2), :, whichPSPs)));
        else
            disp('****** Insufficient events in window for figure generation')
        end
    end
    
function ampVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 2) > 1
        [sortedXData indexOrders] = sort(PSPdata(7, :));
        plot(sortedXData, PSPdata(3, indexOrders), 'linestyle', 'none', 'marker', '.');
        hold on
        % savitsky-golay filtering
        plot(sortedXData, sgolayfilt(PSPdata(3, indexOrders), 3, round(length(sortedXData) / 10) * 2 + 1), 'color', [1 0 0])
        title(['Amplitude, mean = ' num2str(mean(PSPdata(3, :)), '%4.2f') ' mV\\pA'])
        xlabel('Time Since WC (sec)')
        set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function riseVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 2) > 1
        [sortedXData indexOrders] = sort(PSPdata(7, :));
        plot(sortedXData, PSPdata(4, indexOrders), 'linestyle', 'none', 'marker', '.');
        hold on
        % savitsky-golay filtering
        plot(sortedXData, sgolayfilt(PSPdata(4, indexOrders), 3, round(length(sortedXData) / 10) * 2 + 1), 'color', [1 0 0])
        title(['Rise Time, mean = ' num2str(mean(PSPdata(4, :)), '%4.2f') ' mSec'])
        xlabel('Time Since WC (sec)')
        set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function decayVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 2) > 1
        [sortedXData indexOrders] = sort(PSPdata(7, :));
        plot(sortedXData, PSPdata(6, indexOrders), 'linestyle', 'none', 'marker', '.');
        hold on
        % savitsky-golay filtering
        plot(sortedXData, sgolayfilt(PSPdata(6, indexOrders), 3, round(length(sortedXData) / 10) * 2 + 1), 'color', [1 0 0])
        title(['Decay Tau, mean = ' num2str(mean(PSPdata(6, :)), '%4.2f') ' mSec'])
        xlabel('Time Since WC (sec)')
        set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end
    
function delayVsTime(varargin)
    PSPdata = get(gcf, 'userData');
    figure('numbertitle', 'off', 'name', '', 'color', [1 1 1]);
    if size(PSPdata, 2) > 1
        [sortedXData indexOrders] = sort(PSPdata(7, :));
        plot(sortedXData, PSPdata(5, indexOrders), 'linestyle', 'none', 'marker', '.');
        hold on
        % savitsky-golay filtering
        plot(sortedXData, sgolayfilt(PSPdata(5, indexOrders), 3, round(length(sortedXData) / 10) * 2 + 1), 'color', [1 0 0])
        title(['Delay, mean = ' num2str(mean(PSPdata(5, :)), '%4.2f') ' mSec'])
        xlabel('Time Since WC (sec)')
        set(gca, 'xticklabel', sec2time(get(gca, 'xticklabel')));
    else
        text(.2, .5, 'Insufficient events for plotting vs time', 'FontSize', 24)
    end    