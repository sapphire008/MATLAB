function handles = newScope(varargin)
% display data channels in a scrollable window
% newScope(yData, protocol)
% newScope(yData, protocol, figureHandle)
% newScope({yDataGroup1, yDataGroup2})
% newScope({yDataGroup1, yDataGroup2}, [xData], [channelNames], [figureHandle])
%   where [] denote an optional arguement (order does not matter)
% Example:
%    newScope({[tan(1.1:.01:11); cos(.1:.01:10)], [tan(.1:.01:10); cos(.1:.01:10)]}, {'Dogs', 'Cats'});
%
% The reason that this scheme seems so odd is that it allows fewer copies
% of the data to be stored in the workspace so that you can work with
% larger data sets.  This is accomplished because Matlab cleverly holds
% onto a pointer to the copy of the input when there are subfunctions
% addressing the data instead of creating another copy.  Doubly cleverly,
% if the input data is cleared from its native location (probably the base
% workspace) then Matlab doesn't clear it from memory so that the function
% can still refer to it.  However, as soon as the last subfunction callback
% that uses the data is disconnected from the figure, Matlab will delete the
% data set, allowing the user to clear the data copy at will by removing
% callbacks.
%
if nargin == 1 && ischar(varargin{1}) && strcmp(varargin{1}, 'setup')
    installDir = which('newScope');
    installDir = installDir(1:find(installDir == filesep, 1, 'last'));
    addpath(genpath(installDir));
    savepath;
    return
end

for hIndex = varargin
    if ~iscell(hIndex{1}) && isscalar(hIndex{1}) && ~isstruct(hIndex{1})
        handles.figure = hIndex{1};
    end
end
if ~exist('handles', 'var') || ~isappdata(0, 'scopes') || ~ismember(handles.figure, getappdata(0, 'scopes')) || ~ishandle(hIndex{1})
    % either no handle was passed, or the passed handle doesn't have a
    % scope associated with it, so generate a new scope figure
    if ~exist('handles', 'var')
        % generate a new figure number
        handles.figure = fix(rand * 255 + 1);
        while ismember(handles.figure, get(0, 'children'))
            handles.figure = fix(rand * 255 + 1);
        end
    end
    % installDir is used later to determine whether a newScope was just
    % created and should therefore have default settings
    installDir = which('newScope');
    installDir = installDir(1:find(installDir == filesep, 1, 'last'));

    %initialize plotting window
    set(0, 'Units', 'normal');

    figure(handles.figure);
    set(handles.figure, 'NumberTitle','off',...
        'Name', 'Scope',...
        'menu', 'none',...
        'Units', 'characters',...
        'Position', [0 27.5 319 61],...
        'Visible', 'on',...
        'resizefcn', @resize,...
        'PaperPositionMode', 'auto',...
        'closerequestfcn', @closeScope);
    onScreen(handles.figure);
    
    handles.slider = uicontrol('Style','slider','Units','character','Position', [0 0 1 .015], 'value', 0, 'sliderStep', [1 inf], 'callback', @traceScroll);
    handles.zoom = uicontrol('Style','edit','Units','character','Position',[0 .018 .03 .02], 'string', '1', 'callback', @traceScroll);
    f = uimenu('Label','File');
        uimenu(f,'Label','Print With Axes','Callback','printWithAxes');
        uimenu(f,'Label','Print With Scale Bars','Callback','printWithScaleBars','Accelerator','P');
        handles.printMontage = uimenu(f, 'Label', 'Print Montage', 'Callback', @printMontage,'Accelerator','M');
        uimenu(f, 'Label', 'Print Information...', 'Callback', @printInformation);
        uimenu(f,'Label','Close','Callback','close(gcf)',...
               'Separator','on');
    f = uimenu('Label','Export');
        uimenu(f,'Label','With Axes','Callback','exportWithAxes');
        uimenu(f,'Label','With Scale Bars (file)','Callback','exportWithScaleBars','Accelerator','E');   
        uimenu(f,'Label','Settings...', 'callback', 'exportSettings','Accelerator','S');        
    f = uimenu('Label','Display');
        handles.displayTraces = uimenu(f,'Label','Traces','Callback', @setDisplay, 'checked', 'on','Accelerator','T');
        handles.displayMean = uimenu(f,'Label','Mean','Callback', @setDisplay, 'checked', 'off', 'Separator','on','Accelerator','A');
        handles.displayMedian = uimenu(f,'Label','Median','Callback', @setDisplay, 'checked', 'off','Accelerator','D');
        handles.colorCoded = uimenu(f,'Label','Color Coded','Callback', @setDisplay, 'checked', 'off','Separator','on');    
        handles.displayAligned = uimenu(f,'Label','Aligned to...','Callback', @setDisplayAligned, 'checked', 'off','userData', [1 100 1]);
        handles.displayCursors = uimenu(f,'Label','Cursors','callback', @setCursors, 'checked','on');
        handles.displayEvents = uimenu(f,'Label','Events','checked', 'on','callback',@setDisplayEvents);
        handles.displayEventsType = uimenu(f,'Label','Event Marks...','callback',@setEventMarks, 'userData', 1);
        handles.subtractRefTrace = uimenu(f,'Label','Subtract Reference Trace','callback',@setDisplay, 'userData', 1);
        handles.displayBlankArtifacts = uimenu(f,'Label','Blank Artifacts','Accelerator','B', 'callback',@setDisplayBlankArtifacts, 'userData', 3, 'separator', 'on');
        handles.displayArtifactNames = uimenu(f,'Label','Artifact Names...','callback', @setDisplayArtifactNames);
        handles.displayTTLOverlay = uimenu(f,'Label','Stim-Triggered Overlay','callback',@stimTriggeredOverlay);
        uimenu(f,'Label','Add Channel','Callback', @addChannel);
        uimenu(f,'Label','Remove Channel','Callback', @removeChannel);
        handles.autoUpdateChannels = uimenu(f,'Label','Autoupdate Channels','Callback', @setDisplay);
        uimenu(f,'Label','Plot Browser','callback',@showPlotBrowser);
    uimenu('Label', 'Legend', 'Visible', 'off');
    g =  uicontextmenu;
        uimenu(g,'Label','Set as Limits','Callback', @setLimits);
        uimenu(g,'Label','Set Minimum','Callback', @setMin);
        uimenu(g,'Label','Set Maximum','Callback', @setMax);
        uimenu(g,'Label','Add Channel','Callback', @addChannel, 'separator', 'on');
        uimenu(g,'Label','Remove Channel','Callback', @removeChannel);
        y = uimenu(g,'Label','Export', 'Separator','on');
            uimenu(y,'Label','Data to Workspace','Callback',{@exportToWorkspace, 0});
            uimenu(y,'Label','Time to Workspace','Callback',{@exportToWorkspace, 1});
            uimenu(y,'Label','Names to Workspace','Callback',{@exportToWorkspace, 2});     
            uimenu(y,'Label','Short names to Workspace','Callback',{@exportToWorkspace, 3});             
            uimenu(y,'Label','Data to Clipboard','Callback',{@exportToWorkspace, 8}, 'separator', 'on');
            uimenu(y,'Label','Time to Clipboard','Callback',{@exportToWorkspace, 9}); 
            uimenu(y,'Label','Names to Clipboard','Callback',{@exportToWorkspace, 10}); 
            uimenu(y,'Label','Short names to Clipboard','Callback',{@exportToWorkspace, 11}); 
        uimenu(g,'Label','Load Events...','Callback',@loadEvents);    
        uimenu(g,'Label','Remove Events Between Cursors','Callback',@removeEvents);
        uimenu(uimenu(g,'Label','Mark Event','Callback', @markEventSetup), 'Label', 'New...', 'callback', @newEventSeries);

        % load detection functions
        j = uimenu(g,'Label','Detect');
            fileNames = dir([installDir 'Event Detection']);
            beenSeparated = 0;
            for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
                try
                    funHandle = str2func(iFiles{1}(1:end - 2));
                    if ~beenSeparated
                        uimenu(j, 'Label', funHandle(), 'callback', @detectEvents, 'userData', funHandle, 'separator', 'on');
                        beenSeparated = 1;
                    else
                        uimenu(j, 'Label', funHandle(), 'callback', @detectEvents, 'userData', funHandle);
                    end
                catch
                    disp(['File ' iFiles{1} ' in Event Detection folder is not a valid event detector']);
                end
            end

        % load trace characterization functions
        fileNames = dir([installDir 'Trace Characterization']);
        beenSeparated = 0;
        for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
            try
                funHandle = str2func(iFiles{1}(1:end - 2));
                if ~beenSeparated
                    uimenu(g, 'Label', funHandle(), 'callback', @characterizeTrace, 'userData', funHandle, 'separator', 'on');
                    beenSeparated = 1;
                else
                    uimenu(g, 'Label', funHandle(), 'callback', @characterizeTrace, 'userData', funHandle);
                end
            catch
                disp(['File ' iFiles{1} ' in Trace Characterization folder is not a valid trace characterizer']);
            end
        end

        % load fitting functions
        j = uimenu(g,'Label','Fit');
            fileNames = dir([installDir 'Fitting']);
            for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
                try
                    funHandle = str2func(iFiles{1}(1:end - 2));
                    uimenu(j, 'Label', funHandle(), 'callback', @fitData, 'userData', funHandle);
                catch
                    disp(['File ' iFiles{1} ' in Fitting folder is not a valid fitting function']);
                end
            end

    h = copyobj(g, get(g, 'parent'));
        % load experiment characterization functions if applicable
        uimenu(h,'Label','Set as Reference','Callback', @setAsReference);
        uimenu(h,'Label','Remove Reference','Callback', @removeReference);        
        kids = get(h, 'children'); set(h, 'children', kids([3:end - 3 1 2 end - 2:end]));
        delete(findobj(h, 'Label', 'Set as Limits'));
        if nargin > 1 && isstruct(varargin{2})
            fileNames = dir([installDir 'Experiment Characterization']);
            beenSeparated = 0;
            for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
                try
                    funHandle = str2func(iFiles{1}(1:end - 2));
                    if ~beenSeparated
                        uimenu(h, 'Label', funHandle(), 'callback', @characterizeExperiment, 'userData', funHandle, 'separator', 'on');
                        beenSeparated = 1;
                    else
                        uimenu(h, 'Label', funHandle(), 'callback', @characterizeExperiment, 'userData', funHandle);
                    end
                catch
                    disp(['File ' iFiles{1} ' in Experiment Characterization folder is not a valid event detector']);
                end
            end
        end  

    handles.timeControl = timeControl(214, 70 - 1 * 14);
    handles.traceName = uicontrol('style', 'text', 'backgroundColor', [1 1 1], 'units', 'character', 'position', [3 10 5 5], 'horizontalAlignment', 'center');
    handles.selectionType = 0; % 0 = none, 1 = horizontal sizer, 2 = vertical sizer, 3 = axis sizer
    handles.selectionReference = 0; % startCoordinate for h/v sizers, axis number for axis sizer
    handles.selectionAxis = 1; % the current axis we are over
    handles.markerLoc = 0; % index into y-data of the reference line
    handles.markerTime = 0; % time of the reference line
    handles.markerFixed = 0; % if the reference line is present    
    handles.markerLine = 0; % which line we were closest to when fixing the marker
    handles.axesCount = 1;
    handles.axisPortion = 1; % the portion of the total space that each axis is allocated
    handles.dataChanged = 0; % keeps track of whether the lines displayed are the same as the input data
    handles.useReference = 0;
    handles.analysisAxis{1} = struct('None', []);
    handles.channelControlFunction = 'channelControl(1, 1)';
    
    for iTrace = 1
        handles.channelControl(iTrace) = channelControl(214, 61 - (1 - iTrace) * 14);
        handles.axes(iTrace) = axes('drawmode', 'fast', 'box', 'off', 'color', [1 1 1], 'units', 'character', 'Position', [3 10  5 5], 'nextplot', 'add', 'userData', handles.channelControl(iTrace).resultText);
        set(handles.channelControl(iTrace).frame, 'userdata', handles.axes(iTrace));
        startLine = line([1 1], [0 1], 'color', [0 0 0], 'userData', 0);
        stopLine = line([0 0], [0 1], 'color', [0 0 0], 'visible', 'off');
        if iTrace > 1
            set(gca, 'xticklabel', '', 'xtick', []);
        end

        set(gca, 'ylim', [0 1]);
        set(gca, 'xlim', [0 1]);
        set(startLine, 'color', [0 0 0], 'UIcontextmenu', h);
        set(stopLine, 'UIcontextmenu', g, 'color', [1 0 0], 'visible', 'off');
    end    
else
    handles = get(handles.figure, 'userData');
end

