function makeRaster
% generate a raster plot given ROI and a stack of images

    handleList = getappdata(0, 'imageBrowser');
    ROI = getappdata(0, 'ROI');
    info = evalin('base', 'zImage.info');
    
    % filter data
    golay = sgolayfilt(ROI.roiData', 3, 19);

    % create array of peaks and valleys
    golay_der = golay(2:info.NumImages,:) - golay(1:info.NumImages -1,:);
    peaks = zeros(ROI.numObjects, 100);

    %if extremes are short then discount them
    peakThresh = (max(max(golay))-min(min(golay)))/ 5;
    numHits = 0;

    for x = 1:ROI.numObjects

        %pick peaks from change of derivative sign
        places = find(golay_der(1:info.NumImages-2,x)./golay_der(2:info.NumImages-1,x) < 0)+1;
        peaks(x,1:length(places)) = places'; %where does the sign change
        sizePeaks(x) = length(places);

        %if fewer than 3 peaks then skip
        if sizePeaks(x) < 3
            continue
        end

        %determine whether first point is a peak or valley
        if golay(peaks(x,2), x) < golay(peaks(x,1), x) %first value is a max
            for y = 2:2:sizePeaks(x)-2
                peakHeight = golay(peaks(x,y+1), x) - (golay(peaks(x,y), x) + golay(peaks(x,y+2), x))/2;
                if peakHeight > peakThresh & peaks(x,y+2)-peaks(x,y) > 20 % 20% of range
                    numHits = numHits + 1;
                    rasterArray(numHits,:) = [peaks(x,y) x];
                end         
            end
        else  %first value is a min
            for y = 2:2:sizePeaks(x)-1
                peakHeight = golay(peaks(x,y), x) - (golay(peaks(x,y-1), x) + golay(peaks(x,y+1), x))/2;
                if peakHeight > peakThresh & peaks(x,y+1)-peaks(x,y-1) > 20 % 20% of range
                    numHits = numHits + 1;
                    rasterArray(numHits,:) = [peaks(x,y-1) x];
                end    
            end
        end
    end

    %display raster plot
    set(0, 'CurrentFigure', handlelist.frmRaster);
    plot(rasterArray(:,1), rasterArray(:,2), '+');
    set(gca, 'XLim', [1 info.NumImages]);
    set(gca, 'YLim', [0.5 numObjects + 0.5]);

    %display location plot
    set(0, 'CurrentFigure', handlelist.frmLocPlot);
    for x = 1:numObjects
        text(cellProps(x).Centroid(1), cellProps(x).Centroid(2), num2str(x))
    end
    set(gca, 'XLim', [1 info.Width]);
    set(gca, 'YLim', [1 info.Height]);