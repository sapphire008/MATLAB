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
% The reason that these scheme seems so odd is that it allows fewer copies
% of the data to be stored in the workspace so that you can work with
% larger data sets.  This is accomplished because Matlab cleverly holds
% onto a pointer to the copy of the input when there are subfunctions
% addressing the data instead of creating another copy.  Doubly cleverly,
% if the input data is cleared from its native location (probably the base
% workspace) then Matlab doesn't clear it from memory so that the function
% can still refer to it.  However, as soon as the last subfunction callback
% that uses the data is disconnected from the figure Matlab will delete the
% data set, allowing the user to clear the data copy at will be removing
% callbacks.

% sections modified by BWS

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
        'Position', [10 27.5 300 61],...
        'Visible', 'on',...
        'resizefcn', @resize,...
        'PaperPositionMode', 'auto',...
        'closerequestfcn', @closeScope)%,...
%         'handleVisibility', 'callback'); % 12-19-08 made handle invisible to hopefully avoid export errors caused by errant graphical addition to the scope
    
    handles.slider = uicontrol('Style','slider','Units','normal','Position', [0 0 1 .015], 'value', 0, 'sliderStep', [1 inf], 'callback', @traceScroll);
    handles.zoom = uicontrol('Style','edit','Units','normal','Position',[0 .018 .03 .02], 'string', '1', 'callback', @traceScroll, 'visible', 'off');
    f = uimenu('Label','File');
        uimenu(f,'Label','Print With Axes','Callback','printWithAxes');
        uimenu(f,'Label','Print With Scale Bars','Callback','printWithScaleBars','Accelerator','P');
        uimenu(f,'Label','Print Setup','Callback','PRINTDLG(''-setup'',gcf)');
        uimenu(f, 'Label', 'Print Montage', 'Callback', @printMontage,'Accelerator','M');
        uimenu(f,'Label','Close','Callback','close(gcf)',...
               'Separator','on');
        uimenu(f,'Label','Reload Config','callback',@reloadConfig);           % Added to read INI file on 5.22.09           
    f = uimenu('Label','Export');
        uimenu(f,'Label','With Axes','Callback','exportWithAxes');
        uimenu(f,'Label','With Scale Bars (file)','Callback','exportWithScaleBars','Accelerator','E');   
        uimenu(f,'Label','To R drive (file)','Callback','exportToRDrive','Accelerator','R');           
    f = uimenu('Label','Display');
        handles.displayTraces = uimenu(f,'Label','Traces','Callback', @setDisplay, 'checked', 'on');
        handles.displayMean = uimenu(f,'Label','Mean','Callback', @setDisplay, 'checked', 'off', 'Separator','on','Accelerator','M');
        handles.displayMedian = uimenu(f,'Label','Median','Callback', @setDisplay, 'checked', 'off','Accelerator','D');
        handles.colorCoded = uimenu(f,'Label','Color Coded','Callback', @setDisplay, 'checked', 'off','Separator','on');    
        handles.displayAligned = uimenu(f,'Label','Aligned to...','Callback', @setDisplayAligned, 'checked', 'off','userData', [1 100 1]);
        handles.displayCursors = uimenu(f,'Label','Cursors','callback', @setCursors, 'checked','on');
        handles.displayEvents = uimenu(f,'Label','Events','checked', 'on','callback',@setDisplayEvents);
        handles.displayTopText = uimenu(f,'Label','Top Text','checked', 'on','callback',@setDisplayTopText, 'accelerator', 'T');        
        handles.displayEventsType = uimenu(f,'Label','Event Marks...','callback',@setEventMarks, 'userData', 1);
        handles.subtractRefTrace = uimenu(f,'Label','Subtract Reference Trace','callback',@setDisplay, 'userData', 1);
        handles.displayBlankArtifacts = uimenu(f,'Label','Blank Artifacts','Accelerator','B', 'callback',@setDisplayBlankArtifacts, 'userData', 3, 'separator', 'on');
        handles.displayArtifactNames = uimenu(f,'Label','Artifact Names...','callback', @setDisplayArtifactNames);
        handles.displayTTLOverlay = uimenu(f,'Label','Stim-Triggered Overlay','callback',@stimTriggeredOverlay);
        uimenu(f,'Label','Add Channel','Callback', @addChannel);
        uimenu(f,'Label','Remove Channel','Callback', @removeChannel);
        uimenu(f,'Label','Plot Browser','callback',@showPlotBrowser);
    uimenu('Label', 'Legend', 'Visible', 'off');
    g =  uicontextmenu;
        uimenu(g,'Label','Set as Limits','Callback', @setLimits);
        uimenu(g,'Label','Set Minimum','Callback', @setMin);
        uimenu(g,'Label','Set Maximum','Callback', @setMax);
        uimenu(g,'Label','Add Channel','Callback', @addChannel, 'separator', 'on');
        uimenu(g,'Label','Remove Channel','Callback', @removeChannel);
        uimenu(g,'Label','Display Protocol','Callback','benProtocolViewer(getappdata(0, ''currentTrace''))');
        y = uimenu(g,'Label','Export', 'Separator','on');
            uimenu(y,'Label','Data to Workspace','Callback',{@exportToWorkspace, 0});
            uimenu(y,'Label','Time to Workspace','Callback',{@exportToWorkspace, 1});
            uimenu(y,'Label','Names to Workspace','Callback',{@exportToWorkspace, 2});         
            uimenu(y,'Label','Data to Clipboard','Callback',{@exportToWorkspace, 8}, 'separator', 'on');
            uimenu(y,'Label','Time to Clipboard','Callback',{@exportToWorkspace, 9}); 
            uimenu(y,'Label','Names to Clipboard','Callback',{@exportToWorkspace, 10}); 
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
%         j = uimenu(g,'Label','Fit');
%             fileNames = dir([installDir 'Fitting']);
%             for iFiles = {fileNames(~cat(2, fileNames.isdir) & cellfun(@(x) ~isempty(x), strfind({fileNames.name}, '.m'))).name};
%                 try
%                     funHandle = str2func(iFiles{1}(1:end - 2));
%                     uimenu(j, 'Label', funHandle(), 'callback', @fitData, 'userData', funHandle);
%                 catch
%                     disp(['File ' iFiles{1} ' in Fitting folder is not a valid fitting function']);
%                 end
%             end

         jj7 =uimenu(g,'Label','Fitting');
         uimenu(jj7,'Label','Single Exp','callback',@BenSingleExpFit);
         uimenu(jj7,'Label','Double Exp','callback',@BenDoubleExpFit);
         uimenu(jj7,'Label','Triple Exp','callback',@BenTripleExpFit);
         uimenu(jj7,'Label','Alpha','callback',@BenAlphaFit);
         uimenu(jj7,'Label','Boltzmann','callback',@BenBoltzmannFit);
         uimenu(jj7,'Label','Line','callback',@BenLineFit);
         uimenu(jj7,'Label','Sine','callback',@BenSineFit);
            
    h = copyobj(g, get(g, 'parent'));
        % load experiment characterization functions if applicable
        uimenu(h,'Label','Set as Reference','Callback', @setAsReference);
        uimenu(h,'Label','Remove Reference','Callback', @removeReference);        
        uimenu(h,'Label','Set all Reference','Callback', @setAllReference);
        uimenu(h,'Label','Remove all Reference','Callback', @removeAllReference);              
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
        uimenu(h,'Label','Reload Config','callback',@reloadConfig);           % Added to read INI file on 5.22.09


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
    
    
    setappdata(0, 'scopes', handles.figure);
%     set(handles.figure, 'units', 'pixel');
    % load config file
    reloadConfig; % added to read INI files 5.22.09    
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
        if size(yData{iData}, 1) ~= xDim
            error('Input vectors of unequal length');
        end
    end

    numTraces = length(yData);
    
    % set boring values in case nothing passed
    for i = 1:numTraces
        channelNames{i} = ['Group ' num2str(i)];
    end
    channelValues = size(yData, 2):-1:1;
    xData = 1:size(yData{1}, 1);    
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
           if isfield(protocolData, 'ampEnable')
               for ampIndex = find(cellfun(@(x) ~isempty(x), protocolData(1).ampEnable))'
                   whatData = whichChannel(protocolData(1), ampIndex);
                   if ~isempty(whatData)
                       channelIndices(end + 1) = whatData;
                   end
               end
           end
           % add in non amplifier channels
           channelIndices = [channelIndices find(cellfun(@(x) isempty(x), strfind(protocolData(1).channelNames, 'Amp ')))];
              
           if exist('installDir', 'var')
               % this is a new newScope window
               channelValues = channelIndices;
           elseif numel(protocolData(1).channelNames) > 0 %&& (~(numel(protocolData(1).channelNames) == length(get(handles.channelControl(1).channel, 'string'))) || any(~strcmp(protocolData(1).channelNames', get(handles.channelControl(1).channel, 'string'))))
               % we have a different set of channels  
               % *************************
               %  REMOVE THIS SECTION TO NOT OVERWRITE CURRENT CHANNELS
               % *************************
               clear channelValues
               savedChannels = get(handles.channelControl(1).channel, 'string');
               numNew = 0;
               for j = 1:handles.axesCount
                   whichChannels = find(strcmp(savedChannels(get(handles.channelControl(handles.axesCount - j + 1).channel, 'value')), protocolData(1).channelNames), 1, 'first');
                   if ~isempty(whichChannels)
                       % set what was set before
                       channelValues(handles.axesCount - j + 1) =  whichChannels;
                   else
                       % set what we think is best
                       numNew = numNew + 1;
                       channelValues(handles.axesCount - j + 1) = channelIndices(min([length(channelIndices) numNew]));
                   end
               end
           elseif numel(channelIndices) >= handles.axesCount
               channelValues = channelIndices(1:handles.axesCount);
           else
               channelValues = channelIndices;
               while numel(channelValues) < handles.axesCount
                   channelValues = [channelValues channelValues];
               end
               channelValues(handles.axesCount + 1:end) = [];
           end

           %reset some parameters for the scope
           xData = 0:protocolData(1).timePerPoint / 1000:protocolData(1).sweepWindow;
           handles.minX = protocolData(1).timePerPoint / 1000;
           handles.maxX = protocolData(1).sweepWindow;
           handles.xStep = protocolData(1).timePerPoint / 1000;
           if get(handles.timeControl.autoScale, 'value')
               set(handles.axes, 'xlim', [handles.minX handles.maxX]); 
           elseif str2double(get(handles.timeControl.maxVal, 'string')) > handles.maxX
               set(handles.timeControl.maxVal, 'string', num2str(handles.maxX));
               if str2double(get(handles.timeControl.minVal, 'string')) > handles.maxX
                    set(handles.timeControl.minVal, 'string', '0');
                    set(handles.axes, 'xlim', [handles.minX handles.maxX]);
               else
                    set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) handles.maxX]);
               end            
           end
           set(handles.figure, 'userData', handles);