% parse input
if nargin > 0
    % first arguement is always the yData
    if ~iscell(varargin{1})
        varargin{1} = {varargin{1}};
    end
    yData = varargin{1};
    if size(yData{1}, 1) < 3
        yData{1} = yData{1}';
    end
    xDim = size(yData{1}, 1);
    for iData = 2:numel(yData)
        if size(yData{iData}, 1) < 3
            yData{iData} = yData{iData}';
        end
    end

    numTraces = length(yData);
    
    % set boring values in case nothing passed
    for i = 1:numTraces
        channelNames{i} = ['Group ' num2str(i)];
    end
    channelValues = size(yData, 2):-1:1;
    xData = repmat([1 1 size(yData{1}, 1)], size(yData,2), 1);    
    for iTrace = 1:size(yData{1}, 2)
        traceNames{iTrace} = ['data ' sprintf('%0.0f', iTrace)];
    end
    
    if nargin > 1
        if isstruct(varargin{2})
           % input is of the form (yData, protocol)
           protocolData = varargin{2};
           channelNames = protocolData(1).channelNames;
           traceNames = {protocolData.fileName};

           channelIndices = [];
           for ampIndex = find(cellfun(@(x) ~isempty(x), protocolData(1).ampEnable))'
               whatData = whichChannel(protocolData(1), ampIndex);
               if ~isempty(whatData)
                   channelIndices(end + 1) = whatData;
               end
           end
           
           % add in non amplifier channels
           xData = repmat([protocolData(1).timePerPoint / 1000 protocolData(1).timePerPoint / 1000 protocolData(1).sweepWindow],  numel(channelNames), 1);

           if ~isempty(protocolData(1).photometryHeader)
               stimTimes = findStims(protocolData(1), 1); % determine when the photometry started
               for i = 1:size(protocolData(1).photometryHeader.data, 2)
                   yData{end + 1} = protocolData(1).photometryHeader.data(:,i);                   
                   for j = 2:numel(protocolData)
                       yData{end }(:, end + 1) = protocolData(j).photometryHeader.data(:,i);
                   end
                   xData(end + 1, :) = [round(stimTimes{1}(:,1) + protocolData(1).photometryHeader.roiDelay(i)) protocolData(1).imageDuration / size(protocolData(1).photometryHeader.data, 1) round(stimTimes{1}(:,1) + protocolData(1).photometryHeader.roiDelay(i)) + protocolData(1).imageDuration - protocolData(1).imageDuration / size(protocolData(1).photometryHeader.data, 1)];
                   channelNames{end + 1} = ['ROI ' sprintf('%0.0f', i) ', I'];
               end
           end
           % this grabs everything but things labeled 'Amp ', 'Im', or 'Vm' something
           channelIndices = [channelIndices find(cellfun(@(x) x(2) ~= 'm', channelNames))];
              
           if exist('installDir', 'var')
               % this is a new newScope window
               channelValues = channelIndices;
           elseif numel(channelNames) > 0 && (~all(cellfun(@(x) numel(channelNames) == length(x) && all(strcmp(channelNames, x')), get([handles.channelControl.channel], 'string'))))
               % we have a different set of channels  
               clear channelValues
               numNew = 0;
               for j = 1:handles.axesCount
                   savedChannels = get(handles.channelControl(handles.axesCount - j + 1).channel, 'string');                   
                   whichChannels = find(strcmp(savedChannels(get(handles.channelControl(handles.axesCount - j + 1).channel, 'value')), channelNames), 1, 'first');
                   if ~isempty(whichChannels)
                       % set what was set before
                       set(handles.channelControl(handles.axesCount - j + 1).channel, 'enable', 'on');                       
                       channelValues(handles.axesCount - j + 1) =  whichChannels;
                   elseif strcmp(get(handles.autoUpdateChannels, 'checked'), 'off')
                       % just disable the control
                       set(handles.channelControl(handles.axesCount - j + 1).channel, 'enable', 'off');
                       channelValues(handles.axesCount - j + 1) =  nan;
                   else
                       % set what we think is best
                       set(handles.channelControl(handles.axesCount - j + 1).channel, 'enable', 'on');
                       numNew = numNew + 1;
                       channelValues(handles.axesCount - j + 1) = channelIndices(min([length(channelIndices) numNew]));
                   end
               end
           else
               channelValues = cell2mat(get([handles.channelControl.channel], 'value'));
           end

           %reset some parameters for the scope
           if get(handles.timeControl.autoScale, 'value')
               set(handles.axes, 'xlim', [min(xData(:,1)) max(xData(:,3))]); 
           elseif str2double(get(handles.timeControl.maxVal, 'string')) > max(xData(:,3))
               set(handles.timeControl.maxVal, 'string', num2str(max(xData(:,3))));
               if str2double(get(handles.timeControl.minVal, 'string')) > max(xData(:,3))
                    set(handles.timeControl.minVal, 'string', '0');
                    set(handles.axes, 'xlim', [min(xData(:,1)) max(xData(:,3))]);
               else
                    set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) max(xData(:,3))]);
               end            
           end
           setAxisLabels(handles.axes(1));
        else                     
            % figure out which input is which
            for hIndex = 2:nargin
                if ~ishandle(varargin{hIndex}(1)) && numel(varargin{hIndex}) > 2 && isnumeric(varargin{hIndex})
                    if size(varargin{hIndex}, 2) == 3
                        if size(varargin{hIndex}, 1) == size(yData, 2)
                            xData = varargin{hIndex};
                        elseif size(varargin{hIndex}, 1) == 1
                            xData = repmat(varargin{hIndex}, size(yData, 2), 1);
                        else
                            error('Error in xData.  Data must be a vector or a three column matrix of the form [min step max].');
                        end
                    else
                        xData = repmat([varargin{hIndex}(1) diff(varargin{hIndex}(1:2)) varargin{hIndex}(end)], size(yData, 2), 1);
                    end
                elseif ischar(varargin{hIndex})
                    channelNames = {varargin{hIndex}};
                elseif iscell(varargin{hIndex})
                    channelNames = varargin{hIndex};
                end
            end
        end
    end
else
    error('Input to newScope must contain at least yData')
end

handles.minX = xData(:,1); % used for calculating the markerLoc in movePointers
handles.maxX = xData(:,3); % used for checking bounds in horizontal zoom
handles.xStep = xData(:,2); % used for calculating the markerLoc in movePointers

% make sure we have the right number of axes
setappdata(handles.figure, 'updateFunction', @updateTrace);
for i = numel(findobj(handles.figure, 'type', 'axes')) + 1:numel(channelValues) 
    set(handles.figure, 'userData', handles);
    addChannel(handles.axes(1));
    handles = get(handles.figure, 'userData');
end
for i = 1:numel(handles.channelControl)
    if strcmp(get(handles.channelControl(i).channel, 'enable'), 'on')
        set(handles.channelControl(i).channel, 'value', channelValues(min([i numel(channelValues)])));
    end
end

for iTrace = 1:numel(channelValues)
    if strcmp(get(handles.channelControl(iTrace).channel, 'enable'), 'on')    
        set(handles.channelControl(iTrace).channel, 'string', channelNames);
        set(handles.channelControl(iTrace).channel, 'value', channelValues(iTrace));
    end
end

set(handles.figure, 'WindowButtonMotionFcn', @movePointers,...
        'windowButtonDownFcn', @mouseDownScope,...
        'windowButtonUpFcn', @mouseUpScope,...
        'keyPressFcn', @windowKeyPress);
set(handles.printMontage, 'callback', @printMontage);
setappdata(handles.figure, 'characterizeExperiment', @characterizeExperiment);
try
    set(handles.figure, 'WindowScrollWheelFcn', @scrollMouse);
catch
    % mouse scrolling was introduced in some recent version of Matlab, so
    % this keeps older versions from crashing
end

set(handles.figure, 'userData', handles);

if exist('installDir', 'var')
    % this scope was just created so autoscale it
    currentLim = [min(handles.minX) max(handles.maxX)];
else
    currentLim = get(handles.axes(1), 'xlim');
    currentLim(1) = max([min([max(handles.maxX) - 1 currentLim(1)]) min(handles.minX)]);
    currentLim(2) = max([min([max(handles.maxX) currentLim(2)]) min(handles.minX) + 1]);	
end
set(handles.axes, 'xlim', currentLim);
updateTrace(handles.figure, 'all');

% update the x axis
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
    set(handles.slider, 'value', max([0 min([1 (xBounds(1) - min(handles.minX)) / (max(handles.maxX)- min(handles.minX)) / (1- 1 / zoomFactor)])]));
end    
setAxisLabels(handles.axes(1));
xCoord = 1;
    
% this userData will be used to store information about resizing the axes
% if the first entry is 1 then a vertical resize is occuring, 2, a
% horizontal, and 3 a changing of axis size.  the second member is saved
% data used by the process

%%%%%%%%%%%%%%%%%%%%%%%%%%
%  EVENT HANDLERS
%%%%%%%%%%%%%%%%%%%%%%%%%%
% note that these are subfunctions of the newScope function so they get
% access to the data that was passed to create the scope

    function mouseDownScope(varargin)
        pointerLoc = get(handles.figure, 'CurrentPoint');
        figureLoc = get(handles.figure, 'Position');
        tempH = get(handles.figure, 'userData');

        for i = 1:tempH.axesCount
            if (pointerLoc(2) - 3) / (figureLoc(4) - 3) > sum(tempH.axisPortion(1:i - 1)) && (pointerLoc(2) - 3) / (figureLoc(4) - 3) < sum(tempH.axisPortion(1:i))
                tempH.selectionAxis = i;
            end
        end
        if pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3
            % over the axes
            if strcmp(get(tempH.figure, 'pointer'), 'top')
                % over a boundary between two axes
                whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
                for i = 1:tempH.axesCount - 1
                    if whereAt < sum(tempH.axisPortion(1:i)) + tempH.axisPortion(i + 1) * .05 && whereAt > sum(tempH.axisPortion(1:i)) - tempH.axisPortion(i) * .05
                        tempH.selectionReference = i + 1;
                        tempH.selectionType = 3;
                    end
                end
            else
                % over the axis middle
                switch get(tempH.figure, 'SelectionType')
                    case 'normal' %left mouse button clicked
                        if tempH.markerFixed == 0
                            for index = 1:tempH.axesCount
                                kidLines = get(tempH.axes(index), 'children');
                                set(kidLines(end - 1), 'xData', [xCoord xCoord], 'ydata', get(kidLines(end), 'yData'));
                                set(kidLines(end - 1), 'visible', 'on');
                            end
                            tempH.markerFixed = 1;
                        else
                            for index = 1:tempH.axesCount
                                kidLines = get(tempH.axes(index), 'children');
                                set(kidLines(end - 1), 'visible', 'off');
                                set(kidLines(end), 'xData', [xCoord xCoord]);
                            end
                            tempH.markerFixed = 0;
                        end
                    case 'extend' %middle mouse button clicked
                        setappdata(tempH.figure, 'rbStart', get(gca,'CurrentPoint'));
                        rbbox;
                    case 'alt' %right mouse button clicked

                    case 'open' %double click

                end
            end
        elseif pointerLoc(1) <= 7 && pointerLoc(2) > 3
            % over the y-axis on the left
            switch get(tempH.figure, 'SelectionType')
                case 'normal' %left mouse button clicked
                    delete(findobj(tempH.figure, 'tag', 'axisScaler'));
                    uicontrol('tag', 'axisScaler', 'units', 'character', 'Style', 'text', 'String', '', 'backgroundColor', [0 0 1], 'Position', [0, pointerLoc(2), 7, .01]);
                    tempH.selectionReference = pointerLoc(2);
                    tempH.selectionType = 2;
                case 'extend' %middle mouse button clicked

                case 'alt' %right mouse button clicked

                case 'open' %double click

            end
        elseif pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43 && pointerLoc(2) > 3
            % over the y-axis on the right
            switch get(tempH.figure, 'SelectionType')
                case 'normal' %left mouse button clicked
                    delete(findobj(tempH.figure, 'tag', 'axisScaler'));
                    uicontrol('tag', 'axisScaler', 'units', 'character', 'Style', 'text', 'String', '', 'backgroundColor', [0 0 1], 'Position', [figureLoc(3) - 55, pointerLoc(2), 5, .01]);
                    tempH.selectionReference = pointerLoc(2);
                    tempH.selectionType = 4;
                case 'extend' %middle mouse button clicked

                case 'alt' %right mouse button clicked

                case 'open' %double click

            end
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 55 && pointerLoc(2) <= 3
            % over the x-axis
            switch get(tempH.figure, 'SelectionType')
                case 'normal' %left mouse button clicked
                    delete(findobj(tempH.figure, 'tag', 'axisScaler'));
                    uicontrol('tag', 'axisScaler', 'units', 'character', 'Style', 'text', 'String', '', 'backgroundColor', [0 0 1], 'Position', [pointerLoc(1), 1, 0.01, 3]);
                    tempH.selectionReference = pointerLoc(1);
                    tempH.selectionType = 1;
                case 'extend' %middle mouse button clicked

                case 'alt' %right mouse button clicked

                case 'open' %double click

            end
        end
        set(handles.figure, 'userData', tempH);
    end

    function movePointers(varargin)
        pointerLoc = get(handles.figure, 'CurrentPoint');
        figureLoc = get(handles.figure, 'Position');
        tempH = get(handles.figure, 'userData');

        if tempH.selectionType > 0
            blueRect = get(tempH.figure, 'children');
            blueRect = blueRect(1);
            switch tempH.selectionType
                case 1 % horizontal zoom bar
                    if pointerLoc(1) > tempH.selectionReference
                        set(blueRect, 'position', [tempH.selectionReference, 1, pointerLoc(1) - tempH.selectionReference, 2]);
                    elseif pointerLoc(1) < tempH.selectionReference
                        set(blueRect, 'position', [pointerLoc(1), 1, tempH.selectionReference - pointerLoc(1), 2]);
                    end
                case 2 % vertical zoom bar left
                    if pointerLoc(2) > tempH.selectionReference
                        set(blueRect, 'position', [0, tempH.selectionReference, 7, pointerLoc(2) - tempH.selectionReference]);
                    elseif pointerLoc(2) < tempH.selectionReference
                        set(blueRect, 'position', [0, pointerLoc(2), 7, tempH.selectionReference - pointerLoc(2)]);
                    end
                case 3 % resizing axes
                    currentPortion = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
                    if currentPortion > sum(tempH.axisPortion(1:tempH.selectionReference - 2)) && currentPortion < sum(tempH.axisPortion(1:tempH.selectionReference))
                        tempH.axisPortion(tempH.selectionReference - 1) = currentPortion - sum(tempH.axisPortion(1:tempH.selectionReference - 2));
                        tempH.axisPortion(tempH.selectionReference) = 1 - sum(tempH.axisPortion([1:tempH.selectionReference - 1 tempH.selectionReference + 1:tempH.axesCount]));
                    end
                    set(handles.figure, 'userData', tempH);
                case 4 % vertical zoom bar right
                    if pointerLoc(2) > tempH.selectionReference
                        set(blueRect, 'position', [figureLoc(3) - 48, tempH.selectionReference, 5, pointerLoc(2) - tempH.selectionReference]);
                    elseif pointerLoc(2) < tempH.selectionReference
                        set(blueRect, 'position', [figureLoc(3) - 48, pointerLoc(2), 5, tempH.selectionReference - pointerLoc(2)]);
                    end
            end
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3
            % inside the plotting area
            onBorder = false;
            whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
            for i = 1:tempH.axesCount - 1
                if whereAt < sum(tempH.axisPortion(1:i)) + tempH.axisPortion(i + 1) * .05 && whereAt > sum(tempH.axisPortion(1:i)) - tempH.axisPortion(i) * .05
                    onBorder = true;
                end
            end
            if onBorder
                set(handles.figure, 'pointer', 'top');
            else
                % if the ydata has changed because this is a running scope
                % then update it here
                if isfield(tempH, 'isRunning')
                    pointerData = nan(16);
                    pointerData(8,:) = 2;
                    pointerData(:,8) = 2;
                    set(handles.figure, 'pointer', 'custom', 'pointerShapeHotSpot', [8 8], 'pointerShapeCData', pointerData);
                    if get(tempH.isRunning, 'userData')
                        for index = 1:tempH.axesCount
                            lineHandles = get(tempH.axes(index), 'children');
                            whichChan = get(tempH.channelControl(index).channel, 'value');
                            yData{whichChan} = get(lineHandles(1), 'yData')';
                        end
                        set(tempH.isRunning, 'userData', 0);
                    end
                else
                    set(handles.figure, 'pointer', 'crosshair');                    
                end
                whichAxis = find([1 whereAt > cumsum(tempH.axisPortion(1:end-1))] & whereAt < cumsum(tempH.axisPortion), 1, 'first');                
                if strcmp(get(tempH.channelControl(whichAxis).channel, 'enable'), 'off')
                    whichAxis = mod(whichAxis, tempH.axesCount) + 1;
                    if strcmp(get(tempH.channelControl(whichAxis).channel, 'enable'), 'off')
                        return % this channel is disabled
                    end
                end
                whichChan = get(tempH.channelControl(whichAxis).channel, 'value');                
                xCoord = round(((pointerLoc(1) - 7) / (figureLoc(3) - 55)  * diff(get(tempH.axes(1),'Xlim')) + min(get(tempH.axes(1),'Xlim'))) / tempH.xStep(whichChan)) * tempH.xStep(whichChan);
                whereX = round((xCoord - xData(:,1)) ./ tempH.xStep) + 1;
                yCoord = (whereAt - sum(tempH.axisPortion(1:whichAxis - 1))) / tempH.axisPortion(whichAxis) * diff(get(tempH.axes(whichAxis),'Ylim')) + min(get(tempH.axes(whichAxis),'Ylim'));

                if tempH.markerFixed == 0
                    set(tempH.timeControl.displayText, 'string', sprintf('%10.2f', xCoord));
                    axisHandles = nan(tempH.axesCount, 1);
                    
                    % determine which line we are looking at
                    howFar = inf;
                    kidLines = findobj(tempH.axes(whichAxis), 'userData', 'data');
                    if isempty(kidLines)
                        return
                    end
                    for i = [get(tempH.displayMean, 'userData') get(tempH.displayMedian, 'userData')]
                        kidLines  = kidLines(kidLines ~=i);
                    end
                    if strcmp(get(tempH.displayTraces, 'checked'), 'on')
                        if tempH.dataChanged(whichAxis)
                            for traceIndex = 1:numel(kidLines) - (tempH.useReference(whichAxis) && strcmp(get(tempH.subtractRefTrace, 'check'), 'off'))
                                tempData = get(kidLines(traceIndex), 'yData');
                                if numel(tempData) >= whereX(whichChan) - yCoord && abs(tempData(whereX(whichChan)) - yCoord) < howFar
                                    howFar = abs(tempData(whereX(whichChan)) - yCoord);
                                    tempH.markerLine = traceIndex;
                                    set(tempH.traceName, 'string', get(kidLines(traceIndex), 'displayName'));
                                end
                            end
                        else
                            for traceIndex = 1:size(yData{whichChan}, 2)
                                if size(yData{whichChan}, 1) >= whereX(whichChan) && abs(yData{whichChan}(whereX(whichChan), traceIndex) - yCoord) < howFar
                                    howFar = abs(yData{whichChan}(whereX(whichChan), traceIndex) - yCoord);
                                    tempH.markerLine = traceIndex;
                                    set(tempH.traceName, 'string', get(kidLines(end + 1 - traceIndex - (tempH.useReference(whichAxis) && strcmp(get(tempH.subtractRefTrace, 'check'), 'off'))), 'displayName'));
                                end
                            end
                        end
                    end
                    if tempH.useReference(whichAxis) && strcmp(get(tempH.subtractRefTrace, 'check'), 'off')
                        if tempH.dataChanged(whichAxis)
                            tempData = get(kidLines(end), 'yData');
                        else
                            tempData = getappdata(tempH.axes(whichAxis), 'referenceTrace');
                        end
                        if size(tempData,1) >= whereX(whichChan) && abs(tempData(whereX(whichChan)) - yCoord) < howFar
                            howFar = abs(tempData(whereX(whichChan)) - yCoord);
                            tempH.markerLine = -2;
                            set(tempH.traceName, 'string', get(kidLines(end), 'displayName'));
                        end
                    end
                    if strcmp(get(tempH.displayMedian, 'checked'), 'on')
                        tempHandles = get(tempH.displayMedian, 'userData');
                        if ~isnan(tempHandles(whichAxis))
                            tempData = get(tempHandles(whichAxis), 'yData');
                            if abs(tempData(whereX(whichChan)) - yCoord) < howFar
                                tempH.markerLine = -1;
                                set(tempH.traceName, 'string', get(tempHandles(whichAxis), 'displayName'));
                            end
                        end
                    end
                    if strcmp(get(tempH.displayMean, 'checked'), 'on')
                        tempHandles = get(tempH.displayMean, 'userData');
                        if ~isnan(tempHandles(whichAxis))
                            tempData = get(tempHandles(whichAxis), 'yData');
                            if abs(tempData(whereX(whichChan)) - yCoord) < howFar
                                tempH.markerLine = 0;
                                set(tempH.traceName, 'string', get(tempHandles(whichAxis), 'displayName'));
                            end
                        end
                    end 
                    for index = 1:tempH.axesCount
                        try
                            kidLines = get(tempH.axes(index), 'children');
                            if length(kidLines) > 2
                                axisHandles(index) = kidLines(end);    
                                kidLines = kidLines(strcmp('data', get(kidLines, 'userData')));                                
                                switch tempH.markerLine
                                    case -2
                                        % reference trace
                                        tempData = getappdata(tempH.axes(whichAxis), 'referenceTrace');
                                        currentPoint = tempData(whereX(index));
                                    case -1
                                        % median trace
                                        tempHandles = get(tempH.displayMedian, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX(index));
                                    case 0
                                        % mean trace
                                        tempHandles = get(tempH.displayMean, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX(index));                                        
                                    otherwise
                                        % some data trace
                                        if tempH.dataChanged(whichAxis)
                                            tempData = get(kidLines(tempH.markerLine + strcmp(get(tempH.displayMean, 'checked'), 'on') + strcmp(get(tempH.displayMedian, 'checked'), 'on')), 'yData');
                                            currentPoint = tempData(whereX(get(tempH.channelControl(index).channel, 'value')));                                            
                                        else
                                            currentPoint = yData{get(tempH.channelControl(index).channel, 'value')}(whereX(get(tempH.channelControl(index).channel, 'value')), tempH.markerLine);
                                        end
                                end

                                set(tempH.channelControl(index).displayText, 'string', sigPrint(currentPoint));
                            end
                        catch
                            set(tempH.channelControl(index).displayText, 'string', '');
                        end
                    end                    
                    tempH.markerLoc = whereX;
                    tempH.markerTime = xCoord;
                    set(handles.figure, 'userData', tempH);
                    if strcmp(get(tempH.displayCursors, 'checked'), 'on')
                        for index = find(~isnan(axisHandles))' 
                            set(axisHandles(index), 'xData', [xCoord xCoord], 'yData', get(tempH.axes(index), 'ylim'));                    
                        end
                    end
                else % handle marker fixed
                    set(tempH.timeControl.displayText, 'string', [sprintf('%10.2f',tempH.markerTime) ' \ ' sprintf('%10.1f', xCoord - tempH.markerTime)]);
                    axisHandles = nan(tempH.axesCount, 1);                    
                    for index = 1:tempH.axesCount
                        try
                            kidLines = get(tempH.axes(index), 'children');
                            if length(kidLines) > 2
                                axisHandles(index) = kidLines(end - 1);                                                                
                                kidLines = kidLines(strcmp('data', {get(kidLines, 'userData')}));                                                                
                                switch tempH.markerLine
                                    case -2
                                        % reference trace
                                        tempData = getappdata(tempH.axes(whichAxis), 'referenceTrace');
                                        currentPoint = tempData(whereX(index));
                                        lastPoint = tempData(tempH.markerLoc(index));
                                    case -1
                                        % median trace
                                        tempHandles = get(tempH.displayMedian, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX(index));
                                        lastPoint = tempData(tempH.markerLoc(index));
                                    case 0
                                        % mean trace
                                        tempHandles = get(tempH.displayMean, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX(index));
                                        lastPoint = tempData(tempH.markerLoc(index));
                                    otherwise
                                        % some data trace
                                        whichChan = get(tempH.channelControl(index).channel, 'value');
                                        if tempH.dataChanged(whichAxis)
                                            tempData = get(kidLines(tempH.markerLine + strcmp(get(tempH.displayMean, 'checked'), 'on') + strcmp(get(tempH.displayMedian, 'checked'), 'on')), 'yData');
                                            currentPoint = tempData(whereX(index));
                                            lastPoint = tempData(tempH.markerLoc(index));                                                                                     
                                        else
                                            currentPoint = yData{whichChan}(whereX(whichChan), tempH.markerLine);
                                            lastPoint = yData{whichChan}(tempH.markerLoc(index), tempH.markerLine);                                         
                                        end
                                end                                
                                
                                set(tempH.channelControl(index).displayText, 'string', [sigPrint(lastPoint) ', ' sigPrint(currentPoint) ', ' sigPrint(currentPoint - lastPoint)]);
                            end
                        catch
                            set(tempH.channelControl(index).displayText, 'string', '');
                        end
                    end
                    if strcmp(get(tempH.displayCursors, 'checked'), 'on')
                        for index = find(~isnan(axisHandles))'                   
                            set(axisHandles(index), 'xData', [xCoord xCoord], 'yData', get(tempH.axes(index), 'ylim'));                    
                        end
                    end                    
                end
            end
        elseif (pointerLoc(1) <= 7 || (pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43)) && pointerLoc(2) > 3
            % over y-axis
            set(handles.figure, 'pointer', 'top');
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) <= 3
            % over x-axis
            set(handles.figure, 'pointer', 'right');
        end
        if pointerLoc(2) < 1 || pointerLoc(1) > figureLoc(3) - 43
            set(handles.figure, 'pointer', 'arrow');
        end
    end
        
    function mouseUpScope(varargin)
        pointerLoc = get(handles.figure, 'CurrentPoint');
        figureLoc = get(handles.figure, 'Position');
        tempH = get(handles.figure, 'userData');

        if tempH.selectionType > 0
            switch tempH.selectionType
                case 3
                    % relocate the axes bounds
                    for i = 1:tempH.axesCount
                        set(tempH.axes(i), 'position', [7 3 + sum(tempH.axisPortion(1:i - 1)) * (figureLoc(4) - 3) figureLoc(3) - 55 tempH.axisPortion(i) * (figureLoc(4) - 3)]);
                    end
                case 1
                    % resize in the x direction
                    blueRect = get(varargin{1}, 'children');
                    delete(blueRect(1));
                    if tempH.selectionReference ~= pointerLoc(1)
                        xBounds = get(tempH.axes(1), 'xlim');
                        myPoint = (pointerLoc(1) - 7) / (figureLoc(3) - 52)  * diff(xBounds) + min(xBounds);
                        if myPoint < min(tempH.minX)
                            myPoint = min(tempH.minX);
                        end
                        if myPoint > max(tempH.maxX)
                            myPoint = max(tempH.maxX);
                        end
                        set(tempH.axes, 'xlim', sort([(tempH.selectionReference - 7) / (figureLoc(3) - 52)  * diff(xBounds) + min(xBounds) myPoint]));
                        xBounds = get(tempH.axes(1), 'xlim');
                        set(tempH.zoom, 'string', sprintf('%7.1f', (max(tempH.maxX) - min(tempH.minX)) / diff(xBounds)));

                        zoomFactor = str2double(get(tempH.zoom, 'string'));
                        newStep = 1 / zoomFactor / (1 - 1 / zoomFactor);
                        if newStep > 10
                            set(tempH.slider, 'sliderStep', [1 newStep]);
                        else
                            set(tempH.slider, 'sliderStep', [newStep / 10 newStep]);
                        end
                        set(tempH.slider, 'value', max([0 min([1 (xBounds(1) - min(tempH.minX)) / (max(tempH.maxX)- min(tempH.minX)) / (1- 1 / zoomFactor)])]));
                    end
                    set(tempH.timeControl.autoScale, 'value', 0);
                    set(tempH.timeControl.minVal, 'enable', 'on');
                    set(tempH.timeControl.maxVal, 'enable', 'on');
                    set(tempH.timeControl.minVal, 'string', sprintf('%10.1f', min(get(tempH.axes(1), 'xlim'))));
                    set(tempH.timeControl.maxVal, 'string', sprintf('%10.1f', max(get(tempH.axes(1), 'xlim'))));
                    setAxisLabels(tempH.axes(1));
                case 2
                    % resize left in the y direction
                    blueRect = get(varargin{1}, 'children');
                    delete(blueRect(1));
                    if tempH.selectionReference ~= pointerLoc(2)
                        set(tempH.channelControl(tempH.selectionAxis).scaleType, 'value', 2);
                        ylim = sort(([tempH.selectionReference pointerLoc(2)] - 3 - (figureLoc(4) - 3) * sum(tempH.axisPortion(1:tempH.selectionAxis - 1))) / ((figureLoc(4) - 3) * tempH.axisPortion(tempH.selectionAxis)) * diff(get(tempH.axes(tempH.selectionAxis), 'ylim')) + min(get(tempH.axes(tempH.selectionAxis), 'ylim')));
                        set(tempH.channelControl(tempH.selectionAxis).minVal, 'string', sigPrint(ylim(1)));
                        set(tempH.channelControl(tempH.selectionAxis).maxVal, 'string', sigPrint(ylim(2)));
                        newScale(tempH.channelControl(tempH.selectionAxis).scaleType);
                    end
                case 4
                    % resize right in the y direction
                    blueRect = get(varargin{1}, 'children');
                    delete(blueRect(1));                    
                    tempFields = fieldnames(tempH.analysisAxis{tempH.selectionAxis});
                    if numel(tempFields) > 1
                        % there exists at least one analysis axis, so zoom the
                        % last one drawn
                        tempAxis = tempH.analysisAxis{tempH.selectionAxis}.(tempFields{end});
                        if tempH.selectionReference ~= pointerLoc(2)
                            set(tempAxis, 'ylim', sort(([tempH.selectionReference pointerLoc(2)] - 3 - (figureLoc(4) - 3) * sum(tempH.axisPortion(1:tempH.selectionAxis - 1))) / ((figureLoc(4) - 3) * tempH.axisPortion(tempH.selectionAxis)) * diff(get(tempAxis, 'ylim')) + min(get(tempAxis, 'ylim'))));
                        end
                    else
                        % resize left in the y direction
                        if tempH.selectionReference ~= pointerLoc(2)
                            set(tempH.channelControl(tempH.selectionAxis).scaleType, 'value', 2);
                            ylim = sort(([tempH.selectionReference pointerLoc(2)] - 3 - (figureLoc(4) - 3) * sum(tempH.axisPortion(1:tempH.selectionAxis - 1))) / ((figureLoc(4) - 3) * tempH.axisPortion(tempH.selectionAxis)) * diff(get(tempH.axes(tempH.selectionAxis), 'ylim')) + min(get(tempH.axes(tempH.selectionAxis), 'ylim')));                            
                            set(tempH.channelControl(tempH.selectionAxis).minVal, 'string', sigPrint(ylim(1)));
                            set(tempH.channelControl(tempH.selectionAxis).maxVal, 'string', sigPrint(ylim(2)));
                            newScale(tempH.channelControl(tempH.selectionAxis).scaleType);     
                        end
                    end
            end
        elseif strcmp(get(varargin{1}, 'SelectionType'), 'extend')
            if pointerLoc(1) <= 7 && pointerLoc(2) > 3
                % full scale y axis on left
                set(tempH.channelControl(tempH.selectionAxis).scaleType, 'value', 1);
                newScale(tempH.channelControl(tempH.selectionAxis).scaleType);
            elseif pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43 && pointerLoc(2) > 3
                % full scale y axis on right
                tempFields = fieldnames(tempH.analysisAxis{tempH.selectionAxis});
                if numel(tempFields) > 1
                    % there exists at least one analysis axis, so zoom the
                    % last one drawn
                    tempAxis = tempH.analysisAxis{tempH.selectionAxis}.(tempFields{end});
                    set(tempAxis, 'YLimMode', 'auto');
                else
                    % full scale y axis on left
                    set(tempH.channelControl(tempH.selectionAxis).scaleType, 'value', 1);
                    newScale(tempH.channelControl(tempH.selectionAxis).scaleType);
                end
            elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 52 && pointerLoc(2) <= 3
                % full scale x axis
                set(tempH.axes, 'XLim', [min(tempH.minX) max(tempH.maxX)]);
                set(tempH.zoom, 'string', '1.0');
                set(tempH.slider, 'sliderStep', [1 1/0]);
                set(tempH.timeControl.autoScale, 'value', 1);
                set(tempH.timeControl.minVal, 'enable', 'off');
                set(tempH.timeControl.maxVal, 'enable', 'off');
                setAxisLabels(tempH.axes(1))
            elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3 && isappdata(tempH.figure, 'rbStart')
                startPoint = getappdata(tempH.figure, 'rbStart');
                startPoint = startPoint(1,:);
                stopPoint = get(gca,'CurrentPoint');
                stopPoint = stopPoint(1,:);

                % resize to box
                axesKids = get(tempH.axes(tempH.selectionAxis), 'child');
                delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                if startPoint(1) ~= stopPoint(1)
                    if stopPoint(1) < min(tempH.minX)
                        stopPoint(1) = min(tempH.minX);
                    end
                    if stopPoint(1) > max(tempH.maxX)
                        stopPoint(1) = max(tempH.maxX);
                    end
                    set(tempH.axes, 'xlim', sort([startPoint(1) stopPoint(1)]));
                    xBounds = get(tempH.axes(1), 'xlim');
                    set(tempH.zoom, 'string', sprintf('%7.1f', (max(tempH.maxX) - min(tempH.minX)) / diff(xBounds)));

                    zoomFactor = str2double(get(tempH.zoom, 'string'));
                    newStep = 1 / zoomFactor / (1 - 1 / zoomFactor);
                    if newStep > 10
                        set(tempH.slider, 'sliderStep', [1 newStep]);
                    else
                        set(tempH.slider, 'sliderStep', [newStep / 10 newStep]);
                    end
                    set(tempH.slider, 'value', max([0 min([1 (xBounds(1) - min(tempH.minX)) / (max(tempH.maxX)- min(tempH.minX)) / (1- 1 / zoomFactor)])]));
                    setAxisLabels(tempH.axes(1));
                    set(tempH.timeControl.autoScale, 'value', 0);
                    set(tempH.timeControl.minVal, 'enable', 'on');
                    set(tempH.timeControl.maxVal, 'enable', 'on');
                    set(tempH.timeControl.minVal, 'string', sprintf('%10.1f', min(get(tempH.axes(1), 'xlim'))));
                    set(tempH.timeControl.maxVal, 'string', sprintf('%10.1f', max(get(tempH.axes(1), 'xlim'))));
                end
                if startPoint(2) ~= stopPoint(2)
                    set(tempH.channelControl(tempH.selectionAxis).scaleType, 'value', 2);
                    ylim = sort([startPoint(2) stopPoint(2)]);
                    set(tempH.channelControl(tempH.selectionAxis).minVal, 'string', sigPrint(ylim(1)));
                    set(tempH.channelControl(tempH.selectionAxis).maxVal, 'string', sigPrint(ylim(2)));
                    newScale(tempH.channelControl(tempH.selectionAxis).scaleType);
                else
                    % full scale x axis
                    set(tempH.axes, 'XLim', [min(tempH.minX) max(tempH.maxX)]);
                    set(tempH.zoom, 'string', '1.0');
                    set(tempH.slider, 'sliderStep', [1 1/0]);
                    set(tempH.timeControl.autoScale, 'value', 1);
                    set(tempH.timeControl.minVal, 'enable', 'off');
                    set(tempH.timeControl.maxVal, 'enable', 'off');
                    setAxisLabels(tempH.axes(1))

                    % full scale y axis on left
                    set(tempH.channelControl(tempH.selectionAxis).scaleType, 'value', 1);
                    newScale(tempH.channelControl(tempH.selectionAxis).scaleType);
                end
            end
        elseif strcmp(get(varargin{1}, 'SelectionType'), 'alt')
           if pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43 && pointerLoc(2) > 3
                % iterate through the analysis axes sort order
                tempFields = fieldnames(tempH.analysisAxis{tempH.selectionAxis});
                if numel(tempFields) > 2
                    % there exists more than one analysis axis
                    % change the drawing order of the axes
                    figKids = get(tempH.figure, 'children');
                    for i = numel(tempFields) - 1:-1:2
                        set(tempH.analysisAxis{tempH.selectionAxis}.(tempFields{i}), 'color', 'none');
                        figKids(find(figKids == tempH.analysisAxis{tempH.selectionAxis}.(tempFields{i + 1}), 1, 'last')) = tempH.analysisAxis{tempH.selectionAxis}.(tempFields{i});
                    end
                    set(tempH.analysisAxis{tempH.selectionAxis}.(tempFields{end}), 'color', [1 1 1]);
                    figKids(find(figKids == tempH.analysisAxis{tempH.selectionAxis}.(tempFields{2}), 1, 'last')) = tempH.analysisAxis{tempH.selectionAxis}.(tempFields{end});
                    set(handles.figure, 'children', figKids);
                    tempH.analysisAxis{tempH.selectionAxis} = orderfields(tempH.analysisAxis{tempH.selectionAxis}, [1 numel(tempFields) 2:numel(tempFields) - 1]);                    
                end
           end
        end
        tempH.selectionType = 0;
        tempH.selectionReference = 0;
        set(handles.figure, 'userData', tempH);        
    end

    function scrollMouse(varargin)
        pointerLoc = get(handles.figure, 'CurrentPoint');
        figureLoc = get(handles.figure, 'Position');
        tempH = get(handles.figure, 'userData');

        if tempH.selectionType > 0
            return % don't allow scroll wheel if dragging
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3
            % inside the plotting area
            whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
            for i = 1:tempH.axesCount - 1
                if whereAt < sum(tempH.axisPortion(1:i)) + tempH.axisPortion(i + 1) * .05 && whereAt > sum(tempH.axisPortion(1:i)) - tempH.axisPortion(i) * .05
                    % on border so do nothing
                    return      
                end
            end
            whichAxis = find([1 whereAt > cumsum(tempH.axisPortion(1:end-1))] & whereAt < cumsum(tempH.axisPortion), 1, 'first');                
            ylim = get(tempH.axes(whichAxis), 'ylim');
            
            % scroll
            set(tempH.channelControl(whichAxis).scaleType, 'value', 2);
            set(tempH.channelControl(whichAxis).minVal, 'string', sigPrint(ylim(1) + .2 * diff(ylim) * varargin{2}.VerticalScrollCount));
            set(tempH.channelControl(whichAxis).maxVal, 'string', sigPrint(ylim(2) + .2 * diff(ylim) * varargin{2}.VerticalScrollCount));
            newScale(tempH.channelControl(whichAxis).scaleType);
        elseif pointerLoc(1) <= 7 && pointerLoc(2) > 3
            % y axis on the left
            whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);            
            whichAxis = find([1 whereAt > cumsum(tempH.axisPortion(1:end-1))] & whereAt < cumsum(tempH.axisPortion), 1, 'first');    
            yCoord = (whereAt - sum(tempH.axisPortion(1:whichAxis - 1))) / tempH.axisPortion(whichAxis) * diff(get(tempH.axes(whichAxis),'Ylim')) + min(get(tempH.axes(whichAxis),'Ylim'));
            ylim = get(tempH.axes(whichAxis), 'ylim');
            
            % zoom                    
            set(tempH.channelControl(whichAxis).scaleType, 'value', 2);
            set(tempH.channelControl(whichAxis).minVal, 'string', sigPrint(yCoord - .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
            set(tempH.channelControl(whichAxis).maxVal, 'string', sigPrint(yCoord + .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
            newScale(tempH.channelControl(whichAxis).scaleType);  
            
            set(0, 'units', 'norm');
            figureNorm = hgconvertunits(handles.figure, figureLoc, get(handles.figure, 'units'), 'norm', 0);
            pointerNorm = hgconvertunits(handles.figure, [3.5 3 + (sum(tempH.axisPortion(1:whichAxis - 1)) + 0.5 * tempH.axisPortion(whichAxis)) * (figureLoc(4) - 4) 0 0], get(handles.figure, 'units'), 'norm', 0);
            set(0, 'units', 'norm', 'pointerLocation', figureNorm(1:2) + pointerNorm(1:2));
        elseif (pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43) && pointerLoc(2) > 3
            % y axis on the right
            whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);            
            whichAxis = find([1 whereAt > cumsum(tempH.axisPortion(1:end-1))] & whereAt < cumsum(tempH.axisPortion), 1, 'first');   
            yCoord = (whereAt - sum(tempH.axisPortion(1:whichAxis - 1))) / tempH.axisPortion(whichAxis) * diff(get(tempH.axes(whichAxis),'Ylim')) + min(get(tempH.axes(whichAxis),'Ylim'));            
            tempFields = fieldnames(tempH.analysisAxis{tempH.selectionAxis});
            if numel(tempFields) > 1
                % there exists at least one analysis axis, so zoom the
                % last one drawn
                axisHandle = tempH.analysisAxis{tempH.selectionAxis}.(tempFields{end});
                ylim = get(axisHandle, 'ylim');
                set(axisHandle, 'ylim', yCoord + [-.5 .5] .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount);                 
            else            
                ylim = get(tempH.axes(whichAxis), 'ylim');                
                set(tempH.channelControl(whichAxis).scaleType, 'value', 2);
                set(tempH.channelControl(whichAxis).minVal, 'string', sigPrint(yCoord - .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
                set(tempH.channelControl(whichAxis).maxVal, 'string', sigPrint(yCoord + .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
                newScale(tempH.channelControl(whichAxis).scaleType); 
            end
            
            set(0, 'units', 'norm');
            figureNorm = hgconvertunits(handles.figure, figureLoc, get(handles.figure, 'units'), 'norm', 0);
            pointerNorm = hgconvertunits(handles.figure, [figureLoc(3) - 45.5 3 + (sum(tempH.axisPortion(1:whichAxis - 1)) + 0.5 * tempH.axisPortion(whichAxis)) * (figureLoc(4) - 4) 0 0], get(handles.figure, 'units'), 'norm', 0);
            set(0, 'units', 'norm', 'pointerLocation', figureNorm(1:2) + pointerNorm(1:2));            
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) <= 1
            % scroll
            set(tempH.slider, 'value', max([min([get(tempH.slider, 'value') - varargin{2}.VerticalScrollCount * min(get(tempH.slider, 'sliderStep')) 1]) 0]));
            traceScroll;
            set(tempH.timeControl.autoScale, 'value', 0);
            set(tempH.timeControl.minVal, 'enable', 'on', 'string', sprintf('%5.2f', min(get(tempH.axes(1), 'xlim'))));
            set(tempH.timeControl.maxVal, 'enable', 'on', 'string', sprintf('%5.2f', max(get(tempH.axes(1), 'xlim'))));
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) <= 3            
            % zoom
            set(tempH.zoom, 'string', sprintf('%1.3f', str2double(get(tempH.zoom, 'string')) * 1.1 ^ -varargin{2}.VerticalScrollCount));
            traceScroll;
            set(tempH.timeControl.autoScale, 'value', 0);            
            set(tempH.timeControl.minVal, 'enable', 'on', 'string', sprintf('%5.2f', min(get(tempH.axes(1), 'xlim'))));
            set(tempH.timeControl.maxVal, 'enable', 'on', 'string', sprintf('%5.2f', max(get(tempH.axes(1), 'xlim'))));
        end
    end

    function updateTrace(scopeRef, axisNum)
    % update the traces   
        tempH = get(scopeRef, 'userData');
        if ischar(axisNum) && strcmp(axisNum, 'all')
            for outerLoop = 1:tempH.axesCount
                % delete analysis axes
                for i = fieldnames(tempH.analysisAxis{outerLoop})'
                    if ~strcmp(i{1}, 'None')
                        delete(tempH.analysisAxis{outerLoop}.(i{1}));
                        set(tempH.axes(outerLoop), 'color', [1 1 1]);
                    end
                end
                                
                % update the axis
                updateTrace(scopeRef, outerLoop);
                tempH.analysisAxis{outerLoop} = struct('None', []);
            end
            set(scopeRef, 'userData', tempH);
            return
        end        
        tempH.dataChanged(axisNum) = 0;
        set(0, 'currentFigure', scopeRef);
        set(scopeRef, 'currentAxes', tempH.axes(axisNum));

        % delete all of the children except the cursors
        kids = get(tempH.axes(axisNum), 'children');
        delete(kids(1:end - 2));
        if strcmp(get(tempH.channelControl(axisNum).channel, 'enable'), 'off')
            % the currently desired channel doesn't exist
            line('parent', tempH.axes(axisNum), 'xData', 0, 'yData', nan, 'color', [1 0 0], 'userData', 'data', 'displayName', 'Empty Trace');            
            return;
        end        
        set(kids(end - 1:end), 'visible', 'off');
        commandText = cell2mat(get(tempH.channelControl(axisNum).commandText, 'string'));  
        allData = yData{get(tempH.channelControl(axisNum).channel, 'value')};
        x = (xData(get(tempH.channelControl(axisNum).channel, 'value'), 1):xData(get(tempH.channelControl(axisNum).channel, 'value'), 2):xData(get(tempH.channelControl(axisNum).channel, 'value'), 3))';
        whichData = get(tempH.channelControl(axisNum).channel, 'value');
        
        % bring over the file names
        if exist('protocolData', 'var')
            % bring over the data
            artifactLength = get(tempH.displayBlankArtifacts, 'userData'); %ms

            % should the stimulus artifacts be blanked?
            if strcmp(get(tempH.displayBlankArtifacts, 'checked'), 'on') && artifactLength > 0
                for i = 1:numel(protocolData)
                    stimTimes = findStims(protocolData(i), 1);
                    for ttlIndex = 1:numel(protocolData(i).ttlEnable)
                        if ~isempty(stimTimes{ttlIndex})
                            stimTimes{ttlIndex}(:,2) = stimTimes{ttlIndex}(:,2) + artifactLength;            
                            for stimIndex = 1:size(stimTimes{ttlIndex}, 1)
                                if stimTimes{ttlIndex}(stimIndex, 1) >= size(allData, 2)
                                    allData(stimTimes{ttlIndex}(stimIndex, 1) * 1000 / protocolData(i).timePerPoint:round(min([stimTimes{ttlIndex}(stimIndex, 2) end]) * 1000 / protocolData(i).timePerPoint), i) = nan; %allData(stimTimes{ttlIndex}(stimIndex, 1), i);
                                end
                            end
                        end
                    end
                end
            end
            
            % setup commandText
            if ~isempty(strfind(commandText, 'ampNum'))
                ampNames = get(tempH.channelControl(axisNum).channel, 'string');
                ampSelection = get(tempH.channelControl(axisNum).channel, 'value');
                ampNum = double(ampNames{ampSelection}(5)) - 64;
            end    
        end

        % are they spike aligned?
        if strcmp(get(tempH.displayAligned, 'checked'), 'on')
            alignmentBounds = get(tempH.displayAligned, 'userData');    
            spikeData = yData{alignmentBounds(3)}(round(alignmentBounds(1) / tempH.xStep(alignmentBounds(3))):round(alignmentBounds(2) / tempH.xStep(alignmentBounds(3))), :);
            removedTraces = [];
            for i = 1:size(allData, 2)
                spikes = detectSpikes(spikeData(:,i));
                if isempty(spikes)
                    %disp(['No spikes in alignment interval for ' traceNames{i} '.  This trace will not be displayed'])
                    removedTraces(end + 1) = i;
                else
                    allData(:,i) = circshift(allData(:,i), [-fix(spikes(1) .* handles.xStep(alignmentBounds(3)) ./ handles.xStep(whichData)) 0]);
                    x = x - ((spikes(1) .* handles.xStep(alignmentBounds(3)) ./ handles.xStep(whichData) - fix(spikes(1) .* handles.xStep(alignmentBounds(3)) ./ handles.xStep(whichData)))).* handles.xStep(whichData); 
                end
            end
            allData(:, removedTraces) = [];
            tempH.dataChanged(axisNum) = 1;
        end

        % should we subtract a reference trace?
        if tempH.useReference(axisNum)
            refTrace = getappdata(tempH.axes(axisNum), 'referenceTrace');
            if strcmp(get(tempH.subtractRefTrace, 'check'), 'off')
                if get(tempH.channelControl(axisNum).offset, 'value')
                    if strcmp(get(tempH.displayAligned, 'checked'), 'on')
                        line('parent', tempH.axes(axisNum), 'xData', x, 'yData', [refTrace(1:min([end size(allData, 1)])); nan(size(allData, 1)-size(refTrace, 1),1)] - mean(refTrace(round(alignmentBounds(1) /tempH.xStep(whichData)) - 10:round(alignmentBounds(1) / tempH.xStep(whichData)))), 'color', [1 0 0], 'userData', 'data', 'displayName', ['Reference, ' getappdata(tempH.axes(axisNum), 'referenceName')]);
                    else
                        line('parent', tempH.axes(axisNum), 'xData', x, 'yData', [refTrace(1:min([end size(allData, 1)])); nan(size(allData, 1)-size(refTrace, 1),1)] - mean(refTrace(int32(max([0.2 min(get(tempH.axes(1), 'xlim'))])/tempH.xStep(whichData):min(get(tempH.axes(1), 'xlim'))/tempH.xStep(whichData) + 10))), 'color', [1 0 0], 'userData', 'data', 'displayName', ['Reference, ' getappdata(tempH.axes(axisNum), 'referenceName')]);
                    end
                else
                    line('parent', tempH.axes(axisNum), 'xData', x, 'yData', [refTrace(1:min([end size(allData, 1)])); nan(size(allData, 1)-size(refTrace, 1),1)], 'color', [1 0 0], 'userData', 'data', 'displayName', ['Reference, ' getappdata(tempH.axes(axisNum), 'referenceName')]);
                end
            else
                if size(allData, 1) == length(refTrace)
                    allData(1:size(refTrace, 1), :) = allData(1:size(refTrace, 1), :) - repmat(refTrace, 1, size(allData, 2));
                    tempH.dataChanged(axisNum) = 1;
                end
            end
        end

        % cycle through zData and pull out the correct traces
        tempEvents = getappdata(gca, 'events');
        meanBounds = int32(max([1 fix((min(get(tempH.axes(1), 'xlim')) - tempH.minX(whichData)) / tempH.xStep(whichData))]) + (1:min([10 diff(get(tempH.axes(1), 'xlim')) / tempH.xStep(whichData)])));
        if strcmp(get(tempH.displayTraces, 'checked'), 'on')
            if strcmp(get(tempH.colorCoded, 'checked'), 'on')
                colors = colorSpread(size(allData, 2));
                if isempty(findobj(tempH.figure, 'tag', 'colorLegend'))
                    % generate a menu that is a color-coding legend
                    mnuHandle = uimenu(tempH.figure, 'Label', 'Color Codes', 'tag', 'colorLegend');
                    for i = 1:size(allData, 2)
                        uimenu(mnuHandle, 'foregroundColor', colors(i,:), 'Label', traceNames{i});
                    end
                end
            else
                colors = repmat([0 0 0], size(allData, 2), 1);
                delete(findobj(tempH.figure, 'tag', 'colorLegend'));
            end
            for i = 1:size(allData, 2)
                % evaluate command on trace if necessary
                if ~isempty(commandText)
                    if isempty(strfind(commandText, 'allData'))
                        if ~isempty(strfind(commandText, 'protocol')) && exist('protocolData', 'var')
                            protocol = protocolData(i);
                        end                
                        data = allData(:,i);
                        events = [];
                        try
                            set(tempH.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData))));
                        catch
                            % not apparently something that returns a value
                            try
                                eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData)));                                
                            catch
                                warning('Function failure in command box');
                                set(tempH.channelControl(axisNum).resultText, 'string', '');
                            end
                        end
                        try
                            if any(allData(:,i) ~= data)
                                tempH.dataChanged(axisNum) = 1;
                            end
                            allData(:,i) = data;
                        catch
                            warning(['Modified trace has dimensions [' num2str(size(data)) '], but should have dimensions [' num2str(size(allData, 1)) ' 1], so the trace was not modified']);
                        end
                        
                        if ~isempty(events)
                            if isvector(events)
                                tempEvents(end + 1).type = 'Undefined';
                                tempEvents(end).traceName = traceNames{i};
                                tempEvents(end).data = events;
                            else
                                tempEvents(end + 1) = events;
                            end
                        end					
                    elseif i == 1
                        % only allow statement which act on allData to act once
                        if ~isempty(strfind(commandText, 'protocol')) && exist('protocolData', 'var')
                            protocol = protocolData;
                        end
                        try
                            set(tempH.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData))));
                        catch
                            % not apparently something that returns a value
                            try
                                eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData)));                                
                            catch
                                warning('Function failure in command box');
                                set(tempH.channelControl(axisNum).resultText, 'string', '');
                            end
                        end
                    end
                end

                % display the data trace
                if get(tempH.channelControl(axisNum).offset, 'value')
                    if strcmp(get(tempH.displayAligned, 'checked'), 'on')
                        line('parent', tempH.axes(axisNum), 'xData', x, 'yData', allData(:,i) - mean(allData(round(alignmentBounds(1) / tempH.xStep(whichData)) - 10:round(alignmentBounds(1) / tempH.xStep(whichData)), i), 1), 'color', colors(i,:), 'userData', 'data', 'displayName', traceNames{i});                
                    else
                        line('parent', tempH.axes(axisNum), 'xData', x, 'yData', allData(:,i) - mean(allData(meanBounds, i), 1), 'color', colors(i,:), 'userData', 'data', 'displayName', traceNames{i});
                    end
                    tempH.dataChanged(axisNum) = 1;
                else
                    line('parent', tempH.axes(axisNum), 'xData', x, 'yData', allData(:,i), 'color', colors(i,:), 'userData', 'data', 'displayName', traceNames{i});
                end
            end
        end

        if strcmp(get(tempH.displayMean, 'checked'), 'on')            
            % find the mean
            data = mean(allData, 2);
            events = [];

            % evaluate command on trace if necessary
            if ~tempH.dataChanged(axisNum) % only process mean trace if individual traces were not altered
                commandText = cell2mat(get(tempH.channelControl(axisNum).commandText, 'string'));
                if ~isempty(commandText)     
                    if ~isempty(strfind(commandText, 'protocol')) && exist('protocolData', 'var')
                        protocol = protocolData(1);
                    end                
                    try
                        % if this modifies the data and the traces are not
                        % being displayed then the dataChanged flag will be
                        % wrong
                        set(tempH.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData))));
                    catch
                        try
                            eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData)));                                
                        catch
                            warning('Function failure in command box');
                            set(tempH.channelControl(axisNum).resultText, 'string', '');
                        end
                    end
                    if ~isempty(events)
                        if isvector(events)
                            tempEvents(end + 1).type = 'Undefined';
                            tempEvents(end).traceName = ['Mean, ' get(tempH.figure, 'name')];
                            tempEvents(end).data = events;
                        else
                            tempEvents(end + 1) = events;
                        end
                    end					
                end
            end

            % display the mean trace
            tempHandles = get(tempH.displayMean, 'userData');
            if get(tempH.channelControl(axisNum).offset, 'value')
                if strcmp(get(tempH.displayAligned, 'checked'), 'on')
                    tempHandles(axisNum) = line('parent', tempH.axes(axisNum), 'xData', x, 'yData', data - mean(data(round(alignmentBounds(1) / tempH.xStep(whichData)) - 10:round(alignmentBounds(1) / tempH.xStep(whichData)))), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Mean, ' get(tempH.figure, 'name')]);
                else
                    tempHandles(axisNum) = line('parent', tempH.axes(axisNum), 'xData', x, 'yData', data - mean(data(meanBounds), 1), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Mean, ' get(tempH.figure, 'name')]);
                end
                tempH.dataChanged(axisNum) = 1;
            else
                tempHandles(axisNum) = line('parent', tempH.axes(axisNum), 'xData', x, 'yData', data, 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Mean, ' get(tempH.figure, 'name')]);
            end
            set(tempH.displayMean, 'userData', tempHandles);      
        end

        if strcmp(get(tempH.displayMedian, 'checked'), 'on')     
            data = median(allData, 2);
            events = [];

            % evaluate command on trace if necessary
            commandText = cell2mat(get(tempH.channelControl(axisNum).commandText, 'string'));
            if ~isempty(commandText)     
                if ~isempty(strfind(commandText, 'protocol')) && exist('protocolData', 'var')
                    protocol = protocolData(1);
                end                
                try
                    % if this modifies the data and the traces are not
                    % being displayed then the dataChanged flag will be
                    % wrong                    
                    set(tempH.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData))));
                catch
                    try
                        eval(msec2point(commandText, 1 / tempH.xStep(whichData), tempH.minX(whichData)));                                
                    catch
                        warning('Function failure in command box');
                        set(tempH.channelControl(axisNum).resultText, 'string', '');
                    end
                end
                if ~isempty(events)
                    if isvector(events)
                        tempEvents(end + 1).type = 'Undefined';
                        tempEvents(end).traceName = ['Median, ' get(tempH.figure, 'name')];
                        tempEvents(end).data = events;
                    else
                        tempEvents(end + 1) = events;
                    end
                end					
            end

            % display the median trace
            tempHandles = get(tempH.displayMedian, 'userData');
            if get(tempH.channelControl(axisNum).offset, 'value')
                if strcmp(get(tempH.displayAligned, 'checked'), 'on')
                    tempHandles(axisNum) = line('parent', tempH.axes(axisNum), 'xData', x, 'yData', data - mean(data(round(alignmentBounds(1) / tempH.xStep(whichData)) - 10:round(alignmentBounds(1) / tempH.xStep(whichData)))), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Median, ' get(tempH.figure, 'name')]);
                else
                    tempHandles(axisNum) =  line('parent', tempH.axes(axisNum), 'xData', x, 'yData', data - mean(data(meanBounds), 1), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Median, ' get(tempH.figure, 'name')]);
                end
                tempH.dataChanged(axisNum) = 1;
            else
                tempHandles(axisNum) = line('parent', tempH.axes(axisNum), 'xData', x, 'yData', data, 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Median, ' get(tempH.figure, 'name')]);
            end
            set(tempH.displayMedian, 'userData', tempHandles);
            if strfind(commandText, 'events')
                setappdata(tempH.axes(axisNum), 'events', tempEvents);
            end	            
        end

        setappdata(tempH.axes(axisNum), 'events', tempEvents);
        if strcmp(get(tempH.displayEvents, 'checked'), 'on')
            showEvents(tempH.axes(axisNum));
        end
        if strcmp(get(tempH.displayBlankArtifacts, 'checked'), 'on')
            showStims(tempH.figure);
        end
        if isappdata(0, 'imageBrowser')
            showFrameMarker(tempH.axes(axisNum));
        end

        % set the cursors to the right height
        set(kids(end), 'visible', 'on', 'ydata', get(tempH.axes(axisNum), 'ylim'));  
        if tempH.markerFixed == 0
            set(kids(end - 1), 'visible', 'off', 'ydata', get(tempH.axes(axisNum), 'ylim'));  
        else
            set(kids(end - 1), 'visible', 'on', 'ydata', get(tempH.axes(axisNum), 'ylim'));  
        end
        try
            newScale(tempH.channelControl(axisNum).scaleType);
        catch
            warning('Error in rescaling')
        end
        % make sure that the cursors are not off of the scale
        if get(kids(end - 1), 'xdata') > max(get(tempH.axes(axisNum), 'xlim'))
            set(kids(end - 1), 'xdata', [0 0]);
            tempH.markerLoc = 0; % index into y-data of the reference line
            tempH.markerTime = 0; % time of the reference line
            tempH.markerFixed = 0; % if the reference line is present
        end
        if get(kids(end), 'xdata') > max(get(tempH.axes(axisNum), 'xlim'))
            set(kids(end), 'xdata', [0 0]);
        end
        set(scopeRef, 'userData', tempH);
    end

    function characterizeExperiment(varargin)
        if exist('protocolData', 'var')
            lineHandles = get(gca, 'children');
            lineHandles = lineHandles(strcmp(get(lineHandles, 'userData'), 'data'));
            eventFunction = get(varargin{1}, 'userData');

            % determine which amp we are on
            handles = get(gcf, 'userData');
            axisNum = find(handles.axes == gca);
            ampNames = get(handles.channelControl(axisNum).channel, 'string');
            ampSelection = get(handles.channelControl(axisNum).channel, 'value');
            ampNum = double(ampNames{ampSelection}(5)) - 64;
            stringData = {};
            for handleIndex = 1:numel(lineHandles)
                data = get(lineHandles(numel(lineHandles) + 1 - handleIndex), 'yData');
                stringData{end + 1} = eventFunction(data', protocolData(handleIndex), ampNum, gca);
            end
            disp([func2str(eventFunction) '(data, protocol, ' num2str(ampNum) ', gca);'])
            set(get(gca, 'userdata'), 'string', stringData);
        end
    end

    function printMontage(varargin)
    % it is a known issue that cancelling printing only cancels the first page.
    % however, print does not return anything from a .p file to indicate that
    % printing was cancelled and feature('NewPrintAPI') is false so no
    % multipage output is allowed

        handles = get(gcf, 'userData');
        haveSetup = 0;
        if ispref('newScope', 'printInformation') && ~isempty(getpref('newScope', 'printInformation'))
            printInformation = getpref('newScope', 'printInformation');
        else
            printInformation = '{[traceName '', '' channelName], [protocol.ampCellLocationName{ampNum}, '', Drug: '' protocol.drug '', V = '' sprintf(''%1.1f'', protocol.startingValues(find(cellfun(@(x) x(end) == ''V'' && ~isempty(strfind(x, [''Amp '' char(64 + ampNum)])) && isempty(strfind(x, ''Stim'')), protocol.channelNames)))) '', I = '' sprintf(''%1.1f'', protocol.startingValues(find(cellfun(@(x) x(end) == ''I'' && ~isempty(strfind(x, [''Amp '' char(64 + ampNum)])) && isempty(strfind(x, ''Stim'')), protocol.channelNames))))]}';
        end

        for axesIndex = 1:handles.axesCount
            % look at first axis to see how many traces are displayed
            kids = get(handles.axes(axesIndex), 'children');
            dataTraces = kids(strcmp(get(kids, 'userData'), 'data'));
            channelName = get(handles.channelControl(axesIndex).channel, 'string');
            channelName = channelName{get(handles.channelControl(axesIndex).channel, 'value')};
            ampNum = int8(sscanf(channelName, 'Amp %c')) - 64;

            switch length(dataTraces)
                case 1
                    % print two on top of each other
                    figHandle = figure('visible', 'off', 'inverthardcopy', 'off', 'color', [1 1 1], 'paperorientation', 'landscape', 'numbertitle', 'off', 'paperposition', [.25 .25 10.5 8]);
                    newHandle = get(copyobj(dataTraces(1), axes), 'parent');
                    set(gca, 'ylim', get(handles.axes(axesIndex), 'ylim'));
                    % copy over any associated analysis objects
                    printData = '';
                    traceName = get(dataTraces(1), 'displayName');
                    for handleIndex = kids'
                       if (strcmp(get(handleIndex, 'displayName'), traceName) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                           copyobj(handleIndex, gca);
                           if isappdata(handleIndex, 'printData')
                               printData = [printData '; ' getappdata(handleIndex, 'printData')];
                           end
                       end
                    end
                    if exist('protocolData', 'var')
                        protocol = protocolData(1);
                    end
                    try
                        titleData = eval(printInformation);
                        titleData{end} = [titleData{end} printData];
                        title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    catch
                        title(traceName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    end
                    prepForPrint(channelName(end));
                    % copy over any analysis axes
                    analysisAxes = fieldnames(handles.analysisAxis{axesIndex});
                    if numel(analysisAxes) > 1
                        for j = 2:numel(analysisAxes)
                            tempHandle = copyobj(handles.analysisAxis{axesIndex}.(analysisAxes{j}), figHandle);
                            set(tempHandle, 'color', 'none', 'ycolor', [1 1 1], 'xcolor', [1 1 1], 'units', get(newHandle, 'units'), 'position', get(newHandle, 'position'));
                            prepForPrint(tempHandle, get(get(handles.analysisAxis{axesIndex}.(analysisAxes{axesIndex}{j}), 'ylabel'), 'string'), 'yOnly')
                            kidKids = get(tempHandle, 'children');
                            delete(kidKids(3));
                            set(kidKids(1:2), 'color', get(kidKids(4), 'color'));
                        end
                    end

                    if isdeployed
                        deployprint('-noui');
                    else
                        print('-v', ['-f' num2str(figHandle)]);
                    end
                    close(figHandle);
                case 2
                    % print two on top of each other
                    figHandle = figure('visible', 'off', 'inverthardcopy', 'off', 'color', [1 1 1], 'paperorientation', 'portrait', 'numbertitle', 'off', 'paperposition', [.25 .25 8 10.5]);
                    newHandle = get(copyobj(dataTraces(1), subplot(2,1,2)), 'parent');
                    set(gca, 'ylim', get(handles.axes(axesIndex), 'ylim'));
                    % copy over any associated analysis objects
                    printData = '';
                    traceName = get(dataTraces(1), 'displayName');
                    for handleIndex = kids'
                       if (strcmp(get(handleIndex, 'displayName'), traceName) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                           copyobj(handleIndex, gca);
                           if isappdata(handleIndex, 'printData')
                               printData = [printData '; ' getappdata(handleIndex, 'printData')];
                           end
                       end
                    end
                    if exist('protocolData', 'var')
                        protocol = protocolData(1);
                    end
                    try
                        titleData = eval(printInformation);
                        titleData{end} = [titleData{end} printData];
                        title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    catch
                        title(traceName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    end
                    prepForPrint(channelName(end));
                    % copy over any analysis axes
                    analysisAxes = fieldnames(handles.analysisAxis{axesIndex});
                    if numel(analysisAxes) > 1
                        for j = 2:numel(analysisAxes)
                            tempHandle = copyobj(handles.analysisAxis{axesIndex}.(analysisAxes{j}), figHandle);
                            set(tempHandle, 'color', 'none', 'ycolor', [1 1 1], 'xcolor', [1 1 1], 'units', get(newHandle, 'units'), 'position', get(newHandle, 'position'));
                            prepForPrint(tempHandle, get(get(handles.analysisAxis{axesIndex}.(analysisAxes{axesIndex}{j}), 'ylabel'), 'string'), 'yOnly')
                            kidKids = get(tempHandle, 'children');
                            delete(kidKids(3));
                            set(kidKids(1:2), 'color', get(kidKids(4), 'color'));
                        end
                    end

                    newHandle = get(copyobj(dataTraces(2), subplot(2,1,1)), 'parent');
                    set(gca, 'ylim', get(handles.axes(axesIndex), 'ylim'));
                    % copy over any associated analysis objects
                    printData = '';
                    traceName = get(dataTraces(2), 'displayName');
                    for handleIndex = kids'
                       if (strcmp(get(handleIndex, 'displayName') , traceName) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                           copyobj(handleIndex, gca);
                           if isappdata(handleIndex, 'printData')
                               printData = [printData '; ' getappdata(handleIndex, 'printData')];
                           end
                       end
                    end
                    if exist('protocolData', 'var')
                        protocol = protocolData(2);
                    end
                    try
                        titleData = eval(printInformation);
                        titleData{end} = [titleData{end} printData];
                        title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    catch
                        title(traceName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    end
                    prepForPrint(channelName(end));
                    % copy over any analysis axes
                    analysisAxes = fieldnames(handles.analysisAxis{axesIndex});
                    if numel(analysisAxes) > 1
                        for j = 2:numel(analysisAxes)
                            tempHandle = copyobj(handles.analysisAxis{axesIndex}.(analysisAxes{j}), figHandle);
                            set(tempHandle, 'color', 'none', 'ycolor', [1 1 1], 'xcolor', [1 1 1], 'units', get(newHandle, 'units'), 'position', get(newHandle, 'position'));
                            prepForPrint(tempHandle, get(get(handles.analysisAxis{axesIndex}.(analysisAxes{axesIndex}{j}), 'ylabel'), 'string'), 'yOnly')
                            kidKids = get(tempHandle, 'children');
                            delete(kidKids(4));
                            set(kidKids(1:2), 'color', get(kidKids(3), 'color'));
                        end
                    end
                    if isdeployed
                        deployprint('-noui');
                    else
                        print('-v', ['-f' num2str(figHandle)]);
                    end
                    close(figHandle);
                otherwise
                    % quad print
                    figHandle = figure('visible', 'off', 'inverthardcopy', 'off', 'color', [1 1 1], 'paperorientation', 'landscape', 'numbertitle', 'off', 'paperposition', [.25 .25 10.5 8]);
                    plotNum = 1;
                    for i = numel(dataTraces):-1:1
                        newHandle = get(copyobj(dataTraces(i), subplot(2,2,plotNum)), 'parent');
                        set(newHandle, 'ylim', get(handles.axes(axesIndex), 'ylim'));

                        % add an offset label
                        offsetData = mean(yData{get(handles.channelControl(axesIndex).channel, 'value')}(find(yData{get(handles.channelControl(axesIndex).channel, 'value')}(:, numel(dataTraces) + 1 - i), 10, 'first'), numel(dataTraces) + 1 - i));
                        switch channelName(end)
                            case {'V', 'F'}
                                switch 1
                                    case abs(offsetData) >= 1000
                                        yLabel = [sprintf('%0.0f', offsetData / 1000) ' V   '];
                                    case abs(offsetData) >= 1
                                        yLabel = [sprintf('%0.0f', offsetData) ' mV   '];
                                    otherwise
                                        yLabel = [sprintf('%0.0f', offsetData * 1000) ' ' char(181) 'V   '];
                                end
                            case 'I'
                                switch 1
                                    case abs(offsetData) >= 1000000
                                        yLabel = [sprintf('%0.0f', offsetData / 1000000) ' ' char(181) 'A   '];
                                    case abs(offsetData) >= 1000
                                        yLabel = [sprintf('%0.0f', offsetData / 1000) ' nA   '];
                                    case abs(offsetData) >= 1
                                        yLabel = [sprintf('%0.0f', offsetData) ' pA   '];
                                    otherwise
                                        yLabel = [sprintf('%0.0f', offsetData * 1000) ' fA   '];
                                end
                            otherwise
                                yLabel = sprintf('%0.0f', offsetData);
                        end
                        text(min(get(newHandle, 'xlim')), offsetData, yLabel, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'parent', newHandle, 'fontsize', 8);
                        traceName = get(dataTraces(i), 'displayName');

                        printData = '';
                        % copy over any associated analysis objects
                        for handleIndex = kids'
                           if (strcmp(get(handleIndex, 'displayName'), traceName) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                               copyobj(handleIndex, newHandle);
                               if isappdata(handleIndex, 'printData')
                                   printData = [printData '; ' getappdata(handleIndex, 'printData')];
                               end
                           end
                        end
                        if exist('protocolData', 'var')
                            protocol = protocolData(i);
                        end
                        try
                            titleData = eval(printInformation);
                            titleData{end} = [titleData{end} printData];
                            title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                        catch
                            title(traceName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                        end
                        set(newHandle, 'xtick', [], 'xticklabel', '', 'ytick', [], 'yticklabel', '', 'box', 'off', 'xColor', [1 1 1], 'yColor', [1 1 1]);

                        plotNum = plotNum + 1;
                        if plotNum == 5
                            plotNum = 1;
                            prepForPrint(channelName(end));
                            if isdeployed
                                deployprint;
                            elseif ~haveSetup
                                print('-v', ['-f' num2str(figHandle)]);
                                haveSetup = 1;
                            else
                                print(['-f' num2str(figHandle)]);
                            end
                            close(figHandle);
                            figHandle = figure('visible', 'off', 'inverthardcopy', 'off', 'color', [1 1 1], 'paperorientation', 'landscape', 'numbertitle', 'off', 'paperposition', [.25 .25 10.5 8]);
                        end
                    end
                    if plotNum ~= 1
                        prepForPrint(channelName(end));
                        if isdeployed
                            deployprint;
                        elseif ~haveSetup
                            print('-v', ['-f' num2str(figHandle)]);
                            haveSetup = 1;
                        else
                            print(['-f' num2str(figHandle)]);
                        end
                    end
                    close(figHandle);
            end
        end
    end
end

function windowKeyPress(varargin)
    if isappdata(0, 'fileBrowser') && (strcmp(varargin{2}.Key, 'uparrow') || strcmp(varargin{2}.Key, 'downarrow'))
        handles = get(getappdata(0, 'fileBrowser'), 'userData');
        currentEvent = handles{4}.getSelectedRow;
        if strcmp(varargin{2}.Key, 'downarrow') && currentEvent < handles{4}.getRowCount - 1
            handles{4}.setRowSelectionInterval(currentEvent + 1, currentEvent + 1);                
        elseif strcmp(varargin{2}.Key, 'uparrow') && currentEvent > 0
            handles{4}.setRowSelectionInterval(currentEvent - 1, currentEvent - 1);
        end
        keyFcn = get(handles{4}, 'KeyReleasedCallback');
        keyFcn(0, java.awt.event.KeyEvent(handles{4}, 0, 0, 0, 38, char(38)));
    end
end

function traceScroll(varargin)
    handles = get(gcf, 'userData');
    zoomFactor = str2double(get(handles.zoom, 'string'));
    if zoomFactor < 1
        set(handles.zoom, 'string', '1');
        zoomFactor = 1;
    end
    scrollValue = get(handles.slider, 'value') * (1- 1 / zoomFactor);

    windowSize = (max(handles.maxX) - min(handles.minX)) / zoomFactor;
    newStep = 1 / zoomFactor / (1- 1 / zoomFactor);
    if newStep > 10
        set(handles.slider, 'sliderStep', [1 newStep]);
    else
        set(handles.slider, 'sliderStep', [newStep / 10 newStep]);
    end
    set(handles.axes, 'Xlim', [(max(handles.maxX) - min(handles.minX)) * scrollValue + min(handles.minX) (max(handles.maxX) - min(handles.minX))* scrollValue + windowSize + min(handles.minX)], 'dataaspectratiomode', 'auto', 'plotboxaspectratiomode', 'auto');
	setAxisLabels(handles.axes(1));
end

function resize(varargin)
    handles = get(varargin{1}, 'userData');
    figPos = get(varargin{1}, 'position');
    set(handles.timeControl.frame, 'position', [figPos(3) - 43 figPos(4) - 5 - handles.axesCount * 14 42 5]);
    set(handles.traceName, 'position', [7 figPos(4) - 1, figPos(3) - 55, 1]);
    set(handles.slider, 'position', [0 0 figPos(3) 1]);
    set(handles.zoom, 'position', [0 1 8 1]);
    for i = 1:handles.axesCount
        set(handles.axes(i), 'position', [7 3 + sum(handles.axisPortion(1:i - 1)) * (figPos(4) - 4) figPos(3) - 55 handles.axisPortion(i) * (figPos(4) - 4)]);

        % resize analysisAxes
        whichFields = fieldnames(handles.analysisAxis{i});
        whichFields = whichFields(~strcmp(whichFields, 'None'));
        for j = 1:numel(whichFields)
            set(handles.analysisAxis{i}.(whichFields{j}), 'position', [7 3 + sum(handles.axisPortion(1:i - 1)) * (figPos(4) - 4) figPos(3) - 55 handles.axisPortion(i) * (figPos(4) - 4)]);
        end

        set(handles.channelControl(i).frame, 'position', [figPos(3) - 43 figPos(4) - 14 - (handles.axesCount - i) * 14 42 13]);
        if i > 1
            set(handles.axes(i), 'xticklabel', '', 'xtick', []);
        else
            set(handles.axes(i), 'xtickmode', 'auto', 'xticklabelmode', 'auto');
			setAxisLabels(handles.axes(i));
        end
    end
end

function closeScope(varargin)
    handles = getappdata(0, 'scopes');
    if length(handles) > 1
        whichScope = find(handles == varargin{1});
        if ~isempty(whichScope)
            setappdata(0, 'scopes', handles([1:whichScope - 1 whichScope + 1:end]));
        end
    else
        if any(handles == varargin{1})
            rmappdata(0, 'scopes');
        end
    end
    delete(varargin{1})
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Begin Menubar Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function printInformation(varargin)
	% set what information is added to plots
	if ~ispref('newScope', 'printInformation')
		setpref('newScope', 'printInformation', '{[traceName '', '' channelName], [''Drug: '' protocol.drug]}')
	end

	printInformation = inputdlg('What would you like to include in the printings?  ''titleData'' refers to data set aside by analysis functions for printing.', 'Montage Print Title', 1, {getpref('newScope', 'printInformation')});

    if numel(printInformation)
		setpref('newScope', 'printInformation', printInformation{1});
    end
end

function addChannel(varargin)
    handles = get(ancestor(varargin{1}, 'figure'), 'userData');
    if strcmp(get(varargin{1}, 'type'), 'uimenu')
        afterWhich = handles.axesCount;
    else
        afterWhich = find(handles.axes == gca);
    end
    handles.axesCount = handles.axesCount + 1;
    handles.channelControl(afterWhich + 1:handles.axesCount) = handles.channelControl(afterWhich:handles.axesCount - 1);
    handles.axes(afterWhich + 1:handles.axesCount) = handles.axes(afterWhich:handles.axesCount - 1);
    handles.channelControl(afterWhich) = eval(handles.channelControlFunction);
	set(handles.channelControl(afterWhich).channel, 'userData', get(handles.channelControl(afterWhich + 1).channel, 'userData'));
    handles.useReference(afterWhich + 1:handles.axesCount) = handles.useReference(afterWhich:handles.axesCount - 1);
    handles.useReference(afterWhich) = 0;
    handles.dataChanged(afterWhich + 1:handles.axesCount) = handles.dataChanged(afterWhich:handles.axesCount - 1);
    if strcmp(get(handles.displayMean, 'checked'), 'on')
        tempHandles = get(handles.displayMean, 'userData'); 
        set(handles.displayMean, 'userData', [tempHandles(1:afterWhich - 1) nan tempHandles(afterWhich:end)]);
    end
    if strcmp(get(handles.displayMedian, 'checked'), 'on')
        tempHandles = get(handles.displayMedian, 'userData'); 
        set(handles.displayMedian, 'userData', [tempHandles(1:afterWhich - 1) nan tempHandles(afterWhich:end)]);
    end    
    set(handles.channelControl(afterWhich).channel, 'string', get(handles.channelControl(afterWhich + 1).channel, 'string'));
    set(handles.channelControl(afterWhich).channel, 'value', get(handles.channelControl(afterWhich + 1).channel, 'value'));

    % copy analysis axes
    handles.analysisAxis(afterWhich + 1:handles.axesCount) = {handles.analysisAxis{afterWhich:handles.axesCount - 1}};
    handles.analysisAxis{afterWhich} = struct('None', []);
    whichFields = fieldnames(handles.analysisAxis{afterWhich + 1});
    whichFields = whichFields(~strcmp(whichFields, 'None'));
    for i = 1:numel(whichFields)
        handles.analysisAxis{afterWhich}.(whichFields{i}) = copyobj(handles.analysisAxis{afterWhich + 1}.(whichFields{i}), gcf);
    end

    handles.axes(afterWhich) = copyobj(handles.axes(afterWhich + 1), gcf);
    set(handles.axes(afterWhich), 'userData', handles.channelControl(afterWhich).resultText);
    set(handles.channelControl(afterWhich).frame, 'userData', handles.axes(afterWhich));
    if handles.axesCount == 2
        handles.axisPortion(afterWhich) = .5;
        handles.axisPortion(afterWhich + 1) = .5;
    elseif afterWhich == handles.axesCount - 1
        handles.axisPortion = handles.axisPortion * (handles.axesCount - 1) / handles.axesCount;
        handles.axisPortion(handles.axesCount) = mean(handles.axisPortion(1:handles.axesCount - 1));
    else
        handles.axisPortion(afterWhich + 1:handles.axesCount) = handles.axisPortion(afterWhich:handles.axesCount - 1) * (handles.axesCount - 1) / handles.axesCount;
        handles.axisPortion(afterWhich) = mean(handles.axisPortion([1:afterWhich - 1 afterWhich + 1:handles.axesCount - 1]));
    end
    set(gcf, 'userdata', handles);
    resize(gcf, []);
    feval(getappdata(handles.figure, 'updateFunction'), handles.figure, afterWhich);
end

function removeChannel(varargin)
    handles = get(gcf, 'userData');
    whichChan = find(handles.axes == gca);
    if handles.axesCount > 1 % don't let it go down to zero
        handles.axesCount = handles.axesCount - 1;
        delete(handles.channelControl(whichChan).frame);
        delete(handles.axes(whichChan))

        whichFields = fieldnames(handles.analysisAxis{whichChan});
        whichFields = whichFields(~strcmp(whichFields, 'None'));
        for i = 1:numel(whichFields)
            delete(handles.analysisAxis{whichChan}.(whichFields{i}));
        end

        handles.channelControl = handles.channelControl([1:whichChan - 1 whichChan + 1:handles.axesCount + 1]);
        handles.axes = handles.axes([1:whichChan - 1 whichChan + 1:handles.axesCount + 1]);
        handles.useReference = handles.useReference([1:whichChan - 1 whichChan + 1:handles.axesCount + 1]);
        handles.dataChanged = handles.dataChanged([1:whichChan - 1 whichChan + 1:handles.axesCount + 1]);        
        handles.analysisAxis = handles.analysisAxis([1:whichChan - 1 whichChan + 1:handles.axesCount + 1]);
        if strcmp(get(handles.displayMean, 'checked'), 'on')
            tempHandles = get(handles.displayMean, 'userData'); 
            set(handles.displayMean, 'userData', tempHandles([1:whichChan - 1 whichChan + 1:end]));
        end
        if strcmp(get(handles.displayMedian, 'checked'), 'on')
            tempHandles = get(handles.displayMedian, 'userData'); 
            set(handles.displayMedian, 'userData', tempHandles([1:whichChan - 1 whichChan + 1:end]));
        end        
        if handles.axesCount == 1
            handles.axisPortion(1) = 1;
        else
            % just maintain proportions of other axes
            handles.axisPortion([1:whichChan - 1 whichChan + 1:end]) = handles.axisPortion([1:whichChan - 1 whichChan + 1:end]) ./ sum(handles.axisPortion([1:whichChan - 1 whichChan + 1:end]));
            handles.axisPortion(whichChan) = [];
            % maintain size of all but one axis
%             if whichChan == handles.axesCount + 1
%                 handles.axisPortion(handles.axesCount) = handles.axisPortion(handles.axesCount) + handles.axisPortion(handles.axesCount + 1);
%             else
%                 handles.axisPortion(whichChan + 1) = handles.axisPortion(whichChan + 1) + handles.axisPortion(whichChan);
%                 handles.axisPortion(whichChan:handles.axesCount) = handles.axisPortion(whichChan + 1:handles.axesCount + 1);
%             end
        end
        if handles.selectionAxis == whichChan
            handles.selectionAxis = 1;
        end
        set(gcf, 'userdata', handles);
        resize(gcf, []);
    end
end

function showPlotBrowser(varargin)
    % show or hide the plot browser docker
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1},'checked','off');
    else
        set(varargin{1},'checked','on');
    end
    plotbrowser(get(varargin{1}, 'checked'));
    set(gcf, 'toolbar', 'none');
end

function exportToWorkspace(varargin)
persistent dataName

if isempty(dataName)
    dataName = 'data';
end

    lineKids = get(gca, 'children');
    lineKids = lineKids(strcmp(get(lineKids, 'userData'), 'data'),:);
    switch mod(varargin{3}, 8)
        case 0 % data
            xData = get(lineKids(1), 'yData')';
            xData(end, numel(lineKids)) = xData(end, 1); % preassign the array
            for i = 2:numel(lineKids)
                xData(:,i) = get(lineKids(i), 'yData')';
            end            
        case 1 % time
            xData = get(lineKids(1), 'xData')';
        case 2 % names
            xData = get(lineKids, 'displayName');
        case 3 % short names
            xData = get(lineKids, 'displayName');
            if iscell(xData)
                xData = cellfun(@(x) x(find(x == filesep, 1, 'last') + 1:end - 4), xData, 'UniformOutput', 0);
            else
                xData = xData(find(xData == filesep, 1, 'last') + 1:end - 4);
            end
    end
    if varargin{3} > 7
        clipText = '';
        if iscell(xData)
            % names
            for i = 1:numel(xData)
                clipText = [clipText xData{i} char(9)];
            end
        elseif ischar(xData)
            clipText = xData;
        else
            for i = 1:size(xData, 1)
                clipText = [clipText sprintf('%g\t', xData(i,:)) char(13)];
            end
        end
        clipboard('copy', clipText);
    else
        varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, {''});
        if ~isempty(varName)
            dataName = varName{1};
            tempVarName = genvarname(dataName, evalin('base', 'who'));
            if strcmp(dataName, tempVarName)
                assignin('base', dataName, xData);
            elseif findstr(dataName, tempVarName) == 1 && size(xData, 1) == evalin('base', ['size(' dataName ', 1)'])
                switch questdlg(strcat('Add to existing variable?'), 'Uh oh');
                    case 'Yes'
                        assignin('base', varName{1}, [evalin('base', dataName) xData]);
                    case 'No'
                        % do nothing
                    case 'Cancel'
                        % do nothing
                end
            else
                switch questdlg(strcat('''', dataName, ''' is not a valid variable name in the base workspace.  Is ''', tempVarName, ''' ok?'), 'Uh oh');
                    case 'Yes'
                        assignin('base', tempVarName, xData);
                    case 'No'
                        varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, tempVarName);
                        assignin('base', genvarname(varName{1}), xData);
                    case 'Cancel'
                        % do nothing
                end
            end
        end
    end
end

function setDisplay(varargin)
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1}, 'checked', 'off');
    else
        set(varargin{1}, 'checked', 'on');
    end
    feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), 'all');
end

function setCursors(varargin)
    handles = get(gcf, 'userData');
    newState = cell2mat(setdiff({'on', 'off'}, get(varargin{1}, 'checked')));
    set(varargin{1}, 'checked', newState);
    for i = handles.axes
        axisKids = get(i, 'children');
        set(axisKids(end - 1:end), 'visible', newState);
    end
end

function setDisplayAligned(varargin)
    persistent lastValues
    if isempty(lastValues)
        lastValues = [100 200 1];
    end
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1}, 'checked', 'off');
        feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), 'all');
    else
        % ask for channel
        handles = get(ancestor(varargin{1}, 'figure'), 'userData');
        whichChannel = listdlg('ListString', get(handles.channelControl(1).channel , 'string'), 'SelectionMode', 'single', 'PromptString', 'Channel to search for spikes:', 'InitialValue', lastValues(3));
        if ~isempty(whichChannel)
            % ask for bounds
            whereBounds = inputdlg({'Start of window (msec)', 'End of Window (msec)'},'First spike in...',1, {num2str(lastValues(1)), num2str(lastValues(2))});
            if numel(whereBounds) > 0
                handles = get(ancestor(varargin{1}, 'figure'), 'userData');
                minX = min(str2double(whereBounds));
                if minX < 1
                    minX = 1;
                end
                maxX = max(str2double(whereBounds));
                if maxX > max(handles.maxX)
                    maxX = max(handles.maxX);
                end
                if maxX ~= minX
                    lastValues = [minX maxX whichChannel];
                    set(varargin{1}, 'userData', lastValues);
                    set(varargin{1}, 'checked', 'on');
                    feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), 'all');
                end
            end
        end
    end
