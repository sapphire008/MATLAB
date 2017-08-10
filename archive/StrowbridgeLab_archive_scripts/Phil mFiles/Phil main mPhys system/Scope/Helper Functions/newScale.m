function newScale(objectHandle, eventInfo)
    if strcmp(get(objectHandle, 'type'), 'figure')
        % update all axes
        handles = get(objectHandle, 'userdata');        
        whichAxes = 1:handles.axesCount;
    else
        % update just the specified axis
        handles = get(get(get(objectHandle, 'parent'), 'parent'), 'userdata');        
        whichAxes = find([handles.channelControl.scaleType] == objectHandle);
    end
    for whichAxis = whichAxes
        set(handles.channelControl(whichAxis).minVal, 'enable', 'off');
        set(handles.channelControl(whichAxis).maxVal, 'enable', 'off');
        % hide events
        kids = get(handles.axes(whichAxis), 'children');
        delete(kids(strcmp(get(kids, 'userData'), 'events')));
		wasVisible = get(kids(end - 1:end), 'visible');
        set(kids(end - 1:end), 'visible', 'off');
        switch get(handles.channelControl(whichAxis).scaleType, 'value')
            case 1 % auto
                set(handles.axes(whichAxis), 'ylimmode', 'auto');
            case 2 % manual
                set(handles.axes(whichAxis), 'ylim', [str2double(get(handles.channelControl(whichAxis).minVal, 'string')) str2double(get(handles.channelControl(whichAxis).maxVal, 'string'))]); 
                set(handles.channelControl(whichAxis).minVal, 'enable', 'on');
                set(handles.channelControl(whichAxis).maxVal, 'enable', 'on');
            case 3 % float with an all-points histogram
                whichLine = findobj(handles.axes(whichAxis), 'userData', 'data');
                whichLine = whichLine(1);
                xData = get(whichLine, 'xData');
                yData = get(whichLine, 'yData');
                middleVal = calcMean(yData(find(xData > min(get(handles.axes(whichAxis), 'xlim')), 1, 'first')));
                set(handles.axes(whichAxis), 'ylim', [middleVal - str2double(cell2mat(get(handles.channelControl(whichAxis).float, 'string')))/2 middleVal + str2double(cell2mat(get(handles.channelControl(whichAxis).float, 'string')))/2]);
            case 4 % float based on the first 10 points in the window
                whichLine = findobj(handles.axes(whichAxis), 'userData', 'data');
                whichLine = whichLine(1);
                xData = get(whichLine, 'xData');
                yData = get(whichLine, 'yData');
                middleVal = mean(yData(find(xData > min(get(handles.axes(whichAxis), 'xlim')), 1, 'first'):find(xData > min(get(handles.axes(whichAxis), 'xlim')), 1, 'first') + 10));
                set(handles.axes(whichAxis), 'ylim', [middleVal - str2double(cell2mat(get(handles.channelControl(whichAxis).float, 'string')))/2 middleVal + str2double(cell2mat(get(handles.channelControl(whichAxis).float, 'string')))/2]);
            case 5 % float based on the min/max
                whichLine = findobj(handles.axes(whichAxis), 'userData', 'data');
                xData = get(whichLine, 'xData');
                yData = get(whichLine, 'yData');
                if iscell(xData)
                    maxVal = -100000;
                    minVal = 100000;                
                    tempData = find(xData{end} > min(get(handles.axes(whichAxis), 'xlim')), 1, 'first'):find(xData{end} < max(get(handles.axes(whichAxis), 'xlim')), 1, 'last');
                    for i = 1:length(yData)
                        if max(yData{i}(tempData)) > maxVal
                            maxVal = max(yData{i}(tempData));
                        end
                        if min(yData{i}(tempData)) < minVal
                            minVal = min(yData{i}(tempData));
                        end       
                    end
                else
                    maxVal = max(yData(find(xData > min(get(handles.axes(whichAxis), 'xlim')), 1, 'first'):find(xData < max(get(handles.axes(whichAxis), 'xlim')), 1, 'last')));
                    minVal = min(yData(find(xData > min(get(handles.axes(whichAxis), 'xlim')), 1, 'first'):find(xData < max(get(handles.axes(whichAxis), 'xlim')), 1, 'last')));
                end
                middleVal = (maxVal + minVal)/2;
                set(handles.axes(whichAxis), 'ylim', [middleVal - str2double(cell2mat(get(handles.channelControl(whichAxis).float, 'string')))/2 middleVal + str2double(cell2mat(get(handles.channelControl(whichAxis).float, 'string')))/2]);
        end
        temp1 = get(handles.axes(whichAxis), 'ylim');
        set(kids(end - 1:end),'ydata', temp1);          
        set(kids(end - 1), 'visible', wasVisible{1});
        set(kids(end), 'visible', wasVisible{2});
        if isappdata(handles.axes(whichAxis), 'events')
            showEvents(handles.axes(whichAxis));
        end
        if isappdata(0, 'imageBrowser')
            showFrameMarker(handles.axes(whichAxis));
        end    
        if strcmp(get(handles.displayBlankArtifacts, 'checked'), 'on')
            showStims(handles.figure);
        end        
    end
    
    % if we updated the whole figure then also do the x axis
    if strcmp(get(objectHandle, 'type'), 'figure')
        xBounds = get(handles.axes(1), 'xlim');
        if xBounds(1) == 0
            xBounds(1) = min(handles.minX);
        end
        set(handles.zoom, 'string', sprintf('%7.3f', (max(handles.maxX) - min(handles.minX)) / diff(xBounds)));

        zoomFactor = str2double(get(handles.zoom, 'string'));
        newStep = 1 / zoomFactor / (1 - 1 / zoomFactor);
        if newStep > 10
            set(handles.slider, 'sliderStep', [1 newStep]);
        else
            set(handles.slider, 'sliderStep', [newStep / 10 newStep]);
        end
        if xBounds(1) == min(handles.minX) && zoomFactor == 1
            set(handles.slider, 'value', 0);
        else
            set(handles.slider, 'value', (xBounds(1) - min(handles.minX)) / (max(handles.maxX) - min(handles.minX)) / (1- 1 / zoomFactor));
        end    
		setAxisLabels(handles.axes(1));
    end
 