%            feval(getappdata(gcf, 'updateFunction'), figures(i), 'all');
           setAxisLabels(handles.axes(1));
        else                     
            % figure out which input is which
            for hIndex = 2:nargin
                if ~ishandle(varargin{hIndex}(1)) && isvector(varargin{hIndex}) && isnumeric(varargin{hIndex})
                    xData = varargin{hIndex};
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

% make sure we have the right number of axes
for i = numel(findobj(handles.figure, 'type', 'axes')) + 1:numel(channelValues) 
    set(handles.figure, 'userData', handles);
    addChannel(handles.axes(1));
    handles = get(handles.figure, 'userData');
end
for i = 1:numel(handles.channelControl)
    set(handles.channelControl(i).channel, 'value', channelValues(min([i numel(channelValues)])));
end

for iTrace = 1:numel(channelValues)
    set(handles.channelControl(iTrace).channel, 'string', channelNames);
    set(handles.channelControl(iTrace).channel, 'value', channelValues(iTrace));
%     if max(yData{iTrace}(:,1)) ~= min(yData{iTrace}(:,1))
%         set(handles.axes(iTrace), 'ylim', [min(min(yData{iTrace})) max(max(yData{iTrace}))]);
%     else
%         set(handles.axes(iTrace), 'ylim', [yData{iTrace}(1) - 1 yData{iTrace}(1) + 1]);
%     end
end

handles.minX = min(xData); % used for calculating the markerLoc in movePointers
handles.maxX = max(xData); % used for checking bounds in horizontal zoom
handles.xStep = diff(xData(1:2)); % used for calculating the markerLoc in movePointers

if ~isappdata(0, 'EnableMiddleZoom') %exist('protocolData', 'var')
       reloadConfig;
       setappdata(gcf, 'extraPrintText', evaluateBonusText(protocolData(1)));        
end
set(handles.figure, 'WindowButtonMotionFcn', @movePointers,...
        'windowButtonDownFcn', @mouseDownScope,...
        'windowButtonUpFcn', @mouseUpScope,...
        'keyPressFcn', @windowKeyPress);

set(handles.figure, 'userData', handles);
try
    set(handles.figure, 'WindowScrollWheelFcn', @scrollMouse);
catch
    % mouse scrolling was introduced in some recent version of Matlab, so
    % this keeps older versions from crashing
end

setappdata(handles.figure, 'updateFunction', @updateTrace)
if exist('installDir', 'var')
    % this scope was just created so autoscale it
    currentLim = [handles.minX handles.maxX];
else
    currentLim = get(handles.axes(1), 'xlim');
    if max(currentLim) > handles.maxX
        currentLim(2) = handles.maxX;
    end
    if min(currentLim) < handles.minX
        currentLim(1) = handles.minX;
    end
end
set(handles.axes, 'xlim', currentLim);
% for iAxes = 1:handles.axesCount
%     updateTrace(handles.figure, iAxes);
% end
updateTrace(handles.figure, 'all');


% update the x axis
xBounds = get(handles.axes(1), 'xlim');
if xBounds(1) == 0
    xBounds(1) = handles.minX;
end
set(handles.zoom, 'string', sprintf('%7.3f', (handles.maxX - handles.minX) / diff(xBounds)));

zoomFactor = str2double(get(handles.zoom, 'string'));
newStep = 1 / zoomFactor / (1 - 1 / zoomFactor);
if newStep > 10
    set(handles.slider, 'sliderStep', [1 newStep]);
else
    set(handles.slider, 'sliderStep', [newStep / 10 newStep]);
end
if xBounds(1) == handles.minX && zoomFactor == 1
    set(handles.slider, 'value', 0);
else
    set(handles.slider, 'value', max([min([(xBounds(1) - handles.minX) / (handles.maxX - handles.minX) / (1- 1 / zoomFactor) 1]) 0]));
end    
setAxisLabels(handles.axes(1));
xCoord = 1;
try
    movePointers('forceCursors');
catch
    if ~isempty(get(handles.traceName, 'string'))
%         msgbox('Cursor text is probably mismatched with data');
    end
end
    
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
        handles = get(handles.figure, 'userData');        

        for i = 1:handles.axesCount
            if (pointerLoc(2) - 3) / (figureLoc(4) - 3) > sum(handles.axisPortion(1:i - 1)) && (pointerLoc(2) - 3) / (figureLoc(4) - 3) < sum(handles.axisPortion(1:i))
                handles.selectionAxis = i;
            end
        end
        if pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3
            % over the axes
            if strcmp(get(handles.figure, 'pointer'), 'top')
                % over a boundary between two axes
                whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
                for i = 1:handles.axesCount - 1
                    if whereAt < sum(handles.axisPortion(1:i)) + handles.axisPortion(i + 1) * .05 && whereAt > sum(handles.axisPortion(1:i)) - handles.axisPortion(i) * .05
                        handles.selectionReference = i + 1;
                        handles.selectionType = 3;
                    end
                end
            else
                % over the axis middle
                switch get(handles.figure, 'SelectionType')
                    case 'normal' %left mouse button clicked
                        if handles.markerFixed == 0
                            for index = 1:handles.axesCount
                                kidLines = get(handles.axes(index), 'children');
                                set(kidLines(end - 1), 'xData', [xCoord xCoord], 'ydata', get(kidLines(end), 'yData'));
                                set(kidLines(end - 1), 'visible', 'on');
                            end
                            handles.markerFixed = 1;
                        else
                            for index = 1:handles.axesCount
                                kidLines = get(handles.axes(index), 'children');
                                set(kidLines(end - 1), 'visible', 'off');
                                set(kidLines(end), 'xData', [xCoord xCoord]);
                            end
                            handles.markerFixed = 0;
                        end
                    case 'extend' %middle mouse button clicked
                        setappdata(handles.figure, 'rbStart', get(gca,'CurrentPoint'));
                        rbbox;
                    case 'alt' %right mouse button clicked

                    case 'open' %double click

                end
            end
        elseif pointerLoc(1) <= 7 && pointerLoc(2) > 3
            % over the y-axis on the left
            switch get(handles.figure, 'SelectionType')
                case 'normal' %left mouse button clicked
                    uicontrol('units', 'character', 'Style', 'text', 'String', '', 'backgroundColor', [0 0 1], 'Position', [0, pointerLoc(2), 7, .01]);
                    handles.selectionReference = pointerLoc(2);
                    handles.selectionType = 2;
                case 'extend' %middle mouse button clicked

                case 'alt' %right mouse button clicked

                case 'open' %double click

            end
        elseif pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43 && pointerLoc(2) > 3
            % over the y-axis on the right
            switch get(handles.figure, 'SelectionType')
                case 'normal' %left mouse button clicked
                    uicontrol('units', 'character', 'Style', 'text', 'String', '', 'backgroundColor', [0 0 1], 'Position', [figureLoc(3) - 55, pointerLoc(2), 5, .01]);
                    handles.selectionReference = pointerLoc(2);
                    handles.selectionType = 4;
                case 'extend' %middle mouse button clicked

                case 'alt' %right mouse button clicked

                case 'open' %double click

            end
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 55 && pointerLoc(2) <= 3
            % over the x-axis
            switch get(handles.figure, 'SelectionType')
                case 'normal' %left mouse button clicked
                    uicontrol('units', 'character', 'Style', 'text', 'String', '', 'backgroundColor', [0 0 1], 'Position', [pointerLoc(1), 1, 0.01, 3]);
                    handles.selectionReference = pointerLoc(1);
                    handles.selectionType = 1;
                case 'extend' %middle mouse button clicked

                case 'alt' %right mouse button clicked

                case 'open' %double click

            end
        end
        set(handles.figure, 'userData', handles);
    end

    function movePointers(varargin)
        pointerLoc = get(handles.figure, 'CurrentPoint');
        figureLoc = get(handles.figure, 'Position');
        handles = get(handles.figure, 'userData');        

        if handles.selectionType > 0 && ~(ischar(varargin{1})  && strcmp(varargin{1}, 'forceCursors'))
            blueRect = get(handles.figure, 'children');
            blueRect = blueRect(1);
            switch handles.selectionType
                case 1 % horizontal zoom bar
                    if pointerLoc(1) > handles.selectionReference
                        set(blueRect, 'position', [handles.selectionReference, 1, pointerLoc(1) - handles.selectionReference, 2]);
                    elseif pointerLoc(1) < handles.selectionReference
                        set(blueRect, 'position', [pointerLoc(1), 1, handles.selectionReference - pointerLoc(1), 2]);
                    end
                case 2 % vertical zoom bar left
                    if pointerLoc(2) > handles.selectionReference
                        set(blueRect, 'position', [0, handles.selectionReference, 7, pointerLoc(2) - handles.selectionReference]);
                    elseif pointerLoc(2) < handles.selectionReference
                        set(blueRect, 'position', [0, pointerLoc(2), 7, handles.selectionReference - pointerLoc(2)]);
                    end
                case 3 % resizing axes
                    currentPortion = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
                    if currentPortion > sum(handles.axisPortion(1:handles.selectionReference - 2)) && currentPortion < sum(handles.axisPortion(1:handles.selectionReference))
                        handles.axisPortion(handles.selectionReference - 1) = currentPortion - sum(handles.axisPortion(1:handles.selectionReference - 2));
                        handles.axisPortion(handles.selectionReference) = 1 - sum(handles.axisPortion([1:handles.selectionReference - 1 handles.selectionReference + 1:handles.axesCount]));
                    end
                    set(handles.figure, 'userData', handles);
                case 4 % vertical zoom bar right
                    if pointerLoc(2) > handles.selectionReference
                        set(blueRect, 'position', [figureLoc(3) - 48, handles.selectionReference, 5, pointerLoc(2) - handles.selectionReference]);
                    elseif pointerLoc(2) < handles.selectionReference
                        set(blueRect, 'position', [figureLoc(3) - 48, pointerLoc(2), 5, handles.selectionReference - pointerLoc(2)]);
                    end
            end
        elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3 ||  (ischar(varargin{1})  && strcmp(varargin{1}, 'forceCursors'))
            % inside the plotting area
            onBorder = false;
            whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);
            for i = 1:handles.axesCount - 1
                if whereAt < sum(handles.axisPortion(1:i)) + handles.axisPortion(i + 1) * .05 && whereAt > sum(handles.axisPortion(1:i)) - handles.axisPortion(i) * .05
                    onBorder = true;
                end
            end
            if onBorder
                set(handles.figure, 'pointer', 'top');
            else
                % if the ydata has changed because this is a running scope
                % then update it here
                if isfield(handles, 'isRunning')
                    pointerData = nan(16);
                    pointerData(8,:) = 2;
                    pointerData(:,8) = 2;
                    set(handles.figure, 'pointer', 'custom', 'pointerShapeHotSpot', [8 8], 'pointerShapeCData', pointerData);
                    if get(handles.isRunning, 'userData')
                        for index = 1:handles.axesCount
                            lineHandles = get(handles.axes(index), 'children');
                            whichChan = get(handles.channelControl(index).channel, 'value');
                            yData{whichChan} = get(lineHandles(1), 'yData')';
                        end
                        set(handles.isRunning, 'userData', 0);
                    end
                else
                    set(handles.figure, 'pointer', 'crosshair');                    
                end
                xCoord = round(((pointerLoc(1) - 7) / (figureLoc(3) - 55)  * diff(get(handles.axes(1),'Xlim')) + min(get(handles.axes(1),'Xlim'))) / handles.xStep) * handles.xStep;
                whereX = round((xCoord - handles.minX) / handles.xStep) + 1;
                whichAxis = find([1 whereAt > cumsum(handles.axisPortion(1:end-1))] & whereAt < cumsum(handles.axisPortion), 1, 'first');
                yCoord = (whereAt - sum(handles.axisPortion(1:whichAxis - 1))) / handles.axisPortion(whichAxis) * diff(get(handles.axes(whichAxis),'Ylim')) + min(get(handles.axes(whichAxis),'Ylim'));

                if handles.markerFixed == 0
                    set(handles.timeControl.displayText, 'string', sprintf('%10.1f', xCoord));
                    axisHandles = nan(handles.axesCount, 1);
                    
                    % determine which line we are looking at
                    howFar = inf;
                    whichChan = get(handles.channelControl(whichAxis).channel, 'value');
                    kidLines = findobj(handles.axes(whichAxis), 'userData', 'data');
                    for i = [get(handles.displayMean, 'userData') get(handles.displayMedian, 'userData')]
                        kidLines  = kidLines(kidLines ~=i);
                    end
                    if strcmp(get(handles.displayTraces, 'checked'), 'on')
                        if handles.dataChanged(whichAxis)
                            for traceIndex = 1:numel(kidLines) - (handles.useReference(whichAxis) && strcmp(get(handles.subtractRefTrace, 'check'), 'off'))
                                tempData = get(kidLines(traceIndex), 'yData');
                                if abs(tempData(whereX) - yCoord) < howFar
                                    howFar = abs(tempData(whereX) - yCoord);
                                    handles.markerLine = traceIndex;
                                    if isappdata(handles.figure, 'extraPrintText')
                                        set(handles.traceName, 'string', evaluateBonusText(protocolData(traceIndex)));
                                    end
                                end
                            end
                        else
                            for traceIndex = 1:size(yData{whichChan}, 2)
                                if abs(yData{whichChan}(whereX, traceIndex) - yCoord) < howFar
                                    howFar = abs(yData{whichChan}(whereX, traceIndex) - yCoord);
                                    handles.markerLine = traceIndex;
                                    if isappdata(handles.figure, 'extraPrintText')                                    
                                        set(handles.traceName, 'string', evaluateBonusText(protocolData(traceIndex)));
                                    end
                                end
                            end
                        end
                    end
                    if handles.useReference(whichAxis) && strcmp(get(handles.subtractRefTrace, 'check'), 'off')
                        if handles.dataChanged(whichAxis)
                            tempData = get(kidLines(end), 'yData');
                        else
                            tempData = getappdata(handles.axes(whichAxis), 'referenceTrace');
                        end
                        if size(tempData,1) >= whereX && abs(tempData(whereX) - yCoord) < howFar
                            howFar = abs(tempData(whereX) - yCoord);
                            handles.markerLine = -2;
                            if isappdata(handles.figure, 'extraPrintText')
                                        set(handles.traceName, 'string', evaluateBonusText(protocolData(traceIndex)));
                            end
                        end
                    end
                    if strcmp(get(handles.displayMedian, 'checked'), 'on')
                        tempHandles = get(handles.displayMedian, 'userData');
                        if ~isnan(tempHandles(whichAxis))
                            tempData = get(tempHandles(whichAxis), 'yData');
                            if abs(tempData(whereX) - yCoord) < howFar
                                handles.markerLine = -1;
                                if isappdata(handles.figure, 'extraPrintText')
                                        set(handles.traceName, 'string', evaluateBonusText(protocolData(traceIndex)));
                                end
                            end
                        end
                    end
                    if strcmp(get(handles.displayMean, 'checked'), 'on')
                        tempHandles = get(handles.displayMean, 'userData');
                        if ~isnan(tempHandles(whichAxis))
                            tempData = get(tempHandles(whichAxis), 'yData');
                            if abs(tempData(whereX) - yCoord) < howFar
                                handles.markerLine = 0;
                                if isappdata(handles.figure, 'extraPrintText')
                                        set(handles.traceName, 'string', evaluateBonusText(protocolData(traceIndex)));
                                end
                            end
                        end
                    end 
                    setappdata(0, 'currentTrace', protocolData(traceIndex).fileName);
                    for index = 1:handles.axesCount
                        try
                            kidLines = get(handles.axes(index), 'children');
                            if length(kidLines) > 2
                                axisHandles(index) = kidLines(end);                                
                                kidLines = kidLines(strcmp('data', {get(kidLines, 'displayName')}));
                                switch handles.markerLine
                                    case -2
                                        % reference trace
                                        tempData = getappdata(handles.axes(whichAxis), 'referenceTrace');
                                        currentPoint = tempData(whereX);
                                    case -1
                                        % median trace
                                        tempHandles = get(handles.displayMedian, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX);
                                    case 0
                                        % mean trace
                                        tempHandles = get(handles.displayMean, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX);                                        
                                    otherwise
                                        % some data trace
                                        if handles.dataChanged(whichAxis)
                                            tempData = get(kidLines(handles.markerLine + strcmp(get(handles.displayMean, 'checked'), 'on') + strcmp(get(handles.displayMedian, 'checked'), 'on')), 'yData');
                                            currentPoint = tempData(whereX);                                            
                                        else
                                            currentPoint = yData{get(handles.channelControl(index).channel, 'value')}(whereX, handles.markerLine);
                                        end
                                end

                              % modified by BWS on 12/8/08