end

function setDisplayEvents(varargin)
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1}, 'checked', 'off');
    else
        set(varargin{1}, 'checked', 'on');
    end
    for i = findobj(gcf, 'type', 'axes')'
        showEvents(i);
    end
end

function setEventMarks(varargin)
    newSetting = listdlg('PromptString','Events Markers:',...
                'SelectionMode','single',...
                'ListString',{'Pluses', 'Arrows', 'Hash Marks', 'Full Range Lines'},...
                'InitialValue', get(varargin{1}, 'userData'));
    if ~isempty(newSetting)
        set(varargin{1}, 'userData', newSetting);
        handles = get(ancestor(varargin{1}, 'figure'), 'userData');
        for i = 1:numel(handles.axes)
            showEvents(handles.axes(i));
        end
    end
end

function setDisplayBlankArtifacts(varargin)
    persistent lastValue
    if isempty(lastValue)
        lastValue = 3;
    end
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1}, 'checked', 'off');
        feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), 'all');
    else
        whereBounds = inputdlg({'Length (msec)'},'Artifact...',1, {num2str(lastValue)});
        if numel(whereBounds) > 0 && str2double(whereBounds{1}) >= 0
            lastValue =  str2double(whereBounds{1});
            set(varargin{1}, 'checked', 'on');
            set(varargin{1}, 'userData', str2double(whereBounds));
            feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), 'all');
        end
    end
