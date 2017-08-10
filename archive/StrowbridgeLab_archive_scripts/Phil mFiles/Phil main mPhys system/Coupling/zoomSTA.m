function zoomSTA

    if strcmp(get(gcf, 'SelectionType'), 'normal') % left mouse button
         % get all of the data we need
        tempData = get(gcf, 'userData');
        channels = tempData{1};
        stims = tempData{3};
        windowSize = tempData{6};
        windowDelay = tempData{7};
        currentAxis = circshift([1 length(channels) + 1] - round((get(gcf, 'CurrentPoint') - .02) .* [-length(stims) length(channels)] + 0.5), [0 1]);
        cellPath = get(gcf, 'name');
        
        set(copyobj(gcbo, figure), 'units', 'normal', 'position', [0.05 0.05 .9 .9], 'xticklabelmode', 'auto', 'yticklabelmode', 'auto');
        set(gcf, 'pointer', 'fullcrosshair', 'units', 'normal', 'position', [0 0.05 1 .9], 'color', [1 1 1], 'numbertitle', 'off', 'name', ['Cell ' num2str(currentAxis(1)) ' from stim ' num2str(currentAxis(2)) ' in ' cellPath(25:end)]);
        kid = get(get(gcf, 'children'), 'children');
        kidData = get(kid, 'yData');   
        kidXData = get(kid, 'xData');

        set(kid, 'xData',  kidXData - kidXData(1) - windowSize * diff(kidXData(1:2)));
        line([-windowSize * diff(kidXData(1:2)) 0], [min(kidData) - .1 * range(kidData) min(kidData) - .1 * range(kidData)], 'color', [0 0 0], 'linewidth', 3);
        line([windowDelay * diff(kidXData(1:2)) windowDelay * diff(kidXData(1:2)) + windowSize * diff(kidXData(1:2))], [min(kidData) - .1 * range(kidData) min(kidData) - .1 * range(kidData)], 'color', [0 0 0], 'linewidth', 3);
        if windowSize > 50 % the batch routine actually compares the last 50 points before the spike to the prespike instead of the whole thing
            line([-50 * diff(kidXData(1:2)) 0], [min(kidData) - .1 * range(kidData) min(kidData) - .1 * range(kidData)], 'color', [0 1 0], 'linewidth', 3);
        end
        ylabel('mV\\pA');
        xlabel('Time (msec)');
        
        set(gca, 'buttondownfcn', []);
    end