%                                 tempChannel=get(handles.channelControl(index).channel,'string');
                                
                                set(handles.channelControl(index).displayText, 'foregroundColor',[0 0 0]); % black
                                if currentPoint == 0
                                    set(handles.channelControl(index).displayText, 'string', '0');
                                else
                                    set(handles.channelControl(index).displayText, 'string', benDisplayString(currentPoint));
                                end
                            end
                        catch
                            set(handles.channelControl(index).displayText, 'string', '');
                        end
                    end                    
                    handles.markerLoc = whereX;
                    handles.markerTime = xCoord;
                    set(handles.figure, 'userData', handles);
                    if strcmp(get(handles.displayCursors, 'checked'), 'on')
                        for index = find(~isnan(axisHandles))' 
                            set(axisHandles(index), 'xData', [xCoord xCoord], 'yData', get(handles.axes(index), 'ylim'));                    
                        end
                    end
                else % handle marker fixed
                    set(handles.timeControl.displayText, 'string', [sprintf('%10.1f',handles.markerTime) ' \ ' sprintf('%10.1f', xCoord - handles.markerTime)]);
                    axisHandles = nan(handles.axesCount, 1);                    
                    for index = 1:handles.axesCount
                        try
                            kidLines = get(handles.axes(index), 'children');
                            if length(kidLines) > 2
                                axisHandles(index) = kidLines(end - 1);             
                                kidLines = kidLines(strcmp('data', {get(kidLines, 'displayName')}));
                                switch handles.markerLine
                                    case -2
                                        % reference trace
                                        tempData = getappdata(handles.axes(whichAxis), 'referenceTrace');
                                        currentPoint = tempData(whereX);
                                        lastPoint = tempData(handles.markerLoc);
                                    case -1
                                        % median trace
                                        tempHandles = get(handles.displayMedian, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX);
                                        lastPoint = tempData(handles.markerLoc);
                                    case 0
                                        % mean trace
                                        tempHandles = get(handles.displayMean, 'userData');
                                        tempData = get(tempHandles(index), 'yData');
                                        currentPoint = tempData(whereX);
                                        lastPoint = tempData(handles.markerLoc);
                                    otherwise
                                        % some data trace
                                        whichChan = get(handles.channelControl(index).channel, 'value');
                                        if handles.dataChanged(whichAxis)
                                            tempData = get(kidLines(handles.markerLine + strcmp(get(handles.displayMean, 'checked'), 'on') + strcmp(get(handles.displayMedian, 'checked'), 'on')), 'yData');
                                            currentPoint = tempData(whereX);
                                            lastPoint = tempData(handles.markerLoc);                                                                                     
                                        else
                                            currentPoint = yData{whichChan}(whereX, handles.markerLine);
                                            lastPoint = yData{whichChan}(handles.markerLoc, handles.markerLine);                                         
                                        end
                                end                                
                                
                              
                                % modified by BWS 12/8/08                          
                                set(handles.channelControl(index).displayText, 'foregroundColor',[1 0 0]);
                                if currentPoint == 0
                                    set(handles.channelControl(index).displayText, 'string', [benDisplayString(lastPoint) '  ' benDisplayString(currentPoint) '  ' benDisplayString(currentPoint - lastPoint)]);
                                else
                                    set(handles.channelControl(index).displayText, 'string', [benDisplayString(lastPoint) '  ' benDisplayString(currentPoint) '  '  char(62) '  ' benDisplayString(currentPoint - lastPoint)]);
                                end
                            end
                        catch
                            set(handles.channelControl(index).displayText, 'string', '');
                        end
                    end
                    if strcmp(get(handles.displayCursors, 'checked'), 'on')
                        for index = find(~isnan(axisHandles))'                   
                            set(axisHandles(index), 'xData', [xCoord xCoord], 'yData', get(handles.axes(index), 'ylim'));                    
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

    function scrollMouse(varargin)
        if getappdata(0, 'EnableMiddleZoom')
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
                set(tempH.channelControl(whichAxis).minVal, 'string', sprintf(['%10.' sprintf('%0.0f', max([0 4 - log10(ylim(1) + .2 * diff(ylim) * varargin{2}.VerticalScrollCount)])) 'f'], ylim(1) + .2 * diff(ylim) * varargin{2}.VerticalScrollCount));
                set(tempH.channelControl(whichAxis).maxVal, 'string', sprintf(['%10.' sprintf('%0.0f', max([0 4 - log10(ylim(2) + .2 * diff(ylim) * varargin{2}.VerticalScrollCount)])) 'f'], ylim(2) + .2 * diff(ylim) * varargin{2}.VerticalScrollCount));
                newScale(tempH.channelControl(whichAxis).scaleType);
            elseif pointerLoc(1) <= 7 && pointerLoc(2) > 3
                % y axis on the left
                whereAt = (pointerLoc(2) - 3) / (figureLoc(4) - 3);            
                whichAxis = find([1 whereAt > cumsum(tempH.axisPortion(1:end-1))] & whereAt < cumsum(tempH.axisPortion), 1, 'first');    
                yCoord = (whereAt - sum(tempH.axisPortion(1:whichAxis - 1))) / tempH.axisPortion(whichAxis) * diff(get(tempH.axes(whichAxis),'Ylim')) + min(get(tempH.axes(whichAxis),'Ylim'));
                ylim = get(tempH.axes(whichAxis), 'ylim');

                % zoom                    
                set(tempH.channelControl(whichAxis).scaleType, 'value', 2);
                set(tempH.channelControl(whichAxis).minVal, 'string', sprintf(['%10.' sprintf('%0.0f', max([0 4 - log10(yCoord - .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount)])) 'f'], yCoord - .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
                set(tempH.channelControl(whichAxis).maxVal, 'string', sprintf(['%10.' sprintf('%0.0f', max([0 4 - log10(yCoord + .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount)])) 'f'], yCoord + .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
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
                    set(tempH.channelControl(whichAxis).minVal, 'string', sprintf(['%10.' sprintf('%0.0f', max([0 4 - log10(yCoord - .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount)])) 'f'], yCoord - .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
                    set(tempH.channelControl(whichAxis).maxVal, 'string', sprintf(['%10.' sprintf('%0.0f', max([0 4 - log10(yCoord + .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount)])) 'f'], yCoord + .5 .* (diff(ylim)) * 1.1 ^ varargin{2}.VerticalScrollCount));
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
    end

    function mouseUpScope(varargin)
        pointerLoc = get(handles.figure, 'CurrentPoint');
        figureLoc = get(handles.figure, 'Position');
        handles = get(handles.figure, 'userData');

        if handles.selectionType > 0
            switch handles.selectionType
                case 3
                    % relocate the axes bounds
                    for i = 1:handles.axesCount
                        set(handles.axes(i), 'position', [7 3 + sum(handles.axisPortion(1:i - 1)) * (figureLoc(4) - 3) figureLoc(3) - 55 handles.axisPortion(i) * (figureLoc(4) - 3)]);
                    end
                case 1
                    % resize in the x direction
                    blueRect = get(varargin{1}, 'children');
                    delete(blueRect(1));
                    if handles.selectionReference ~= pointerLoc(1)
                        xBounds = get(handles.axes(1), 'xlim');
                        myPoint = (pointerLoc(1) - 7) / (figureLoc(3) - 52)  * diff(xBounds) + min(xBounds);
                        if myPoint < handles.minX
                            myPoint = handles.minX;
                        end
                        if myPoint > handles.maxX
                            myPoint = handles.maxX;
                        end
                        set(handles.axes, 'xlim', sort([(handles.selectionReference - 7) / (figureLoc(3) - 52)  * diff(xBounds) + min(xBounds) myPoint]));
                        xBounds = get(handles.axes(1), 'xlim');
                        set(handles.zoom, 'string', sprintf('%7.1f', (handles.maxX - handles.minX) / diff(xBounds)));

                        zoomFactor = str2double(get(handles.zoom, 'string'));
                        newStep = 1 / zoomFactor / (1 - 1 / zoomFactor);
                        if newStep > 10
                            set(handles.slider, 'sliderStep', [1 newStep]);
                        else
                            set(handles.slider, 'sliderStep', [newStep / 10 newStep]);
                        end
                        % changed on 12.17.08 to avoid scroller value out
                        % of range warnings
                        set(handles.slider, 'value', max([min([(xBounds(1) - handles.minX) / (handles.maxX - handles.minX) / (1- 1 / zoomFactor) 1]) 0]));
                    end
                    set(handles.timeControl.autoScale, 'value', 0);
                    set(handles.timeControl.minVal, 'enable', 'on');
                    set(handles.timeControl.maxVal, 'enable', 'on');
                    set(handles.timeControl.minVal, 'string', sprintf('%10.1f', min(get(handles.axes(1), 'xlim'))));
                    set(handles.timeControl.maxVal, 'string', sprintf('%10.1f', max(get(handles.axes(1), 'xlim'))));
                    setAxisLabels(handles.axes(1));
                case 2
                    % resize left in the y direction
                    blueRect = get(varargin{1}, 'children');
                    delete(blueRect(1));
                    axesKids = get(handles.axes(handles.selectionAxis), 'child');
                    delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                    if handles.selectionReference ~= pointerLoc(2)
                        set(handles.axes(handles.selectionAxis), 'ylim', sort(([handles.selectionReference pointerLoc(2)] - 3 - (figureLoc(4) - 3) * sum(handles.axisPortion(1:handles.selectionAxis - 1))) / ((figureLoc(4) - 3) * handles.axisPortion(handles.selectionAxis)) * diff(get(handles.axes(handles.selectionAxis), 'ylim')) + min(get(handles.axes(handles.selectionAxis), 'ylim'))));
                    end
                    set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 2);
                    set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'on');
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'on');
                    set(handles.channelControl(handles.selectionAxis).minVal, 'string', sprintf('%10.3f', min(get(handles.axes(handles.selectionAxis), 'ylim'))));
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'string', sprintf('%10.3f', max(get(handles.axes(handles.selectionAxis), 'ylim'))));
                    if isappdata(handles.axes(handles.selectionAxis), 'events')
                        showEvents(handles.axes(handles.selectionAxis));
                    end
                    if isappdata(0, 'imageBrowser')
                        showFrameMarker(handles.axes(handles.selectionAxis));
                    end
                case 4
                    % resize right in the y direction
                    blueRect = get(varargin{1}, 'children');
                    delete(blueRect(1));                    
                    tempFields = fieldnames(handles.analysisAxis{handles.selectionAxis});
                    if numel(tempFields) > 1
                        % there exists at least one analysis axis, so zoom the
                        % last one drawn
                        tempAxis = handles.analysisAxis{handles.selectionAxis}.(tempFields{end});
                        if handles.selectionReference ~= pointerLoc(2)
                            set(tempAxis, 'ylim', sort(([handles.selectionReference pointerLoc(2)] - 3 - (figureLoc(4) - 3) * sum(handles.axisPortion(1:handles.selectionAxis - 1))) / ((figureLoc(4) - 3) * handles.axisPortion(handles.selectionAxis)) * diff(get(tempAxis, 'ylim')) + min(get(tempAxis, 'ylim'))));
                        end
                    else
                        % resize left in the y direction
                        axesKids = get(handles.axes(handles.selectionAxis), 'child');
                        delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                        if handles.selectionReference ~= pointerLoc(2)
                            set(handles.axes(handles.selectionAxis), 'ylim', sort(([handles.selectionReference pointerLoc(2)] - 3 - (figureLoc(4) - 3) * sum(handles.axisPortion(1:handles.selectionAxis - 1))) / ((figureLoc(4) - 3) * handles.axisPortion(handles.selectionAxis)) * diff(get(handles.axes(handles.selectionAxis), 'ylim')) + min(get(handles.axes(handles.selectionAxis), 'ylim'))));
                        end
                        set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 2);
                        set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'on');
                        set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'on');
                        set(handles.channelControl(handles.selectionAxis).minVal, 'string', sprintf('%10.3f', min(get(handles.axes(handles.selectionAxis), 'ylim'))));
                        set(handles.channelControl(handles.selectionAxis).maxVal, 'string', sprintf('%10.3f', max(get(handles.axes(handles.selectionAxis), 'ylim'))));
                        if isappdata(handles.axes(handles.selectionAxis), 'events')
                            showEvents(handles.axes(handles.selectionAxis));
                        end
                        if isappdata(0, 'imageBrowser')
                            showFrameMarker(handles.axes(handles.selectionAxis));
                        end
                    end
            end
        elseif strcmp(get(varargin{1}, 'SelectionType'), 'extend')
            if pointerLoc(1) <= 7 && pointerLoc(2) > 3
                % full scale y axis on left
                axesKids = get(handles.axes(handles.selectionAxis), 'child');
                set(axesKids(end - 1:end), 'visible', 'off');
                delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                set(handles.axes(handles.selectionAxis), 'YLimMode', 'auto');
                set(axesKids(end - 1:end), 'ydata', get(handles.axes(handles.selectionAxis), 'ylim'));
                set(axesKids(end - 1:end), 'visible', 'on');
                set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 1);
                set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'off');
                set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'off');
                if isappdata(handles.axes(handles.selectionAxis), 'events')
                    showEvents(handles.axes(handles.selectionAxis));
                end
                if isappdata(0, 'imageBrowser')
                    showFrameMarker(handles.axes(handles.selectionAxis));
                end
            elseif pointerLoc(1) >= figureLoc(3) - 48 && pointerLoc(1) <= figureLoc(3) - 43 && pointerLoc(2) > 3
                % full scale y axis on right
                tempFields = fieldnames(handles.analysisAxis{handles.selectionAxis});
                if numel(tempFields) > 1
                    % there exists at least one analysis axis, so zoom the
                    % last one drawn
                    tempAxis = handles.analysisAxis{handles.selectionAxis}.(tempFields{end});
                    set(tempAxis, 'YLimMode', 'auto');
                else
                    % full scale y axis on left
                    axesKids = get(handles.axes(handles.selectionAxis), 'child');
                    set(axesKids(end - 1:end), 'visible', 'off');
                    delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                    set(handles.axes(handles.selectionAxis), 'YLimMode', 'auto');
                    set(axesKids(end - 1:end), 'ydata', get(handles.axes(handles.selectionAxis), 'ylim'));
                    set(axesKids(end - 1:end), 'visible', 'on');
                    set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 1);
                    set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'off');
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'off');
                    if isappdata(handles.axes(handles.selectionAxis), 'events')
                        showEvents(handles.axes(handles.selectionAxis));
                    end
                    if isappdata(0, 'imageBrowser')
                        showFrameMarker(handles.axes(handles.selectionAxis));
                    end
                end
            elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 52 && pointerLoc(2) <= 3
                % full scale x axis
                set(handles.axes, 'XLim', [handles.minX handles.maxX]);
                set(handles.zoom, 'string', '1.0');
                set(handles.slider, 'sliderStep', [1 1/0]);
                set(handles.timeControl.autoScale, 'value', 1);
                set(handles.timeControl.minVal, 'enable', 'off');
                set(handles.timeControl.maxVal, 'enable', 'off');
                setAxisLabels(handles.axes(1))
            elseif pointerLoc(1) > 7 && pointerLoc(1) < figureLoc(3) - 48 && pointerLoc(2) > 3 && isappdata(handles.figure, 'rbStart')
                startPoint = getappdata(handles.figure, 'rbStart');
                startPoint = startPoint(1,:);
                stopPoint = get(gca,'CurrentPoint');
                stopPoint = stopPoint(1,:);

                % resize to box
                axesKids = get(handles.axes(handles.selectionAxis), 'child');
                delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                if startPoint(1) ~= stopPoint(1)
                    if stopPoint(1) < handles.minX
                        stopPoint(1) = handles.minX;
                    end
                    if stopPoint(1) > handles.maxX
                        stopPoint(1) = handles.maxX;
                    end
                    set(handles.axes, 'xlim', sort([startPoint(1) stopPoint(1)]));
                    xBounds = get(handles.axes(1), 'xlim');
                    set(handles.zoom, 'string', sprintf('%7.1f', (handles.maxX - handles.minX) / diff(xBounds)));

                    zoomFactor = str2double(get(handles.zoom, 'string'));
                    newStep = 1 / zoomFactor / (1 - 1 / zoomFactor);
                    if newStep > 10
                        set(handles.slider, 'sliderStep', [1 newStep]);
                    else
                        set(handles.slider, 'sliderStep', [newStep / 10 newStep]);
                    end
                    set(handles.slider, 'value', max([min([(xBounds(1) - handles.minX) / (handles.maxX - handles.minX) / (1- 1 / zoomFactor) 1]) 0]));                    
                    setAxisLabels(handles.axes(1));
                end
                if startPoint(2) ~= stopPoint(2)
                    set(gca, 'ylim', sort([startPoint(2) stopPoint(2)]));

                    set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 2);
                    set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'on');
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'on');
                    set(handles.channelControl(handles.selectionAxis).minVal, 'string', sprintf('%10.3f', min(get(gca, 'ylim'))));
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'string', sprintf('%10.3f', max(get(gca, 'ylim'))));

                    set(handles.timeControl.autoScale, 'value', 0);
                    set(handles.timeControl.minVal, 'enable', 'on');
                    set(handles.timeControl.maxVal, 'enable', 'on');
                    set(handles.timeControl.minVal, 'string', sprintf('%10.1f', min(get(handles.axes(1), 'xlim'))));
                    set(handles.timeControl.maxVal, 'string', sprintf('%10.1f', max(get(handles.axes(1), 'xlim'))));
                else
                    % full scale x axis
                    set(handles.axes, 'XLim', [handles.minX handles.maxX]);
                    set(handles.zoom, 'string', '1.0');
                    set(handles.slider, 'sliderStep', [1 1/0]);
                    set(handles.timeControl.autoScale, 'value', 1);
                    set(handles.timeControl.minVal, 'enable', 'off');
                    set(handles.timeControl.maxVal, 'enable', 'off');
                    setAxisLabels(handles.axes(1))

                    % full scale y axis on left
                    axesKids = get(handles.axes(handles.selectionAxis), 'child');
                    set(axesKids(end - 1:end), 'visible', 'off');
                    delete(axesKids(strcmp(get(axesKids, 'userData'), 'events')));
                    set(handles.axes(handles.selectionAxis), 'YLimMode', 'auto');
                    set(axesKids(end - 1:end), 'ydata', get(handles.axes(handles.selectionAxis), 'ylim'));
                    set(axesKids(end - 1:end), 'visible', 'on');
                    set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 1);
                    set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'off');
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'off');
                    set(handles.channelControl(handles.selectionAxis).scaleType, 'value', 1);
                    set(handles.channelControl(handles.selectionAxis).minVal, 'enable', 'off');
                    set(handles.channelControl(handles.selectionAxis).maxVal, 'enable', 'off');

                    set(handles.timeControl.autoScale, 'value', 1);
                    set(handles.timeControl.minVal, 'enable', 'off');
                    set(handles.timeControl.maxVal, 'enable', 'off');
                end

                if isappdata(handles.axes(handles.selectionAxis), 'events')
                    showEvents(handles.axes(handles.selectionAxis));
                end
                if isappdata(0, 'imageBrowser')
                    showFrameMarker(handles.axes(handles.selectionAxis));
                end
            end
        end
        handles.selectionType = 0;
        handles.selectionReference = 0;
        set(handles.figure, 'userData', handles);        
    end

    function updateTrace(scopeRef, axisNum)
    % update the traces   
        if ~isempty(get(scopeRef, 'WindowButtonMotionFcn'))
            setappdata(scopeRef, 'WindowButtonMotionFcn', get(scopeRef, 'WindowButtonMotionFcn'));
        end
        set(scopeRef, 'WindowButtonMotionFcn', []);    
        handles = get(scopeRef, 'userData');
        if ischar(axisNum) && strcmp(axisNum, 'all')
            for outerLoop = 1:handles.axesCount
                % delete analysis axes
                for i = fieldnames(handles.analysisAxis{outerLoop})'
                    if ~strcmp(i{1}, 'None')
                        delete(handles.analysisAxis{outerLoop}.(i{1}));
                        set(handles.axes(outerLoop), 'color', [1 1 1]);
                    end
                end
                                
                % update the axis
                updateTrace(scopeRef, outerLoop);
                handles.analysisAxis{outerLoop} = struct('None', []);
            end
            set(scopeRef, 'userData', handles);
            return
        end        
        handles.dataChanged(axisNum) = 0;
        set(0, 'currentFigure', scopeRef);
        set(scopeRef, 'currentAxes', handles.axes(axisNum));

        % delete all of the children except the cursors
        kids = get(handles.axes(axisNum), 'children');
        delete(kids(1:end - 2));
        set(kids(end - 1:end), 'visible', 'off');
        commandText = cell2mat(get(handles.channelControl(axisNum).commandText, 'string'));  
        allData = yData{get(handles.channelControl(axisNum).channel, 'value')};

        % bring over the file names
        if exist('protocolData', 'var')
            % bring over the data
            % modified by BWS on 12/8/08 to include artifactDelay
            retValues = get(handles.displayBlankArtifacts, 'userData'); %ms
            artifactLength=retValues(1);
            if numel(retValues)==2
                artifactDelay=retValues(2);
            else
                artifactDelay=0;
            end 
            % should the stimulus artifacts be blanked?
            if strcmp(get(handles.displayBlankArtifacts, 'checked'), 'on') && artifactLength > 0
                for i = 1:numel(protocolData)
                    stimTimes = findStims(protocolData(i), 1);
                    for ttlIndex = 1:numel(protocolData(i).ttlEnable)
                        if ~isempty(stimTimes{ttlIndex})
                            stimTimes{ttlIndex}(:,1)=stimTimes{ttlIndex}(:,1)+artifactDelay;
                            stimTimes{ttlIndex}(:,2) = stimTimes{ttlIndex}(:,2) + artifactDelay+artifactLength;            
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
                ampNames = get(handles.channelControl(axisNum).channel, 'string');
                ampSelection = get(handles.channelControl(axisNum).channel, 'value');
                ampNum = double(ampNames{ampSelection}(5)) - 64;
            end    
        end

        % are they spike aligned?
        if strcmp(get(handles.displayAligned, 'checked'), 'on')
            alignmentBounds = get(handles.displayAligned, 'userData');    
            spikeData = evalin('base', ['zData.traceData{' sprintf('%0.0f', alignmentBounds(3)) '}(' sprintf('%0.0f', round(alignmentBounds(1) / handles.xStep)) ':' sprintf('%0.0f', round(alignmentBounds(2) / handles.xStep)) ', :)']);
            removedTraces = [];
            for i = 1:evalin('base', 'length(zData.protocol)')
                spikes = detectSpikes(spikeData(:,i));
                if isempty(spikes)
                    %disp(['No spikes in alignment interval for ' traceNames{i} '.  This trace will not be displayed'])
                    removedTraces(end + 1) = i;
                else
                    allData(:,i) = circshift(allData(:,i), [-spikes(1) 0]);
                end
            end
            allData(:, removedTraces) = [];
            handles.dataChanged(axisNum) = 1;
        end

        % should we subtract a reference trace?
        if handles.useReference(axisNum)
            refTrace = getappdata(handles.axes(axisNum), 'referenceTrace');
            if strcmp(get(handles.subtractRefTrace, 'check'), 'off')
                if get(handles.channelControl(axisNum).offset, 'value')
                    if strcmp(get(handles.displayAligned, 'checked'), 'on')
                        line('parent', handles.axes(axisNum), 'xData', (0:size(allData, 1) - 1) * handles.xStep, 'yData', [refTrace(1:min([end size(allData, 1)])); nan(size(allData, 1)-size(refTrace, 1),1)] - mean(refTrace(round(alignmentBounds(1) / handles.xStep) - 10:round(alignmentBounds(1) / handles.xStep))), 'color', [1 0 0], 'userData', 'data', 'displayName', ['Reference, ' getappdata(handles.axes(axisNum), 'referenceName')]);
                    else
                        line('parent', handles.axes(axisNum), 'xData', (0:size(allData, 1) - 1) * handles.xStep, 'yData', [refTrace(1:min([end size(allData, 1)])); nan(size(allData, 1)-size(refTrace, 1),1)] - mean(refTrace(int32(max([0.2 min(get(handles.axes(1), 'xlim'))])/handles.xStep:min(get(handles.axes(1), 'xlim'))/handles.xStep + 10))), 'color', [1 0 0], 'userData', 'data', 'displayName', ['Reference, ' getappdata(handles.axes(axisNum), 'referenceName')]);
                    end
                else
                    line('parent', handles.axes(axisNum), 'xData', (0:size(allData, 1) - 1) * handles.xStep, 'yData', [refTrace(1:min([end size(allData, 1)])); nan(size(allData, 1)-size(refTrace, 1),1)], 'color', [1 0 0], 'userData', 'data', 'displayName', ['Reference, ' getappdata(handles.axes(axisNum), 'referenceName')]);
                end
            else
                if size(allData, 1) == length(refTrace)
                    allData(1:size(refTrace, 1), :) = allData(1:size(refTrace, 1), :) - repmat(refTrace, 1, size(allData, 2));
                    handles.dataChanged(axisNum) = 1;
                end
            end
        end

        % cycle through zData and pull out the correct traces
        if strcmp(get(handles.displayTraces, 'checked'), 'on')
            if length(commandText) > 5 && strcmp(commandText(1:6), 'events')