end

function setDisplayArtifactNames(varargin)
    showStims(gcf, 1);
end

function stimTriggeredOverlay(varargin)
    persistent windowBounds
    if isempty(windowBounds)
        windowBounds = [-10 100];
    end
    handleList = get(gcf, 'userData');
    otherHandles = handleList.axes;
    otherKids = get(otherHandles, 'children');
    if ~iscell(otherKids)
        otherKids = {otherKids};
    end
    for index = 1:numel(otherKids)
        otherKids{index} = otherKids{index}(strcmp(get(otherKids{index}, 'userData'), 'data'));
    end

    windowBounds = str2double(inputdlg({'Window Start (msec)', 'Window End (msec)'},'',1, {num2str(windowBounds(1)); num2str(windowBounds(2))}));

    info = evalin('base', 'zData.protocol');
    for i = 1:numel(otherKids{1})
		for axesIndex = 1:numel(otherHandles)
			otherData{axesIndex} = get(otherKids{axesIndex}(i), 'yData')';
            whichOther(axesIndex) = get(handleList.channelControl(axesIndex).channel, 'value');
		end

        events = findStims(info(i), 0);
        for ttlIndex = 1:numel(info(i).ttlEnable)
			if ~isempty(events{ttlIndex})
				eventTriggeredAverage(events{ttlIndex}(:,1), otherData, windowBounds, handleList.xStep(whichOther), 1);
			end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin Popup Menu Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setLimits(varargin)
    handles = get(gcf, 'userdata');
    kids = get(gca, 'children');
    set(handles.timeControl.minVal, 'string', sprintf('%7.1f', min([min(get(kids(end), 'xData')) min(get(kids(end - 1), 'xData'))])));
    set(handles.timeControl.maxVal, 'string', sprintf('%7.1f', max([min(get(kids(end - 1), 'xData')) min(get(kids(end), 'xData'))])));
    set(handles.timeControl.autoScale, 'value', 0);
    set(handles.timeControl.minVal, 'enable', 'on');
    set(handles.timeControl.maxVal, 'enable', 'on');
    set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) str2double(get(handles.timeControl.maxVal, 'string'))]);
    newScale(gcf)
end

function setMin(varargin)
    handles = get(gcf, 'userdata');
    kids = get(gca, 'children');
    set(handles.timeControl.minVal, 'string', sprintf('%7.1f', min(get(kids(end), 'xData'))));
    if get(handles.timeControl.autoScale, 'value')
        set(handles.timeControl.maxVal, 'string', sprintf('%7.1f', max(get(handles.axes(1), 'xlim'))));
        set(handles.timeControl.autoScale, 'value', 0);
    end
    set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) str2double(get(handles.timeControl.maxVal, 'string'))]);
    newScale(gcf)
end

function setMax(varargin)
    handles = get(gcf, 'userdata');
    kids = get(gca, 'children');
    set(handles.timeControl.maxVal, 'string', sprintf('%7.1f', min(get(kids(end), 'xData'))));
    if get(handles.timeControl.autoScale, 'value')
        set(handles.timeControl.minVal, 'string', sprintf('%7.1f', min(get(handles.axes(1), 'xlim'))));        
        set(handles.timeControl.autoScale, 'value', 0);
    end
    set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) str2double(get(handles.timeControl.maxVal, 'string'))]);
    newScale(gcf)
end

function removeEvents(varargin)
    if strcmp('Yes', questdlg('Remove all events between cursors?', 'Remove Events', 'Yes', 'No', 'Yes'))
        events = getappdata(gca, 'events');
        kids = get(gca, 'children');
        bounds = get(kids(end - 1:end), 'xData');
        minBound = min([bounds{1}(1) bounds{2}(1)]);
        maxBound = max([bounds{1}(1) bounds{2}(1)]);
        
        for i = 1:numel(events)
            events(i).data = events(i).data(~(events(i).data > minBound & events(i).data < maxBound));
        end
        setappdata(gca, 'events', events);
        showEvents(gca);
    end    