%                 tempEvents = struct('traceName', '', 'data', [], 'type', '');
                if numel(strfind(commandText, 'events')) > 1
                    oldEvents = getappdata(handles.axes(axisNum), 'events');
                end
            elseif strfind(commandText, 'events')
                oldEvents = getappdata(handles.axes(axisNum), 'events');
            end	
            if strcmp(get(handles.colorCoded, 'checked'), 'on')
                colors = colorSpread(size(allData, 2));
                if isempty(findobj(handles.figure, 'tag', 'colorLegend'))
                    % generate a menu that is a color-coding legend
                    mnuHandle = uimenu(handles.figure, 'Label', 'Color Codes', 'tag', 'colorLegend');
                    for i = 1:size(allData, 2)
                        uimenu(mnuHandle, 'foregroundColor', colors(i,:), 'Label', traceNames{i});
                    end
                end
            else
                colors = repmat([0 0 0], size(allData, 2), 1);
                delete(findobj(handles.figure, 'tag', 'colorLegend'));
            end
            for i = 1:size(allData, 2)
                % evaluate command on trace if necessary
                if ~isempty(commandText)
                    if isempty(strfind(commandText, 'allData'))
                        if ~isempty(strfind(commandText, 'protocol'))
                            protocol = protocolData(i);
                        end                
                        if ~isempty(strfind(commandText, 'events')) && exist('oldEvents', 'var') && ~isempty(oldEvents)
                            events = oldEvents(i);
                        end
                        data = allData(:,i);
                        try
                            set(handles.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / handles.xStep, handles.minX)));
                        catch
                            % not apparently something that returns a value
                            try
                                eval(msec2point(commandText, 1 / handles.xStep, handles.minX));                                
                            catch
                                    msgbox(['Error in text box function of axis #' sprintf('%0.0f', axisNum)]);
                            end
                        end
                        try
                            if any(allData(:,i) ~= data)
                                handles.dataChanged(axisNum) = 1;
                            end
                            allData(:,i) = data;
                        catch
                            msgbox(['Modified trace has dimensions [' num2str(size(data)) '], but should have dimensions [' size(allData, 1) ' 1], so the trace was not modified']);
                        end
                        
                        if ~isempty(strfind(commandText, 'events'))
                            tempEvents(i) = events;
                        end					
                    elseif i == 1
                        % only allow statement which act on allData to act once
                        if ~isempty(strfind(commandText, 'protocol'))
                            protocol = protocolData;
                        end
                        try
                            set(handles.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / handles.xStep, handles.minX)));
                        catch
                            % not apparently something that returns a value
                            eval(msec2point(commandText, 1 / handles.xStep, handles.minX));                                
                        end
                    end
                end

                % display the data trace
                if get(handles.channelControl(axisNum).offset, 'value')
                    if strcmp(get(handles.displayAligned, 'checked'), 'on')
                        line('parent', handles.axes(axisNum), 'xData', xData', 'yData', allData(:,i) - mean(allData(round(alignmentBounds(1) / handles.xStep) - 10:round(alignmentBounds(1) / handles.xStep), i), 1), 'color', colors(i,:), 'userData', 'data', 'displayName', traceNames{i});                
                    else
                        line('parent', handles.axes(axisNum), 'xData', xData', 'yData', allData(:,i) - mean(allData(int32(max([1 fix((min(get(handles.axes(1), 'xlim')) - handles.minX) / handles.xStep)]) + (1:min([10 diff(get(handles.axes(1), 'xlim')) / handles.xStep]))), i), 1), 'color', colors(i,:), 'userData', 'data', 'displayName', traceNames{i});
                    end
                    handles.dataChanged(axisNum) = 1;
                else
                    line('parent', handles.axes(axisNum), 'xData', xData', 'yData', allData(:,i), 'color', colors(i,:), 'userData', 'data', 'displayName', traceNames{i});
                end
            end

            if length(commandText) > 8 && strcmp(commandText(1:6), 'events')
                setappdata(handles.axes(axisNum), 'events', tempEvents);
            end			
        end

        if strcmp(get(handles.displayMean, 'checked'), 'on')
            % find the mean
            data = mean(allData, 2);

            % evaluate command on trace if necessary
            commandText = cell2mat(get(handles.channelControl(axisNum).commandText, 'string'));
            if ~isempty(commandText)     
                if ~isempty(strfind(commandText, 'protocol'))
                    protocol = protocolData(1);
                end                
                if ~isempty(strfind(commandText, 'events')) && exist('oldEvents', 'var')
                    events = oldEvents(i);
                end
                try
                    % if this modifies the data and the traces are not
                    % being displayed then the dataChanged flag will be
                    % wrong
                    set(handles.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / handles.xStep, handles.minX)));
                catch
                    eval(msec2point(commandText, 1 / handles.xStep, handles.minX));
                end
                if ~isempty(strfind(commandText, 'events'))
                    tempEvents(i) = events;
                end					
            end

            % display the mean trace
            tempHandles = get(handles.displayMean, 'userData');
            if get(handles.channelControl(axisNum).offset, 'value')
                if strcmp(get(handles.displayAligned, 'checked'), 'on')
                    tempHandles(axisNum) = line('parent', handles.axes(axisNum), 'xData', xData', 'yData', data - mean(data(round(alignmentBounds(1) / handles.xStep) - 10:round(alignmentBounds(1) / handles.xStep))), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Mean, ' get(handles.figure, 'name')]);
                else
                    tempHandles(axisNum) = line('parent', handles.axes(axisNum), 'xData', xData', 'yData', data - mean(data(int32(max([0.2 min(get(handles.axes(1), 'xlim'))])/handles.xStep:min(get(handles.axes(1), 'xlim'))/handles.xStep + 10))), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Mean, ' get(handles.figure, 'name')]);
                end
                handles.dataChanged(axisNum) = 1;
            else
                tempHandles(axisNum) = line('parent', handles.axes(axisNum), 'xData', xData', 'yData', data, 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Mean, ' get(handles.figure, 'name')]);
            end
            set(handles.displayMean, 'userData', tempHandles);
        end

        if strcmp(get(handles.displayMedian, 'checked'), 'on')
            data = median(allData, 2);

            % evaluate command on trace if necessary
            commandText = cell2mat(get(handles.channelControl(axisNum).commandText, 'string'));
            if ~isempty(commandText)     
                if ~isempty(strfind(commandText, 'protocol'))
                    protocol = protocolData(1);
                end                
                if ~isempty(strfind(commandText, 'events')) && exist('oldEvents', 'var')
                    events = oldEvents(i);
                end
                try
                    % if this modifies the data and the traces are not
                    % being displayed then the dataChanged flag will be
                    % wrong                    
                    set(handles.channelControl(axisNum).resultText, 'string', eval(msec2point(commandText, 1 / handles.xStep, handles.minX)));
                catch
                    eval(msec2point(commandText, 1 / handles.xStep, handles.minX));
                end
                if ~isempty(strfind(commandText, 'events'))
                    tempEvents(i) = events;
                end					
            end

            % display the median trace
            tempHandles = get(handles.displayMedian, 'userData');
            if get(handles.channelControl(axisNum).offset, 'value')
                if strcmp(get(handles.displayAligned, 'checked'), 'on')
                    tempHandles(axisNum) = line('parent', handles.axes(axisNum), 'xData', xData', 'yData', data - mean(data(round(alignmentBounds(1) / handles.xStep) - 10:round(alignmentBounds(1) / handles.xStep))), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Median, ' get(handles.figure, 'name')]);
                else
                    tempHandles(axisNum) =  line('parent', handles.axes(axisNum), 'xData', xData', 'yData', data - mean(data(int32(max([0.2 min(get(handles.axes(1), 'xlim'))])/handles.xStep:min(get(handles.axes(1), 'xlim'))/handles.xStep + 10))), 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Median, ' get(handles.figure, 'name')]);
                end
                handles.dataChanged(axisNum) = 1;
            else
                tempHandles(axisNum) = line('parent', handles.axes(axisNum), 'xData', xData', 'yData', data, 'userData', 'data', 'color', [0 0 1], 'lineWidth', 2, 'displayName', ['Median, ' get(handles.figure, 'name')]);
            end
            set(handles.displayMedian, 'userData', tempHandles);
        end

        if strcmp(get(handles.displayEvents, 'checked'), 'on')
            showEvents(handles.axes(axisNum));
        end
        if strcmp(get(handles.displayBlankArtifacts, 'checked'), 'on')
            showStims(handles.figure);
        end
        if isappdata(0, 'imageBrowser')
            showFrameMarker(handles.axes(axisNum));
        end

        % set the cursors to the right height
        set(kids(end), 'visible', 'on', 'ydata', get(handles.axes(axisNum), 'ylim'));  
        if handles.markerFixed == 0
            set(kids(end - 1), 'visible', 'off', 'ydata', get(handles.axes(axisNum), 'ylim'));  
        else
            set(kids(end - 1), 'visible', 'on', 'ydata', get(handles.axes(axisNum), 'ylim'));  
        end
        try
            newScale(handles.channelControl(axisNum).scaleType);
        catch
            msgbox('Error in rescaling')
        end
        % make sure that the cursors are not off of the scale
        if get(kids(end - 1), 'xdata') > max(get(handles.axes(axisNum), 'xlim'))
            set(kids(end - 1), 'xdata', [0 0]);
            handles.markerLoc = 0; % index into y-data of the reference line
            handles.markerTime = 0; % time of the reference line
            handles.markerFixed = 0; % if the reference line is present
        end
        if get(kids(end), 'xdata') > max(get(handles.axes(axisNum), 'xlim'))
            set(kids(end), 'xdata', [0 0]);
        end
        set(scopeRef, 'userData', handles);
         set(scopeRef, 'WindowButtonMotionFcn',getappdata(scopeRef, 'WindowButtonMotionFcn'));
    end
end

function windowKeyPress(varargin)
   % modified by BWS to stop errant arrow key presses to wrong fileBrowser
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
    set(handles.slider,'units', 'characters', 'position', [0 0 figPos(3) 1])
end

function closeScope(varargin)
    handles = getappdata(0, 'scopes');
    if length(handles) > 1
        whichScope = find(handles == varargin{1});
        if ~isempty(whichScope)
            setappdata(0, 'scopes', handles([1:whichScope - 1 whichScope + 1:end]));
        end
    else
        whichScope = find(handles == varargin{1}, 1);
        if ~isempty(whichScope)
            rmappdata(0, 'scopes');
        end
    end
    rmappdata(0, 'EnableMiddleZoom');
    delete(varargin{1})
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Begin Menubar Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        printInformation = '{[protocol.fileName '', '' channelName], [protocol.ampCellLocationName{ampNum}, '', Drug: '' protocol.drug '', V = '' sprintf(''%1.1f'', protocol.startingValues(find(cellfun(@(x) x(end) == ''V'' && ~isempty(strfind(x, [''Amp '' char(64 + ampNum)])) && isempty(strfind(x, ''Stim'')), protocol.channelNames)))) '', I = '' sprintf(''%1.1f'', protocol.startingValues(find(cellfun(@(x) x(end) == ''I'' && ~isempty(strfind(x, [''Amp '' char(64 + ampNum)])) && isempty(strfind(x, ''Stim'')), protocol.channelNames))))]}';
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
                printWithScaleBars;
            case 2
                % print two on top of each other
                figHandle = figure('visible', 'off', 'inverthardcopy', 'off', 'color', [1 1 1], 'paperorientation', 'portrait', 'numbertitle', 'off', 'paperposition', [.25 .25 8 10.5]);
                newHandle = get(copyobj(dataTraces(1), subplot(2,1,1)), 'parent');
                set(gca, 'ylim', get(handles.axes(axesIndex), 'ylim'));
                % copy over any associated analysis objects
                titleData = '';
                for handleIndex = kids'
                   if (strcmp(get(handleIndex, 'displayName') , getappdata(dataTraces(1), 'traceName')) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                       copyobj(handleIndex, gca);
                       if isappdata(handleIndex, 'printData')
                           titleData = [titleData ', ' getappdata(handleIndex, 'printData')];
                       end
                   end
                end
                protocol = evalin('base', 'zData.protocol(1)');
                try
                    titleData = eval(printInformation);
                    title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                catch
                    title(protocol.fileName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                end
                prepForPrint(channelName(end))
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

                newHandle = get(copyobj(dataTraces(2), subplot(2,1,2)), 'parent');
                set(gca, 'ylim', get(handles.axes(axesIndex), 'ylim'));
                % copy over any associated analysis objects
                titleData = '';
                for handleIndex = kids'
                   if (strcmp(get(handleIndex, 'displayName') , getappdata(dataTraces(2), 'traceName')) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                       copyobj(handleIndex, gca);
                       if isappdata(handleIndex, 'printData')
                           titleData = [titleData ', ' getappdata(handleIndex, 'printData')];
                       end
                   end
                end
                protocol = evalin('base', 'zData.protocol(2)');
                try
                    titleData = eval(printInformation);
                    title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                catch
                    title(protocol.fileName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                end
                prepForPrint(channelName(end))
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
                for i = dataTraces'
                    newHandle = get(copyobj(i, subplot(2,2,plotNum)), 'parent');
                    set(newHandle, 'ylim', get(handles.axes(axesIndex), 'ylim'));

                    % add an offset label
                    kids = get(newHandle, 'children');
                    yData = get(kids(end), 'ydata');
                    yData = yData(~isnan(yData));
                    yData = mean(yData(1:min([10 length(yData)])));
                    switch channelName(end)
                        case {'V', 'F'}
                            switch 1
                                case abs(yData) >= 1000
                                    yLabel = [sprintf('%0.0f', yData / 1000) ' V   '];
                                case abs(yData) >= 1
                                    yLabel = [sprintf('%0.0f', yData) ' mV   '];
                                otherwise
                                    yLabel = [sprintf('%0.0f', yData * 1000) ' ' char(181) 'V   '];
                            end
                        case 'I'
                            switch 1
                                case abs(yData) >= 1000000
                                    yLabel = [sprintf('%0.0f', yData / 1000000) ' ' char(181) 'A   '];
                                case abs(yData) >= 1000
                                    yLabel = [sprintf('%0.0f', yData / 1000) ' nA   '];
                                case abs(yData) >= 1
                                    yLabel = [sprintf('%0.0f', yData) ' pA   '];
                                otherwise
                                    yLabel = [sprintf('%0.0f', yData * 1000) ' fA   '];
                            end
                        otherwise
                            yLabel = sprintf('%0.0f', yData);
                    end
                    text(min(get(newHandle, 'xlim')), yData, yLabel, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'parent', newHandle, 'fontsize', 8);

                    % copy over any associated analysis objects
                    for handleIndex = kids'
                       if (strcmp(get(handleIndex, 'displayName') , getappdata(i, 'traceName')) && ~strcmp(get(handleIndex, 'userData'), 'data')) || strcmp(get(handleIndex, 'userData'), 'stims')
                           copyobj(handleIndex, newHandle);
                           if isappdata(handleIndex, 'printData')
                               titleData = [titleData ', ' getappdata(handleIndex, 'printData')];
                           end
                       end
                    end
                    protocol = evalin('base', ['zData.protocol(' sprintf('%0.0f', find(i == dataTraces)) ')']);
                    try
                        titleData = eval(printInformation);
                        title(titleData, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    catch
                        title(protocol.fileName, 'color', [0 0 0], 'fontsize', 5, 'interpreter', 'none');
                    end
                    set(newHandle, 'xtick', [], 'xticklabel', '', 'ytick', [], 'yticklabel', '', 'box', 'off', 'xColor', [1 1 1], 'yColor', [1 1 1]);

                    % copy over any analysis axes
                    analysisAxes = fieldnames(handles.analysisAxis{axesIndex});
                    if numel(analysisAxes) > 1
                        for j = 2:numel(analysisAxes)
                            tempHandle = copyobj(handles.analysisAxis{axesIndex}.(analysisAxes{j}), figHandle);
                            set(tempHandle, 'color', 'none', 'ycolor', [1 1 1], 'xcolor', [1 1 1], 'units', get(newHandle, 'units'), 'position', get(newHandle, 'position'));
                            kidKids = get(tempHandle, 'children');
                            delete(kidKids([3:find(dataTraces == i)  find(dataTraces == i):end]));
                            set(kidKids(1:2), 'color', get(kidKids(find(dataTraces == i, 1)), 'color'));
                        end
                    end

                    plotNum = plotNum + 1;
                    if plotNum == 5
                        plotNum = 1;
                        prepForPrint(channelName(end));
                        if numel(analysisAxes) > 1
							for j = 2:numel(analysisAxes)
								prepForPrint(tempHandle, get(get(handles.analysisAxis{axesIndex}.(analysisAxes{axesIndex}{j}), 'ylabel'), 'string'), 'yOnly');
							end
                        end
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
                    if numel(analysisAxes) > 1
						for j = 2:numel(analysisAxes)
							prepForPrint(tempHandle, get(get(handles.analysisAxis{axesIndex}.(analysisAxes{axesIndex}{j}), 'ylabel'), 'string'), 'yOnly');
						end
                    end
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

function reloadConfig(varargin)
% load the configuration file from mPhys.ini
try
    whichSection = 1;
    fid = fopen('d:\LabWorld\INIs\mPhys.ini', 'r');
    if fid > 0
            handles = get(gcf, 'userData');
            if ~isstruct(handles)
                fclose(fid);
                return
            end
            setappdata(0, 'EnableMiddleZoom', 1);
            tLine = fgetl(fid);
            while ischar(tLine)
                lineEnd = find(tLine == ';') - 1;
                if isempty(lineEnd)
                    lineEnd = length(tLine);
                end
                textPart = strtrim(tLine(1:lineEnd));
                if ~isempty(textPart)
                    % not a comment
                    switch textPart
                        case '[Configuration]'
                            whichSection = 1;
                        case '[Export]'
                            whichSection = 2;
                        case '[BonusText]'
                            whichSection = 3;
                        otherwise
                            switch whichSection
                                case 1
                                    if ~isempty(strfind(textPart, 'DisplayAllTraces'))
%                                         disp(textPart)
                                    elseif ~isempty(strfind(textPart, 'DisplayBonusText'))
                                        if str2double(textPart(find(textPart == '=', 1) + 1:end))
                                            set(handles.traceName, 'visible', 'on');   
                                        else
                                            set(handles.traceName, 'visible', 'off');   
                                        end
                                    elseif ~isempty(strfind(textPart, 'UseDefaultScales'))                                        
                                        if str2double(textPart(find(textPart == '=', 1) + 1:end))
                                            set([handles.channelControl.scaleType], 'value', 6);
                                            channelNames = get(handles.channelControl(1).channel, 'string');
                                            for i = 1:numel(handles.channelControl)
                                                if channelNames{get(handles.channelControl(i).channel, 'value')}(end) == 'V'
                                                    set(handles.channelControl(i).maxVal, 'string', '40'); % hard-coded minimum and maximum values for channel display
                                                    set(handles.channelControl(i).minVal, 'string', '-100');
                                                else
                                                    set(handles.channelControl(i).maxVal, 'string', '500');
                                                    set(handles.channelControl(i).minVal, 'string', '-500');
                                                end
                                            end
                                        else
                                            set([handles.channelControl.scaleType], 'value', 1);
                                        end
                                        newScale(gcf);
                                    elseif ~isempty(strfind(textPart, 'EnableMiddleZoom'))
                                        setappdata(0, 'EnableMiddleZoom', str2double(textPart(find(textPart == '=', 1) + 1:end)))                   
                                    elseif ~isempty(strfind(textPart, 'ExportHeight'))      
                                        setappdata(0, 'ExportHeight', str2double(textPart(find(textPart == '=', 1) + 1:end)));
                                    elseif ~isempty(strfind(textPart, 'ExportWidth'))      
                                        setappdata(0, 'ExportWidth', str2double(textPart(find(textPart == '=', 1) + 1:end)));
                                    elseif ~isempty(strfind(textPart, 'ExportWithOffset'))      
                                        setappdata(0, 'ExportWithOffset', str2double(textPart(find(textPart == '=', 1) + 1:end)));
                                    elseif ~isempty(strfind(textPart, 'ScopeBottom'))      
                                        currentPos = get(getappdata(0, 'scopes'), 'position');                                        
                                        set(getappdata(0, 'scopes'), 'position', [currentPos(1) str2double(textPart(find(textPart == '=', 1) + 1:end)) currentPos(3:4)]);
                                    elseif ~isempty(strfind(textPart, 'ScopeLeft'))      
                                        currentPos = get(getappdata(0, 'scopes'), 'position');                                        
                                        set(getappdata(0, 'scopes'), 'position', [str2double(textPart(find(textPart == '=', 1) + 1:end)) currentPos(2:4)]);
                                    elseif ~isempty(strfind(textPart, 'ScopeWidth'))      
                                        currentPos = get(getappdata(0, 'scopes'), 'position');                                        
                                        set(getappdata(0, 'scopes'), 'position', [currentPos(1:2) str2double(textPart(find(textPart == '=', 1) + 1:end)) currentPos(4)]);
                                        resize(getappdata(0, 'scopes'));
                                    elseif ~isempty(strfind(textPart, 'ScopeHeight'))      
                                        currentPos = get(getappdata(0, 'scopes'), 'position');                                        
                                        set(getappdata(0, 'scopes'), 'position', [currentPos(1:3) str2double(textPart(find(textPart == '=', 1) + 1:end))]);      
                                        resize(getappdata(0, 'scopes'));
                                    end
                                case 2 % export
                                    exportText.(textPart(1:find(textPart == '=', 1) - 1)) = str2double(textPart(find(textPart == '=', 1) + 1:end));                    
                                    if strcmp(textPart(1:find(textPart == '=', 1) - 1), 'BaselineVmImByTrace')
                                        if ispref('newScope', 'exportSettings')
                                            tempPref = getpref('newScope', 'exportSettings');
                                        else
                                            tempPref = [0 0 0 0];
                                        end
                                        setpref('newScope', 'exportSettings', [tempPref(1:3) str2double(textPart(find(textPart == '=', 1) + 1:end))]);
                                    end
                                case 3 % bonusText
                                    bonusText.(textPart(1:find(textPart == '=', 1) - 1)) = str2double(textPart(find(textPart == '=', 1) + 1:end));                                                               
                            end
                    end                                                
                end
                tLine = fgetl(fid);
            end
        fclose(fid);
        setappdata(0, 'bonusText', bonusText);
        setappdata(0, 'exportText', exportText);
        setappdata(gcf, 'extraPrintText', evaluateBonusText(evalin('base', 'zData.protocol(1)')));
    end
catch
     msgbox('Error loading config file d:\LabWorld\INIs\mPhys.ini')
end
end

function printInformation(varargin)
	% set what information is added to plots
	if ~ispref('newScope', 'printInformation')
		setpref('newScope', 'printInformation', '{[protocol.fileName '', '' channelName], [''Drug: '' protocol.drug]}')
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
    handles.analysisAxis{afterWhich + 1:handles.axesCount} = handles.analysisAxis{afterWhich:handles.axesCount - 1};
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
    try
        feval(getappdata(handles.figure, 'updateFunction'), handles.figure, afterWhich);
    catch
            % not set yet
    end
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
            if whichChan == handles.axesCount + 1
                handles.axisPortion(handles.axesCount) = handles.axisPortion(handles.axesCount) + handles.axisPortion(handles.axesCount + 1);
            else
                handles.axisPortion(whichChan + 1) = handles.axisPortion(whichChan + 1) + handles.axisPortion(whichChan);
                handles.axisPortion(whichChan:handles.axesCount) = handles.axisPortion(whichChan + 1:handles.axesCount + 1);
            end
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
            xData = {get(lineKids, 'displayName')};
    end
    if varargin{3} > 7
        clipText = '';
        if iscell(xData)
            % names
            for i = 1:numel(xData)
                clipText = [clipText xData{i} char(9)];
            end
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
        whichChannel = listdlg('ListString', evalin('base', 'zData.protocol(1).channelNames'), 'SelectionMode', 'single', 'PromptString', 'Channel to search for spikes:', 'InitialValue', lastValues(3));
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
                if maxX > handles.maxX
                    maxX = handles.maxX;
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

function setDisplayTopText(varargin)
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1}, 'checked', 'off');
    else
        set(varargin{1}, 'checked', 'on');
    end
    handles = get(gcf, 'userData');
    set(handles.traceName, 'visible', get(varargin{1}, 'checked'));
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
% Updated by BWS on 12/8/08 to vary start of blanking with lastDelay
    persistent lastValue lastDelay
    if isempty(lastValue)
        lastValue = 0.6;
    end
    if isempty(lastDelay)
        lastDelay=0.8;
    end
    if strcmp(get(varargin{1}, 'checked'), 'on')
        set(varargin{1}, 'checked', 'off');
        feval(getappdata(gcf, 'updateFunction'), ancestor(varargin{1}, 'figure'), 'all');
    else
        whereBounds = inputdlg({'Duration (msec)', 'Delay (msec)' },'Artifact blanking',1, {num2str(lastValue),num2str(lastDelay)});
        newValue=whereBounds{1};
        newDelay=whereBounds{2};
        if numel(newValue) > 0 && str2double(newValue) >= 0
            lastValue =  str2double(newValue);
            lastDelay = str2double(newDelay);
            set(varargin{1}, 'checked', 'on');
            set(varargin{1}, 'userData', [lastValue,lastDelay]);       
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

    otherData = zeros(numel(otherHandles), round((handleList.maxX - handleList.minX) / handleList.xStep) + 1);
    info = evalin('base', 'zData.protocol');
    for i = 1:numel(otherKids{1})
		for axesIndex = 1:numel(otherHandles)
			otherData(axesIndex, :) = get(otherKids{axesIndex}(i), 'yData');
		end

        events = findStims(info(i), 0);
        for ttlIndex = 1:numel(info(i).ttlEnable)
			if ~isempty(events(ttlIndex).data)
				eventTriggeredAverage(events(ttlIndex).data(:,1)', otherData, windowBounds, handleList.xStep, 1);
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
        set(handles.timeControl.minVal, 'enable', 'on');
        set(handles.timeControl.maxVal, 'enable', 'on');
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
        set(handles.timeControl.minVal, 'enable', 'on');
        set(handles.timeControl.maxVal, 'enable', 'on');
    end
    set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) str2double(get(handles.timeControl.maxVal, 'string'))]);
    newScale(gcf)
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
        traceNames = unique({get(kids(strcmp(get(kids, 'userData'), 'data')), 'displayName')});

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

function setAllReference(varargin)
    handles = get(gcf, 'userData');
    for i = handles.axes
        set(gcf, 'currentAxes', i);
        setAsReference(i);
    end
end

function removeAllReference(varargin)
    handles = get(gcf, 'userData');
    for i = handles.axes
        set(gcf, 'currentAxes', i);
        removeReference(i);
    end
end

% function fitData(varargin)
%     lineHandles = get(gca, 'children');
%     lineType = strcmp(get(lineHandles, 'userData'), 'data');
%     eventFunction = get(varargin{1}, 'userData');
%     stringData = {};
%     handleList = get(gcf, 'userData');
% 
%     if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
%         whichTime = [handleList.minX handleList.maxX];
%     else
%         whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
%     end
%     whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);
% 
%     for handleIndex = lineHandles(lineType)'
%         data = get(handleIndex, 'yData');
%         stringData{end + 1} = eventFunction(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
%     end
%     disp([func2str(eventFunction) '(data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
%     set(get(gca, 'userdata'), 'string', stringData);
% end

function BenSingleExpFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fit1Exp(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fit1Exp data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function BenDoubleExpFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fit2Exp(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fit2Exp data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function BenTripleExpFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fit3Exp(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fit3Exp data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function BenAlphaFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fitAlpha(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fitAlpha data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end
function BenBoltzmannFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fitBoltzmann(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fitBoltzmann data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function BenLineFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fitLine(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fitLine data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function BenSineFit(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)'
        data = get(handleIndex, 'yData');
        stringData{end + 1} = fitSine(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp(['fitSine data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function characterizeTrace(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    eventFunction = get(varargin{1}, 'userData');
    stringData = {};
    handleList = get(gcf, 'userData');

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    for handleIndex = lineHandles(lineType)
        data = get(handleIndex, 'yData');
        stringData{end + 1} = eventFunction(data(whichX(1):whichX(2)), handleList.xStep, whichTime(1), gca);
    end
    disp([func2str(eventFunction) '(data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ', handles.axes(axisNum));'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function characterizeExperiment(varargin)
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
    protocol = evalin('base', 'zData.protocol');
    for handleIndex = 1:numel(lineHandles)
        data = get(lineHandles(handleIndex), 'yData');
        stringData{end + 1} = eventFunction(data', protocol(handleIndex), ampNum, gca);
    end
    disp([func2str(eventFunction) '(data, protocol, ' num2str(ampNum) ', gca);'])
    set(get(gca, 'userdata'), 'string', stringData);
end

function detectEvents(varargin)
    lineHandles = get(gca, 'children');
    lineType = strcmp(get(lineHandles, 'userData'), 'data');
    handleList = get(gcf, 'userData');
    eventFunction = get(varargin{1}, 'userData');
    stringData = '';
    events = [];

    if strcmp(get(lineHandles(end - 1), 'visible'), 'off')
        whichTime = [handleList.minX handleList.maxX];
    else
        whichTime = round([min([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')]) max([get(lineHandles(end), 'xData') get(lineHandles(end - 1), 'xData')])] / handleList.xStep) * handleList.xStep;
    end
    whichX = int32((whichTime - handleList.minX) ./ handleList.xStep + 1);

    numEvents = [];
    for handleIndex = 1:length(lineHandles) - 2
        if lineType(handleIndex)
            data = get(lineHandles(handleIndex), 'yData');
            events(end + 1).traceName = get(lineHandles(handleIndex), 'displayName');
            events(end).data = (eventFunction(data(whichX(1):whichX(2))', handleList.xStep) - 2) * handleList.xStep + whichTime(1);
            events(end).type = get(varargin{1}, 'label');
            numEvents(end + 1) = numel(events(end).data);
            stringData = [stringData num2str(numEvents(end)) char(13)];
            disp(['events = ' func2str(eventFunction) '(data(' num2str(whichTime(1)) ':' num2str(whichTime(2)) '), ' num2str(handleList.xStep) ', ' num2str(whichTime(1)) ') * ' num2str(handleList.xStep) ' + ' num2str(whichTime(1)) ';'])
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
        set(handles.axes, 'xlim', [handles.minX handles.maxX]);         
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

% modified by BWS on 12/8/08
    handles.displayText = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'HorizontalAlignment','center',...
    'ListboxTop',0,...
    'Position',[0.025 0.8 0.95 0.133333333333333],...
    'String','0mV',...
    'ForegroundColor', [0 0 0], ...
    'Style','text');

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
    'enable', 'off',...
    'callback', @newMin);

    handles.channel = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.0324074074074074 0.951515151515152 0.680555555555555 0.121212121212121],...
    'String',{'No Channels'},...
    'Style','popupmenu',...
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
    'enable', 'off',...
    'callback', @newMax);

    handles.scaleType = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.402777777777778 0.721212121212121 0.555555555555556 0.121212121212121],...
    'String',{'Auto', 'Manual', 'Float Hist', 'Float Base', 'Float Min/Max','Default'},...
    'Style','popupmenu',...
    'Value',1,...
    'callback', @newScale);

    handles.offset = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.40462962962963 0.6 0.244444444444444 0.0909090909090909],...
    'String',{'Null' },...
    'Style','checkbox',...
    'callback', @newOffset);

    handles.float = uicontrol(...
    'Parent',handles.frame,...
    'Units','normalized',...
    'Position',[0.70462962962963 0.6 0.20 0.0909090909090909],...
    'String',{'100' },...
    'Style','edit',...
    'HorizontalAlignment','right',...
    'callback', @newFloat);

    matlabText = loadMatlabText;

    handles.commandText = uicontrol(...
    'Parent',handles.frame,...
    'backgroundcolor', [1 1 1],...
    'Units','normalized',...
    'Position',[0.025 0.41 0.95 0.12],...
    'String', {''},...
    'HorizontalAlignment','left',...
    'Style','edit',...
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
    'Style','edit');
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