end

function loadEvents(varargin)
    handleList = get(gcf, 'userData');        

    [fileName pathName] = uigetfile({'*.mat', 'Event files (*.mat)'}, 'Select a file from which to load events');
    if ~isequal(fileName,0)
        names = whos('-file', fullfile(pathName, fileName));
        if any(strcmp({names.name}, 'events'))
            load(fullfile(pathName, fileName), 'events');
            % assign the events to channels
            [channels assignments assignments] = unique({events.source});
            currentAxes = {'-None-'};
            for i = 1:handleList.axesCount
                stringData = get(handleList.channelControl(i).channel, 'string');        
                currentAxes{i + 1} = stringData{get(handleList.channelControl(i).channel, 'value')};
            end
            for j = 1:numel(channels)
                [s,v] = listdlg('PromptString',['Add events from ' channels{j} ' to:'], 'SelectionMode','single', 'ListString',currentAxes);
                if ~v
                    return
                end
                if s > 1
                    tempEvents = getappdata(handleList.axes(s - 1), 'events');
                    for i = find(assignments == j)
                        tempEvents(end + 1).data = events(i).data;
                        tempEvents(end).traceName = events(i).traceName;
                        tempEvents(end).type = [events(i).type  '; ' events(i).source];
                    end
                    setappdata(handleList.axes(s - 1), 'events', tempEvents);
                    showEvents(handleList.axes(s - 1));
                end
            end
        end
    end    
end

function markEventSetup(varargin)
    stringData = getappdata(gca, 'events');
    ourVals = [];
    for i = 1:numel(stringData)
        ourVals{i} = [stringData(i).type ', ' stringData.traceName];
    end
    kids = get(varargin{1}, 'children');
    delete(kids(1:end - 1));

    for i = 1:numel(ourVals)
		uimenu(varargin{1}, 'Label', ourVals{i}, 'callback', {@markEvent, i});
    end
end

function newEventSeries(varargin)
    eventType = inputdlg({'Type'},'Event Series',1, {'User'});

    if numel(eventType) > 0
        % add series
        kids = get(gca, 'children');
        events = getappdata(gca, 'events');
        traceNames = unique(get(kids(strcmp(get(kids, 'userData'), 'data')), 'displayName'));

        [eventTrace okClick] = listdlg('PromptString','Select trace with which events are associated:',...
                    'SelectionMode','single',...
                    'ListSize', [600 80],...
                    'ListString',traceNames);

        if okClick
            events(end + 1).data = mean(get(kids(end), 'xData'));
            events(end).traceName = traceNames{eventTrace};
            events(end).type = eventType{1};

            setappdata(gca, 'events', events);
            showEvents(gca);
        end
    end
end

function markEvent(varargin)
    kids = get(gca, 'children');
    events = getappdata(gca, 'events');
    events(varargin{3}).data(end + 1) = mean(get(kids(end), 'xData'));
    setappdata(gca, 'events', events);
    showEvents(gca);
end

function setAsReference(varargin)
    handles = get(gcf, 'userData');
    handles.useReference(handles.axes == gca) = 1;
    kids = setdiff(findobj(get(gca, 'children'), 'userData', 'data'),[get(handles.displayMean, 'userData') get(handles.displayMedian, 'userData')]);
    switch handles.markerLine
        case -1
            % median
            tempHandles = get(handles.displayMedian, 'userData');
            setappdata(gca, 'referenceTrace', get(tempHandles(handles.axes == gca), 'yData')');
            setappdata(gca, 'referenceName', get(tempHandles(handles.axes == gca), 'displayName'));
        case 0
            % mean
            tempHandles = get(handles.displayMean, 'userData');
            setappdata(gca, 'referenceTrace', get(tempHandles(handles.axes == gca), 'yData')');
            setappdata(gca, 'referenceName', get(tempHandles(handles.axes == gca), 'displayName'));                
        otherwise
            setappdata(gca, 'referenceTrace', get(kids(handles.markerLine), 'yData')');
            setappdata(gca, 'referenceName', get(kids(handles.markerLine), 'displayName'));
    end
    set(ancestor(varargin{1}, 'figure'), 'userData', handles);
    feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), find(handles.axes == gca, 1));
end

function removeReference(varargin)
    handles = get(gcf, 'userData');
    handles.useReference(handles.axes == gca) = 0;
    if isappdata(gca, 'referenceTrace')
        rmappdata(gca, 'referenceTrace');
        rmappdata(gca, 'referenceName');
    end
    set(ancestor(varargin{1}, 'figure'), 'userData', handles);
    feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), find(handles.axes == gca, 1));
end

function fitData(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    eventFunction = get(varargin{1}, 'userData');
    stringData = {};
    handleList = get(gcf, 'userData');
    whichData = get(handleList.channelControl(handleList.axes == gca).channel, 'value');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX(whichData) handleList.maxX(whichData)];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep(whichData)) * handleList.xStep(whichData);
    end
    whichX = int32((whichTime - handleList.minX(whichData)) ./ handleList.xStep(whichData) + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = eventFunction(data(whichX(1):whichX(2)), handleList.xStep(whichData), whichTime(1), gca, get(handleIndex, 'displayName'));
    end
    disp([func2str(eventFunction) '(data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep(whichData)) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function characterizeTrace(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    eventFunction = get(varargin{1}, 'userData');
    stringData = {};
    handleList = get(gcf, 'userData');
    whichData = get(handleList.channelControl(handleList.axes == gca).channel, 'value');    

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX(whichData) handleList.maxX(whichData)];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep(whichData)) * handleList.xStep(whichData);
    end
    whichX = int32((whichTime - handleList.minX(whichData)) ./ handleList.xStep(whichData) + 1);

    for handleIndex = lineHandles(lineType)
        data = get(handleIndex, 'yData');
        stringData{end + 1} = eventFunction(data(whichX(1):whichX(2)), handleList.xStep(whichData), whichTime(1), gca);
    end
    disp([func2str(eventFunction) '(data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep(whichData)) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function detectEvents(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    handleList = get(gcf, 'userData');
    whichData = get(handleList.channelControl(handleList.axes == gca).channel, 'value');        
    eventFunction = get(varargin{1}, 'userData');
    stringData = '';
    events = getappdata(gca, 'events');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX(whichData) handleList.maxX(whichData)];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep(whichData)) * handleList.xStep(whichData);
    end
    whichX = int32((whichTime - handleList.minX(whichData)) ./ handleList.xStep(whichData) + 1);

    numEvents = [];
    for handleIndex = 1:length(lineHandles) - 2
        if lineType(handleIndex)
            data = get(lineHandles(handleIndex), 'yData');
            events(end + 1).traceName = get(lineHandles(handleIndex), 'displayName');
            events(end).data = (eventFunction(data(whichX(1):whichX(2))', handleList.xStep(whichData)) - 2) * handleList.xStep(whichData) + whichTime(1);
%             disp([sum(events(end).data < 10000)/10 sum(events(end).data > 11000 & events(end).data <= 15000)/4]);            
            events(end).type = get(varargin{1}, 'label');
            numEvents(end + 1) = numel(events(end).data);
            stringData = [stringData num2str(numEvents(end)) char(13)];
            disp(['events = ' func2str(eventFunction) '(data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep(whichData)) ', ' num2str(whichTime(1)) ') * ' num2str(handleList.xStep(whichData)) ' + ' num2str(whichTime(1)) ';'])
        end
    end
    if numel(numEvents) > 1
       stringData = ['mean = ' num2str(mean(numEvents)) ', STE = ' num2str(std(numEvents)/numel(numEvents)) char(13) stringData];
    end
    setappdata(gca, 'events', events);
    showEvents(gca);
    set(get(gca, 'userdata'), 'string', stringData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-parts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = timeControl(right, bottom)
    handles.frame = uipanel(...
    'units', 'characters',...
    'Position',[right bottom 42 5],...
    'resizefcn', [],...
    'title', 'X Axis');

    handles.displayText = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','center',...
    'ListboxTop',0,...
    'Position',[0.025 0.68 0.95 0.3],...
    'String','0mV',...
    'Style','text');

    uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'CData',[],...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.025 0.4 0.1 0.3],...
    'String','Min',...
    'Style','text');

    uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.525 0.4 0.1 0.3],...
    'String','Max',...
    'Style','text');

    handles.minVal = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.225 0.4 0.2 0.3],...
    'String','0',...
    'Style','edit',...
    'enable', 'off',...
    'callback', @newTimeMin);

    handles.maxVal = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.6525 0.4 0.2 0.3],...
    'String','1',...
    'Style','edit',...
    'enable', 'off',...
    'callback', @newTimeMax);

    handles.autoScale = uicontrol(...
    'Parent', handles.frame,...
    'Units','normalized',...
    'Position',[0.2 0.05 0.544444444444444 0.3],...
    'String',{  'Auto' },...
    'Style','checkbox',...
    'value', 1,...
    'callback', @autoScale);
end

function autoScale(varargin)
    handles = get(gcf, 'userdata');
    if get(handles.timeControl.autoScale, 'value') == 0
        set(handles.timeControl.minVal, 'enable', 'on');
        set(handles.timeControl.maxVal, 'enable', 'on');
        set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) str2double(get(handles.timeControl.maxVal, 'string'))]); 
    else
        set(handles.timeControl.minVal, 'enable', 'off');
        set(handles.timeControl.maxVal, 'enable', 'off');
        set(handles.axes, 'xlim', [min(handles.minX) max(handles.maxX)]);         
    end
    newScale(gcf)
end
    
function newTimeMax(varargin)
    handles = get(gcf, 'userdata');
    set(handles.axes, 'xlim', [min(get(handles.axes(1), 'xlim')) max([str2double(get(handles.timeControl.maxVal, 'string')) min(get(handles.axes(1), 'xlim')) + 1])]);
    newScale(gcf)
end
    
function newTimeMin(varargin)
    handles = get(gcf, 'userdata');
    set(handles.axes, 'xlim', [min([str2double(get(handles.timeControl.minVal, 'string')) max(get(handles.axes(1), 'xlim')) - 1]) max(get(handles.axes(1), 'xlim'))]);    
    newScale(gcf)
end

function handles = channelControl(right, bottom)
    handles.frame = uipanel(...
    'units', 'characters',...
    'Position',[right bottom 42 13],...
    'resizefcn', []);

    handles.displayText = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','center',...
    'ListboxTop',0,...
    'Position',[0.025 0.8 0.95 0.133333333333333],...
    'String','0mV',...
    'Style','text',...
    'tag','displayText');

    uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'CData',[],...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.0462962962962963 0.703030303030303 0.0972222222222222 0.121212121212121],...
    'String','Max',...
    'Style','text');

    uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.0509259259259259 0.575757575757576 0.0925925925925926 0.127272727272727],...
    'String','Min',...
    'Style','text');

    handles.minVal = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.166666666666667 0.593939393939394 0.166666666666667 0.127272727272727],...
    'String','-100',...
    'Style','edit',...
    'tag','minVal',...
    'enable', 'off',...
    'callback', @newMin);

    handles.channel = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.0324074074074074 0.951515151515152 0.680555555555555 0.121212121212121],...
    'String',{'No Channels'},...
    'Style','popupmenu',...
    'tag','channel',...
    'Value',1,...
    'callback', @newChannel);

    handles.maxVal = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','right',...
    'ListboxTop',0,...
    'Position',[0.166666666666667 0.715151515151515 0.166666666666667 0.127272727272727],...
    'String','40',...
    'Style','edit',...
    'tag','maxVal',...    
    'enable', 'off',...
    'callback', @newMax);

    handles.scaleType = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.402777777777778 0.721212121212121 0.555555555555556 0.121212121212121],...
    'String',{'Auto', 'Manual', 'FloatH', 'FloatN', 'FloatM'},...
    'Style','popupmenu',...
    'tag','scaleType',...
    'Value',1,...
    'callback', @newScale);

    handles.offset = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.40462962962963 0.6 0.244444444444444 0.0909090909090909],...
    'String',{'Null' },...
    'Style','checkbox',...
    'tag','null',...
    'callback', @newOffset);

    handles.float = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.70462962962963 0.6 0.20 0.0909090909090909],...
    'String',{'100' },...
    'Style','edit',...
    'tag','floatVal',...
    'HorizontalAlignment','right',...
    'callback', @newFloat);

    matlabText = loadMatlabText;

    handles.commandText = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.025 0.41 0.95 0.12],...
    'String', {''},...
    'HorizontalAlignment','left',...
    'Style','edit',...
    'tag','commandText',...
    'userData', {size(matlabText, 2) + 1, matlabText},...
    'keyPressFcn', @commandKeyPress);

    handles.resultText = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','left',...
    'max', 1000,...
    'min', 1,...
    'Position',[0.025 0.025 0.95 0.36],...
    'String',{  '' },...
    'Style','edit',...
    'tag','resultText');
end

function newMax(varargin)
    handles = get(gcf, 'userdata');
    whichAxis = find([handles.channelControl.maxVal] == varargin{1});
    set(handles.axes(whichAxis), 'ylim', [min(get(handles.axes(whichAxis), 'ylim')) str2double(get(handles.channelControl(whichAxis).maxVal, 'string'))]);
    if isappdata(handles.axes(whichAxis), 'events')
        showEvents(handles.axes(whichAxis));
    end
    if isappdata(0, 'imageBrowser')
        showFrameMarker(handles.axes(whichAxis));
    end
end
    
function newMin(varargin)
    handles = get(gcf, 'userdata');
    whichAxis = find([handles.channelControl.minVal] == varargin{1});
    set(handles.axes(whichAxis), 'ylim', [str2double(get(handles.channelControl(whichAxis).minVal, 'string')) max(get(handles.axes(whichAxis), 'ylim'))]);
    if isappdata(handles.axes(whichAxis), 'events')
        showEvents(handles.axes(whichAxis));
    end
    if isappdata(0, 'imageBrowser')
        showFrameMarker(handles.axes(whichAxis));
    end    
end
 
function newOffset(varargin)
    handles = get(gcf, 'userdata');
    whichAxis = find([handles.channelControl.offset] == varargin{1});    
    feval(getappdata(gcf, 'updateFunction'), gcf, whichAxis);
    if isappdata(handles.axes(whichAxis), 'events')
        showEvents(handles.axes(whichAxis));
    end
    if isappdata(0, 'imageBrowser')
        showFrameMarker(handles.axes(whichAxis));
    end    
end
     
function newChannel(varargin)
    handles = get(gcf, 'userdata');
    whichAxis = find([handles.channelControl.channel] == varargin{1});
    rmappdata(handles.axes(whichAxis), 'events');
    showEvents(handles.axes(whichAxis));    
    feval(getappdata(gcf, 'updateFunction'), gcf, whichAxis);
end
 
function newFloat(varargin)
    handles = get(gcf, 'userdata');
    whichAxis = find([handles.channelControl.float] == varargin{1});
    newScale(handles.channelControl(whichAxis).scaleType);   
    if isappdata(handles.axes(whichAxis), 'events')
        showEvents(handles.axes(whichAxis));
    end
    if isappdata(0, 'imageBrowser')
        showFrameMarker(handles.axes(whichAxis));
    end
end
 
function commandText = loadMatlabText()
    fid = fopen('newScopeCommands.txt');
    whichCommand = 1;
    if fid > 0
        while 1
            tline = fgetl(fid);
            if ~ischar(tline)
                break
            end
            commandText{whichCommand} = tline;
            whichCommand = whichCommand + 1;
        end
        fclose(fid);
    else
        commandText = '';
    end
end
    
function addText(varargin)
    userData = get(varargin{1}, 'userData');
    commandText = userData{2};
    newCommand = cell2mat(get(varargin{1}, 'string'));
    if find(strcmp(commandText, newCommand))
        commandText(find(strcmp(commandText, newCommand)):length(commandText) - 1) = commandText(find(strcmp(commandText, newCommand)) + 1:length(commandText));
        commandText{length(commandText)} = newCommand;
        set(varargin{1}, 'userData', {length(commandText), commandText});
	else
		commandText{end + 1} = newCommand;
		set(varargin{1}, 'userData', {length(commandText), commandText});		
    end
end
    
function commandKeyPress(varargin)
    userData = get(varargin{1}, 'userData');
    commandText = userData{2};
    whichCommand = userData{1};

    if whichCommand <= length(commandText) + 1 && whichCommand > -1
        if strcmp(varargin{2}.Key, 'downarrow')  % down arrow
            if whichCommand < length(commandText)
                whichCommand = whichCommand + 1;
                set(varargin{1}, 'string', commandText(whichCommand));
            elseif whichCommand == length(commandText)
                whichCommand = whichCommand + 1;
                set(varargin{1}, 'string', '');
            end
        end
        
        if strcmp(varargin{2}.Key, 'uparrow') && whichCommand > 1 % up arrow
            whichCommand = whichCommand - 1;
            set(varargin{1}, 'string', commandText(whichCommand));
        end
    end
    
    set(varargin{1}, 'userData', {whichCommand, commandText})
    
    if strcmp(varargin{2}.Key, 'return')
        handles = get(gcf, 'userdata');
        whichAxis = find([handles.channelControl.commandText] == varargin{1}); 
        pause(.05);
        addText(varargin{1}, varargin{2});
		pause(.05);
        feval(getappdata(gcf, 'updateFunction'), gcf, whichAxis);
    end
end