% GUI for detecting PSPs
function handles = pspGui(lastVals)

if ~isappdata(0, 'pspDetector')
    if nargin < 1
        % set the default values
        lastVals.minAmp = .5;
        lastVals.maxAmp = 10;
        lastVals.minTau = 5;
        lastVals.maxTau = 100;
        lastVals.minYOffset = -100;
        lastVals.maxYOffset = -30;    
        lastVals.minDecay = 5;
        lastVals.maxDecay = 500; 
        lastVals.derThresh = 1;
        lastVals.closestEPSPs = 5;
        lastVals.errThresh = 0.08;
        lastVals.dataFilterType = 1;
        lastVals.derFilterType = 3;
        lastVals.dataFilterLength = 5;
        lastVals.derFilterLength = 5;
        lastVals.debugging = 0;
        lastVals.dataStart = 1;
        lastVals.forceDisplay = 0;
        lastVals.outputAxis = 0;
        lastVals.alphaFit = 0;    
        lastVals.decayFit = 0;
        lastVals.riseFit = 0;
    end
    
    figure('menu', 'none',...
        'name', 'PSP Detector',...
        'numbertitle', 'off',...
        'units', 'pixels',...
        'resize', 'off',...
        'color', [0.9255 0.9137 0.8471],...
        'position', [100 100 177 852],...
        'closeRequestFcn', @closeWindow);
    
    % menus
    f = uimenu('Label','Data');
        uimenu(f,'Label','Save PSPs...','Callback', @savePSPs);
        uimenu(f,'Label','Export to Workspace...','Callback', @exportPSPs);
        uimenu(f, 'Label', 'Characterize PSPs', 'callback', @characterizePSPsClick);
        uimenu(f, 'Label', 'Overlay PSPs', 'callback', @overlayPSPsClick);
        uimenu(f, 'Label', 'Covariances', 'callback', @genCovariances);
        uimenu(f,'Label','End','Callback', @closeWindow,...
               'Separator','on','Accelerator','Q');
    if ~ispref('pspGUI','presets')
        setpref('pspGUI','presets',{'presetEPSPs', 'presetIPSPs', 'presetEPSCs', 'presetIPSCs', 'presetNoisyEPSPs'});
        setpref('pspGUI','presetEPSPs', {'0.5','30','5','100','5','500','-100','-30',2,'5',4,'5',0,1,'1','0.08','5',0,0,'PSPsUp'})
        setpref('pspGUI', 'presetEPSCs', {'-2000','-5','2','200','5','500','-inf','inf',2,'11',4,'7',0,1,'1','0.08','5',1,0,'PSPsDown'});
        setpref('pspGUI','presetIPSPs', {'-30','0.5','5','100','5','500','-100','-30',2,'5',4,'5',0,1,'1','0.08','5',0,0,'PSPsDown'})
        setpref('pspGUI', 'presetIPSCs', {'5','2000','2','200','5','500','-inf','inf',2,'11',4,'7',0,1,'1','0.08','5',1,0,'PSPsUp'});		
        setpref('pspGUI','presetNoisyEPSPs', {'0.2','30','5','100','5','500','-100','-30',2,'15',4,'5',0,1,'.2','0.08','5',0,0,'PSPsUp'})		
    end
    g = uimenu('Label','Presets');
        uimenu(g,'Label','Add Current...','callback', @addPreset);
        uimenu(g,'Label','Remove Preset...','callback', @removePreset);
        tempPresets = getpref('pspGUI','presets');

        uimenu(g,'Label',tempPresets{1}(7:end),'callback', @setPreset,'separator','on');
        for i = 2:numel(tempPresets)
            uimenu(g,'Label',tempPresets{i}(7:end),'callback', @setPreset);
        end


    % uicontrols
    panel = uipanel('Title','Amplitude', 'units', 'pixel','FontSize',12,'Position',[9.8500  782.5000  159.3000   73.5000]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Min:', 'position', [.1 .6 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.ampMin = uicontrol('tooltipstring', 'Minimum allowable amplitude (pa\mV)', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.minAmp, 'position', [.6 .6 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Max:', 'position', [.1 .1 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.ampMax = uicontrol('tooltipstring', 'Maximum allowable amplitude (in pa\mV)', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.maxAmp, 'position', [.6 .1 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);

    panel = uipanel('Title','Alpha Tau', 'units', 'pixel','FontSize',12,'Position',[9.8500  711.0000  159.3000   73.5000]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Min:', 'position', [.1 .6 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.alphaTauMin = uicontrol('tooltipstring', 'Minimum allowable tau of first pass alpha function (msec)', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.minTau, 'position', [.6 .6 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Max:', 'position', [.1 .1 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.alphaTauMax = uicontrol('tooltipstring', 'Maximum allowable tau of first pass alpha function (msec)', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.maxTau, 'position', [.6 .1 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);

    panel = uipanel('Title','Decay Time', 'units', 'pixel','FontSize',12,'Position',[9.8500  638.5000  159.3000   73.5000]);
    uicontrol('tooltipstring', 'Minimum allowable tau of exponential decay fitting (msec)', 'Style', 'Text', 'units', 'normal', 'String', 'Min:', 'position', [.1 .6 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.decayMin = uicontrol('callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.minDecay, 'position', [.6 .6 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Max:', 'position', [.1 .1 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.decayMax = uicontrol('tooltipstring', 'Maximum allowable tau of exponential decay fitting (msec)', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.maxDecay, 'position', [.6 .1 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);

    panel = uipanel('Title','Y Offset', 'units', 'pixel','FontSize',12,'Position',[9.8500  566.0000  159.3000   73.5000]);
    uicontrol('tooltipstring', 'Minimum allowable offset of alpha function from baseline (pa\mV)','Style', 'Text', 'units', 'normal', 'String', 'Min:', 'position', [.1 .6 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.offsetMin = uicontrol('callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.minYOffset, 'position', [.6 .6 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Max:', 'position', [.1 .1 .5 .4], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.offsetMax = uicontrol('tooltipstring', 'Maximum allowable offset of alpha function from baseline (pa\mV)','callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.maxYOffset, 'position', [.6 .1 .3 .4], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);

    panel = uipanel('Title','Filtering', 'units', 'pixel','FontSize',12,'Position',[9.8500  446.5000  159.3000  120.5000]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Data', 'position', [0 .75 .45 .2], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Derivative', 'position', [0 .25 .45 .2], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Length', 'position', [.1 .50 .4 .2], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Length', 'position', [.1 0 .4 .2], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.dataFilterType = uicontrol('tooltipstring', 'Filtering of data trace', 'callback', @updatePSPs, 'Style', 'popup', 'units', 'normal', 'String', {'None'; 'Average'; 'Median'; 'S Golay'}, 'value', lastVals.dataFilterType + 1, 'position', [.45 .8 .55 .2], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    handles.derFilterType = uicontrol('tooltipstring', 'Filtering of derivative trace', 'callback', @updatePSPs, 'Style', 'popup', 'units', 'normal', 'String', {'None'; 'Average'; 'Median'; 'S Golay'}, 'value', lastVals.derFilterType + 1, 'position', [.45 .3 .55 .2], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    handles.dataFilterLength = uicontrol('tooltipstring', 'Length of filter for data trace', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.dataFilterLength, 'position', [.5 .50 .3 .2], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    handles.derFilterLength = uicontrol('tooltipstring', 'Length of filter for derivative trace','callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.derFilterLength, 'position', [.5 0 .3 .2], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);

    panel = uipanel('Title','Fitting', 'units', 'pixel','FontSize',12,'Position',[9.8500  357  159.3000  90]);
    handles.alphaFit = uicontrol('tooltipstring', 'Alpha fit to event', 'callback', @updatePSPs, 'Style', 'check', 'units', 'normal', 'String', 'Alpha', 'value', lastVals.alphaFit, 'position', [.1 .05 .8 .3], 'parent', panel, 'fontsize', 12);
    handles.decayFit = uicontrol('tooltipstring', 'Exponential fit to decay', 'callback', @updatePSPs, 'Style', 'check', 'units', 'normal', 'String', 'Decay', 'value', lastVals.decayFit, 'position', [.1 .35 .8 .3], 'parent', panel, 'fontsize', 12);
    handles.riseFit = uicontrol('tooltipstring', 'Exponential fit to rise', 'callback', @updatePSPs, 'Style', 'check', 'units', 'normal', 'String', 'Rise', 'value', lastVals.riseFit, 'position', [.1 .65 .8 .3], 'parent', panel, 'fontsize', 12);

    panel = uipanel('Title','', 'units', 'pixel','FontSize',12,'Position',[9.8500  185  159.3000  170]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Der Thresh', 'position', [.1 .65 .5 .12], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.derThresh = uicontrol('tooltipstring', 'Value which derivative must exceed to trigger an event start', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.derThresh, 'position', [.6 .65 .3 .12], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    handles.debugging = uicontrol('tooltipstring', 'Whether debugging plots are shown along the way', 'callback', @updatePSPs, 'Style', 'check', 'units', 'normal', 'String', 'Debugging', 'position', [.1 .85 .8 .12], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [0.9255 0.9137 0.8471]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Err Thresh', 'position', [.1 .5 .5 .12], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.errThresh = uicontrol('tooltipstring', 'Error threshold used for fitting alpha functions and decay taus', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.errThresh, 'position', [.6 .5 .3 .12], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'PSP Gap', 'position', [.1 .35 .5 .12], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.closestPSPs = uicontrol('tooltipstring', 'Closest that two PSPs can be without the first one being disregarded (msec)', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', lastVals.closestEPSPs, 'position', [.6 .35 .3 .12], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    handles.windowTimes = uicontrol('tooltipstring', 'Window of possible times (windowLength @ windowStarts); leave blank for whole time', 'callback', @updatePSPs, 'Style', 'edit', 'units', 'normal', 'String', '', 'position', [.6 .2 .3 .12], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1]);
    uicontrol('Style', 'Text', 'units', 'normal', 'String', 'Window', 'position', [.1 .2 .5 .12], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');
    handles.goButton = uicontrol('tooltipstring', 'Re-detect PSPs', 'callback', @updatePSPs, 'Style', 'pushbutton', 'units', 'normal', 'String', 'Detect', 'position', [.3 .03 .4 .12], 'parent', panel, 'fontsize', 12,'horizontalalignment', 'left');

    panel = uipanel('Title', 'Data', 'units', 'pixel','FontSize',12,'Position',[9.8500    8.3500  159.3000   95.5500]);
    handles.dataSource = uicontrol('callback', @updatePSPs, 'Style', 'list', 'units', 'normal', 'String', '', 'position', [0.02 0.02 .96 1], 'parent', panel, 'fontsize', 12, 'backgroundcolor', [1 1 1], 'min', 0, 'max', 0);
    handles.refreshData = uicontrol('callback', @loadChannels, 'style', 'pushbutton', 'units', 'pixel', 'position', [90 85.55 50 20], 'string', 'refresh');
    handles.PSPtype = uibuttongroup('visible', 'off', 'units', 'pixel', 'Position', [9.8500    108.3500  159.3000   75]);
    handles.PSPsAuto = uicontrol('tag','PSPsAuto','Style','Radio','String','Auto Detect','units', 'normal','fontsize', 12, 'pos',[.1 .65 .8 .3],'parent',handles.PSPtype,'HandleVisibility','off');
    handles.PSPsUp = uicontrol('tag','PSPsUp','Style','Radio','String','Up','units', 'normal','fontsize', 12, 'pos',[.1 .35 .8 .3],'parent',handles.PSPtype,'HandleVisibility','off');
    handles.PSPsDown = uicontrol('tag','PSPsDown','Style','Radio','String','Down','units', 'normal','fontsize', 12, 'pos',[.1 .05 .8 .3],'parent',handles.PSPtype,'HandleVisibility','off');
    set(handles.PSPtype,'SelectionChangeFcn',@updatePSPs,'SelectedObject',handles.PSPsAuto,'Visible','on', 'userdata', handles.PSPsAuto);

    setappdata(gcf, 'lastVals', lastVals);
    setappdata(0, 'pspDetector', handles);
    setappdata(handles.dataSource, 'lastSelection', []);
else
    if nargin > 0
        % just reset the values
        handleList = getappdata(0, 'pspDetector');
        set(handleList.ampMin, 'string', lastVals.minAmp);
        set(handleList.ampMax, 'string', lastVals.maxAmp);
        set(handleList.alphaTauMin, 'string', lastVals.minTau);
        set(handleList.alphaTauMax, 'string', lastVals.maxTau);
        set(handleList.decayMin, 'string', lastVals.minDecay);
        set(handleList.decayMax, 'string', lastVals.maxDecay);
        set(handleList.offsetMin, 'string', lastVals.minOffset);
        set(handleList.offsetMax, 'string', lastVals.maxOffset);
        set(handleList.dataFilterType, 'value', lastVals.dataFilterType);
        set(handleList.dataFilterLength, 'string', lastVals.dataFilterLength);
        set(handleList.derFilterType, 'value', lastVals.derFilterType);
        set(handleList.derFilterLength, 'string', lastVals.derFilterLength);
        set(handleList.debugging, 'value', lastVals.debugging);
        set(handleList.alphaFit, 'value', lastVals.alphaFit);
        set(handleList.decayFit, 'value', lastVals.decayFit);
        set(handleList.riseFit, 'value', lastVals.riseFit);        
        set(handleList.derThresh, 'string', lastVals.derThresh);
        set(handleList.errThresh, 'string', lastVals.errThresh);
        set(handleList.closestPSPs, 'string', lastVals.closestPSPs);  
        setappdata(gcf, 'lastVals', lastVals);
    end
end
loadChannels

function closeWindow(varargin)
    button = questdlg('Save PSP data?');
    if strcmp(button, 'Yes')
        savePSPs;
    end
    if ~strcmp(button, 'Cancel')
       rmappdata(0, 'pspDetector');
       delete(gcf);
    end
    
function savePSPs(varargin)
   
    if isappdata(gcf, 'PSPs')
        [FileName PathName] = uiputfile({'*.mat', 'Matlab Data Files (*.mat)';' *.*', 'All Files (*.*)'},'Choose name and location for file', 'PSPs');

        if isequal(FileName, 0)
            error('Wasn''t sure if you really wanted to discard PSPs')
        end
        PSPs = getappdata(gcf, 'PSPs');

        save([PathName FileName], 'PSPs');
    else
        msgbox('No PSPs to save'); 
    end
    
function exportPSPs(varargin)   
    varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, {'PSPs'});
 
    tempVarName = genvarname(varName, evalin('base', 'who'));
    if strcmp(varName, tempVarName)
        assignin('base', varName{1},  getappdata(gcf, 'PSPs'));
    else
        switch questdlg(strcat('''', varName, ''' is not a valid variable name in the base workspace.  Is ''', tempVarName, ''' ok?'), 'Uh oh');
            case 'Yes'
                assignin('base', tempVarName{1},  getappdata(gcf, 'PSPs'));
            case 'No'
                varName = inputdlg('Enter a name for the workspace variable', 'Export', 1, tempVarName);
                assignin('base', genvarname(varName{1}),  getappdata(gcf, 'PSPs'));
            case 'Cancel'
                % do nothing
        end
    end    

    
function characterizePSPsClick(varargin)
    if isappdata(gcf, 'PSPs')
        PSPs = getappdata(gcf, 'PSPs');
        if numel(PSPs.params) > 1
            params = [];
            for i = 1:numel(PSPs.params)
                if ~isempty(PSPs.params{i})
                    params(end + 1:end + size(PSPs.params{i}, 1), :) = PSPs.params{i};
                end
            end
            PSPs = [];
            PSPs.params{1} = params;
        end
        characterizePSPs(PSPs.params{1,1}, diff(getappdata(gcf, 'xLims')) / 1000);
    end

function overlayPSPsClick(varargin)
    persistent lastValues
    
    if isappdata(gcf, 'PSPs')
        if isempty(lastValues)
            lastValues = [-2 10];
        end
        whereBounds = inputdlg({'Start of window (msec)', 'End of Window (msec)'},'Time Window...',1, {num2str(lastValues(1)), num2str(lastValues(2))});
        if numel(whereBounds) > 0 % bail if they hit 'Cancel'
            whereBounds = str2double(whereBounds);
            lastValues = whereBounds;
            PSPs = getappdata(gcf, 'PSPs');
            handles = getappdata(0, 'pspDetector');
            whichAxis = get(handles.dataSource, 'userData');
            whichAxis = whichAxis(get(handles.dataSource, 'value'));        
            kids = get(whichAxis, 'children');
            zData = readTrace(get(kids(end - 2), 'displayName'), 1);
            data = getappdata(gcf, 'traceData');
            overlayPSPs(data, [whereBounds(1) whereBounds(2)], PSPs.params, zData.timePerPoint);
        end
    end
    
function genCovariances(varargin)
    if isappdata(gcf, 'PSPs')
        PSPs = getappdata(gcf, 'PSPs');
        if numel(PSPs.params) > 1
            params = [];
            for i = 1:numel(PSPs.params)
                params(end + 1:end + size(PSPs.params{i}, 1), :) = PSPs.params{i};
            end
            PSPs = [];
            PSPs.params{1} = params;
        end
        outData = char(ones(5, 60) * 32);
        tempData = num2str(cov(normalizeMatrix(PSPs.params{1}, 2)));
        outData(2:5, end - size(tempData, 2) + 1:end) = tempData;
        outData(1,:) = '               Amplitude    Rise Tau    Location   Decay Tau';
        outData(2,1:9) = 'Amplitude';
        outData(3,1:8) = 'Rise Tau';
        outData(4,1:8) = 'Location';
        outData(5,1:9) = 'Decay Tau';
        disp(outData);

        corVals = corrcoef(PSPs.params{1});
        corVals = corVals .^ 2;
        figure('name', 'Covariance', 'numbertitle', 'off');
        subplot(3,2,1), plot(PSPs.params{1}(:,1), PSPs.params{1}(:,2), 'linestyle', 'none', 'marker', '.', 'markerSize', 12), m = polyfit(PSPs.params{1}(:,1), PSPs.params{1}(:,2), 1); line([min(PSPs.params{1}(:,1)) max(PSPs.params{1}(:,1))], [m(1) * min(PSPs.params{1}(:,1)) + m(2) m(1) * max(PSPs.params{1}(:,1)) + m(2)], 'color', [1 0 0]), title(['Rise Tau vs. Amplitude, R^{2} = ' sprintf('%4.2f', corVals(2,1))]), axis tight;
        subplot(3,2,3), plot(PSPs.params{1}(:,1), PSPs.params{1}(:,3), 'linestyle', 'none', 'marker', '.', 'markerSize', 12), m = polyfit(PSPs.params{1}(:,1), PSPs.params{1}(:,3), 1); line([min(PSPs.params{1}(:,1)) max(PSPs.params{1}(:,1))], [m(1) * min(PSPs.params{1}(:,1)) + m(2) m(1) * max(PSPs.params{1}(:,1)) + m(2)], 'color', [1 0 0]),title(['Location vs. Amplitude, R^{2} = ' sprintf('%4.2f', corVals(3,1))]), axis tight;
        subplot(3,2,5), plot(PSPs.params{1}(:,1), PSPs.params{1}(:,4), 'linestyle', 'none', 'marker', '.', 'markerSize', 12), m = polyfit(PSPs.params{1}(:,1), PSPs.params{1}(:,4), 1); line([min(PSPs.params{1}(:,1)) max(PSPs.params{1}(:,1))], [m(1) * min(PSPs.params{1}(:,1)) + m(2) m(1) * max(PSPs.params{1}(:,1)) + m(2)], 'color', [1 0 0]),title(['Decay Tau vs. Amplitude, R^{2} = ' sprintf('%4.2f', corVals(4,1))]), axis tight;
        subplot(3,2,2), plot(PSPs.params{1}(:,4), PSPs.params{1}(:,3), 'linestyle', 'none', 'marker', '.', 'markerSize', 12), m = polyfit(PSPs.params{1}(:,4), PSPs.params{1}(:,3), 1); line([min(PSPs.params{1}(:,4)) max(PSPs.params{1}(:,4))], [m(1) * min(PSPs.params{1}(:,4)) + m(2) m(1) * max(PSPs.params{1}(:,4)) + m(2)], 'color', [1 0 0]),title(['Location vs. Decay Tau, R^{2} = ' sprintf('%4.2f', corVals(3,4))]), axis tight;
        subplot(3,2,4), plot(PSPs.params{1}(:,2), PSPs.params{1}(:,3), 'linestyle', 'none', 'marker', '.', 'markerSize', 12), m = polyfit(PSPs.params{1}(:,2), PSPs.params{1}(:,3), 1); line([min(PSPs.params{1}(:,2)) max(PSPs.params{1}(:,2))], [m(1) * min(PSPs.params{1}(:,2)) + m(2) m(1) * max(PSPs.params{1}(:,2)) + m(2)], 'color', [1 0 0]),title(['Location vs. Rise Tau, R^{2} = ' sprintf('%4.2f', corVals(3,2))]), axis tight;
        subplot(3,2,6), plot(PSPs.params{1}(:,2), PSPs.params{1}(:,4), 'linestyle', 'none', 'marker', '.', 'markerSize', 12), m = polyfit(PSPs.params{1}(:,2), PSPs.params{1}(:,4), 1); line([min(PSPs.params{1}(:,2)) max(PSPs.params{1}(:,2))], [m(1) * min(PSPs.params{1}(:,2)) + m(2) m(1) * max(PSPs.params{1}(:,2)) + m(2)], 'color', [1 0 0]),title(['Decay Tau vs. Rise Tau, R^{2} = ' sprintf('%4.2f', corVals(4,2))]), axis tight;
    end
    
function updatePSPs(varargin)
    persistent useMultiProcessor
    if isempty(useMultiProcessor)
        useMultiProcessor = -1;
    end
    lastVals = getappdata(gcf, 'lastVals');
    handleList = getappdata(0, 'pspDetector');
    pspFigure = gcf;
    
    if varargin{1} == handleList.goButton
        % set these as the values
        lastVals = loadVals;
        setappdata(pspFigure, 'lastVals', lastVals);     
        setappdata(handleList.dataSource, 'lastSelection', get(handleList.dataSource, 'value'));
        
        % call detect
        axisHandles = get(handleList.dataSource, 'userData');
        lastVals.outputAxis = axisHandles(get(handleList.dataSource, 'value'));
        if ishandle(lastVals.outputAxis)                
            kids = get(lastVals.outputAxis, 'children');
            kids = kids(strcmp(get(kids(1:end - 2), 'userData'), 'data'));
            xdata = get(kids(end), 'xdata');
            xDiff = diff(xdata(1:2));
            lims = get(lastVals.outputAxis, 'xlim');
            lastVals.dataStart = round((lims(1) + 1)/ xDiff);
            setappdata(pspFigure, 'lastVals', lastVals);    
            try
                data = cell2mat(get(kids, 'ydata'));
                data = data(:, (min([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)));
                lastVals.minTau = lastVals.minTau / xDiff;
                lastVals.maxTau = lastVals.maxTau / xDiff;                
                numEvents = [];
                if useMultiProcessor == -1
                    useMultiProcessor = strcmp('Yes', questdlg('Use multiple threads to speed processing (this is only helpful on multiprocessor machines)?', 'Multithread', 'Yes', 'No', 'No'));
                end
                if ~matlabpool('size') && useMultiProcessor
                    matlabpool('open', 4);
                end
                winString = get(handleList.windowTimes, 'string');
                whichType = get(get(handleList.PSPtype,'SelectedObject'), 'string');
                parfor (traceIndex = 1:numel(kids), 4 * ~lastVals.debugging)
                    if isempty(winString)
                        switch whichType
                            case 'Auto Detect'
                                [params decayFits] = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), lastVals);
                                if traceIndex == 1
                                    disp(['detectPSPs(data(' sprintf('%1.1f', max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]) * xDiff) ':' sprintf('%1.1f', round((lims(2) - xdata(1)) / xDiff) * xDiff) ')' struct2stream(lastVals, lims(1)) ');'])
                                end
                            case 'Up'
                                [params decayFits] = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), 0, lastVals);
%                                 tempPSPs = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), 1, lastVals);
%                                 toRemove = [];
%                                 for h = 1:size(params, 1)
%                                     if sum(params(h, 3) < tempPSPs(:,3) + tempPSPs(:,2) * 2 & params(h, 3) > tempPSPs(:,3) + tempPSPs(:,2) * 0)
%                                         toRemove = [toRemove h];
%                                     end
%                                 end
%                                 params(toRemove, :) = [];
%                                 decayFits(toRemove, :) = [];
                                if traceIndex == 1
                                    disp(['detectPSPs(data(' sprintf('%1.1f', max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]) * xDiff) ':' sprintf('%1.1f', round((lims(2) - xdata(1)) / xDiff) * xDiff) '), 0' struct2stream(lastVals, lims(1)) ');'])
                                end
                            case 'Down'
                                [params decayFits] = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), 1, lastVals);
                                if traceIndex == 1
                                    disp(['detectPSPs(data(' sprintf('%1.1f', max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]) * xDiff) ':' sprintf('%1.1f', round((lims(2) - xdata(1)) / xDiff) * xDiff) '), 1' struct2stream(lastVals, lims(1)) ');'])
                                end
                        end
                    else
                        windowLength = round(str2double(winString(1:find(winString == '@', 1, 'first') - 1)) / xDiff);
                        windowStarts = round(str2num(winString(find(winString == '@', 1, 'first') + 1:end)) / xDiff) - max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]);
                        switch whichType
                            case 'Auto Detect'
                                [params decayFits] = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), windowStarts, windowLength, lastVals);
                                if traceIndex == 1
                                    disp(['detectPSPs(data(' sprintf('%1.1f', max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]) * xDiff) ':' sprintf('%1.1f', round((lims(2) - xdata(1)) / xDiff) * xDiff) '), ' sprintf('%0.0f', windowStarts) ', ' sprintf('%0.0f', windowLength) struct2stream(lastVals, lims(1)) ');'])
                                end
                            case 'Up'
                                [params decayFits] = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), 0, windowStarts, windowLength, lastVals);                                
                                if traceIndex == 1
                                    disp(['detectPSPs(data(' sprintf('%1.1f', max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]) * xDiff) ':' sprintf('%1.1f', round((lims(2) - xdata(1)) / xDiff) * xDiff) '), 0, ' sprintf('%0.0f', windowStarts) ', ' sprintf('%0.0f', windowLength) struct2stream(lastVals, lims(1)) ');'])
                                end
                            case 'Down'
                                [params decayFits] = detectPSPs(data(traceIndex, max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]):round((lims(2) - xdata(1)) / xDiff)), 1, windowStarts, windowLength, lastVals);
                                if traceIndex == 1
                                    disp(['detectPSPs(data(' sprintf('%1.1f', max([1 round((lims(1) + 1 - xdata(1)) / xDiff)]) * xDiff) ':' sprintf('%1.1f', round((lims(2) - xdata(1)) / xDiff) * xDiff) '), 1, ' sprintf('%0.0f', windowStarts) ', ' sprintf('%0.0f', windowLength) struct2stream(lastVals, lims(1)) ');'])
                                end
                        end                        
                    end
                    if params(1,1) == 0
                        params = [];
                        disp('No PSPs detected');
                    end
                    Params{traceIndex} = params;
                    DecayFits{traceIndex} = decayFits;
                end
                stringData = '';                
                timeDiff = get(get(lastVals.outputAxis, 'parent'), 'userData');
                timeDiff = timeDiff.xStep(get(handleList.dataSource, 'value'));
                for traceIndex = 1:numel(kids)  
                    if ~isempty(Params{traceIndex})
                        Params{traceIndex}(:,2:4) = Params{traceIndex}(:,2:4) .* timeDiff;
                        Params{traceIndex}(:,3) = Params{traceIndex}(:,3) + 1 + lims(1);
                        try
                            for i = 1:size(Params{traceIndex}, 1)
                                % plot starts
                                line(Params{traceIndex}(i, 3), data(traceIndex, round(Params{traceIndex}(i, 3)/timeDiff)), 'parent', lastVals.outputAxis, 'Color', [0 0 1], 'linestyle', 'none', 'marker', '+', 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Start time = ' sprintf('%6.1f', Params{traceIndex}(i,3)) ''')']);
                                % plot amplitudes
                                line([Params{traceIndex}(i, 3) + Params{traceIndex}(i, 2) Params{traceIndex}(i, 3) + Params{traceIndex}(i, 2)], [data(traceIndex, round(Params{traceIndex}(i, 3)/ timeDiff + Params{traceIndex}(i, 2) / timeDiff)) - Params{traceIndex}(i, 1) data(traceIndex, round(Params{traceIndex}(i, 3)/ timeDiff + Params{traceIndex}(i, 2)/ timeDiff))], 'parent', lastVals.outputAxis, 'Color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Rise time = ' sprintf('%4.1f', Params{traceIndex}(i,2)) '''; ''Amplitude = ' sprintf('%7.2f', Params{traceIndex}(i,1)) '''})']);
                                if lastVals.decayFit
                                    % plot decay tau
                                    line(lastVals.dataStart * timeDiff + ((Params{traceIndex}(i, 3)/timeDiff + Params{traceIndex}(i, 2)/timeDiff * 1.5:Params{traceIndex}(i, 3)/timeDiff + Params{traceIndex}(i, 2)/timeDiff * 1.5 + numel(DecayFits{traceIndex}{i}) - 1) * timeDiff), DecayFits{traceIndex}{i}, 'parent', lastVals.outputAxis, 'Color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Decay tau = ' sprintf('%6.2f', Params{traceIndex}(i,4)) ''')']);        
                                end
                            end
                        catch

                        end

                        events(traceIndex).data = Params{traceIndex}(:,3)';
                    else
                        events(traceIndex).data = [];
                    end
                    events(traceIndex).traceName = get(kids(traceIndex), 'displayName');
                    events(traceIndex).type = 'PSPs';
                    numEvents(traceIndex) = size(Params{traceIndex}, 1);                    
                    stringData = [stringData num2str(numEvents(traceIndex)) ' events' char(13)];                          
                end
                PSPs.params = Params;
                PSPs.decayFits = DecayFits;                
                setappdata(lastVals.outputAxis, 'events', events);
                if numel(numEvents) > 1
                    stringData = ['mean = ' num2str(mean(numEvents)) ', STE = ' num2str(std(numEvents)/sqrt(numel(numEvents))) char(13) stringData];
                end                
                set(get(lastVals.outputAxis, 'userData'), 'string', stringData);                
            catch
                setappdata(lastVals.outputAxis, 'events', []);
                PSPs = [];
            end
            showEvents(lastVals.outputAxis);                
        end
        if exist('PSPs', 'var')
            setappdata(pspFigure, 'PSPs', PSPs);
            setappdata(pspFigure, 'traceData', data);
            setappdata(pspFigure, 'xLims', lims);
            setappdata(pspFigure, 'xStep', xDiff);
        end
    elseif  str2double(get(handleList.ampMin, 'string')) >= lastVals.minAmp &&...
            str2double(get(handleList.ampMax, 'string')) <= lastVals.maxAmp &&...
            str2double(get(handleList.alphaTauMin, 'string')) >= lastVals.minTau &&...
            str2double(get(handleList.alphaTauMax, 'string')) <= lastVals.maxTau &&...
            str2double(get(handleList.decayMin, 'string')) >= lastVals.minDecay &&...
            str2double(get(handleList.decayMax, 'string')) <= lastVals.maxDecay &&...
            str2double(get(handleList.offsetMin, 'string')) >= lastVals.minYOffset &&...
            str2double(get(handleList.offsetMax, 'string')) <= lastVals.maxYOffset &&...
            get(handleList.dataFilterType, 'value') == lastVals.dataFilterType + 1 &&...
            get(handleList.derFilterType, 'value') == lastVals.derFilterType + 1 &&...
            str2double(get(handleList.dataFilterLength, 'string')) >= lastVals.dataFilterLength &&...
            str2double(get(handleList.derFilterLength, 'string')) <= lastVals.derFilterLength &&...
            str2double(get(handleList.derThresh, 'string')) >= lastVals.derThresh &&...
            str2double(get(handleList.errThresh, 'string')) <= lastVals.errThresh &&...
            str2double(get(handleList.closestPSPs, 'string')) <= lastVals.closestEPSPs &&...
            length(getappdata(handleList.dataSource, 'lastSelection')) == length(get(handleList.dataSource, 'value')) &&...
            getappdata(handleList.dataSource, 'lastSelection') == get(handleList.dataSource, 'value') &&...
            get(handleList.PSPtype, 'userData') == get(handleList.PSPtype, 'selectedObject')
            
        
            % set these as the values
            lastVals = loadVals;
            setappdata(pspFigure, 'lastVals', lastVals);
            setappdata(handleList.dataSource, 'lastSelection', get(handleList.dataSource, 'value'));
            set(handleList.PSPtype, 'userData', get(handleList.PSPtype, 'selectedObject'));
            
            % filter out the ones that are out of bounds
            PSPs = getappdata(pspFigure, 'PSPs');
            if size(PSPs, 1) == 1
                return
            end            
            if ~iscell(PSPs)
                PSPs = {PSPs};
            end
            for traceIndex = 1:numel(PSPs)
                keepers = PSPs{traceIndex}.params{1}(:, 1) >= lastVals.minAmp &...
                            PSPs{traceIndex}.params{1}(:, 1) <= lastVals.maxAmp &...
                            PSPs{traceIndex}.params{1}(:, 4) >= lastVals.minDecay &...
                            PSPs{traceIndex}.params{1}(:, 4) <= lastVals.maxDecay;
                PSPs{traceIndex}.params{1} = PSPs{traceIndex}.params{1}(keepers, :); 
                PSPs{traceIndex}.decayFits = {PSPs{traceIndex}.decayFits{1}(:, keepers)}; 
            end
            
            setappdata(pspFigure, 'PSPs', PSPs);
            
            % update the display
            axisHandles = get(handleList.dataSource, 'userData');
            axisHandles = axisHandles(get(handleList.dataSource, 'value'));
            axisKids = get(axisHandles, 'children');
            delete(axisKids(~strcmp(get(axisKids(1:end - 2), 'userdata'), 'data')))
            xDiff = get(axisKids(end - 2), 'xdata');
            xDiff = diff(xDiff(1:2));            
            for traceIndex = 1:numel(axisKids)
                data = get(axisKids(traceIndex), 'ydata');
                for i = 1:size(PSPs{traceIndex}.params{1}, 1)
                    % plot starts
                    line(PSPs{traceIndex}.params{1}(i, 3), data(int32(PSPs{traceIndex}.params{1}(i, 3) / xDiff) - lastVals.dataStart), 'parent', axisHandles, 'Color', [0 0 1], 'linestyle', 'none', 'marker', '+', 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Start time = ' sprintf('%6.1f', PSPs{traceIndex}.params{1}(i,3)) ''')']);
                    % plot amplitudes
                    line([PSPs{traceIndex}.params{1}(i, 3) + PSPs{traceIndex}.params{1}(i, 2) PSPs{traceIndex}.params{1}(i, 3) + PSPs{traceIndex}.params{1}(i, 2)], [data(int32((PSPs{traceIndex}.params{1}(i, 3) + PSPs{traceIndex}.params{1}(i, 2)) / xDiff) - lastVals.dataStart) - PSPs{traceIndex}.params{1}(i, 1) data(int32((PSPs{traceIndex}.params{1}(i, 3) + PSPs{traceIndex}.params{1}(i, 2)) / xDiff) - lastVals.dataStart)], 'parent', axisHandles, 'Color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Rise time = ' sprintf('%4.1f', PSPs{traceIndex}.params{1}(i,2)) '''; ''Amplitude = ' sprintf('%7.2f', PSPs{traceIndex}.params{1}(i,1)) '''})']);
                    % plot decay tau
                    line(PSPs{traceIndex}.params{1}(i, 3) + PSPs{traceIndex}.params{1}(i, 2) * 1.5:xDiff:PSPs{traceIndex}.params{1}(i, 3) + PSPs{traceIndex}.params{1}(i, 2) * 1.5 + numel(PSPs{traceIndex}.decayFits{i}) * xDiff - xDiff, PSPs{traceIndex}.decayFits{i}, 'parent', axisHandles, 'Color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Decay tau = ' sprintf('%6.2f', PSPs{traceIndex}.params{1}(i,4)) ''')']);        
                end  
                events(traceIndex).data = PSPs.params{traceIndex}(:,3)';              
            end      
            setappdata(axisHandles, 'events', events);
            showEvents(axisHandles);            
    end
  
function lastVals = loadVals
    handleList = getappdata(0, 'pspDetector');
    lastVals.minAmp = str2double(get(handleList.ampMin, 'string'));
    lastVals.maxAmp = str2double(get(handleList.ampMax, 'string'));
    lastVals.minTau = str2double(get(handleList.alphaTauMin, 'string'));
    lastVals.maxTau = str2double(get(handleList.alphaTauMax, 'string'));
    lastVals.minYOffset = str2double(get(handleList.offsetMin, 'string'));
    lastVals.maxYOffset = str2double(get(handleList.offsetMax, 'string'));    
    lastVals.minDecay = str2double(get(handleList.decayMin, 'string'));
    lastVals.maxDecay = str2double(get(handleList.decayMax, 'string')); 
    lastVals.derThresh = str2double(get(handleList.derThresh, 'string')); 
    lastVals.closestEPSPs = str2double(get(handleList.closestPSPs, 'string'));
    lastVals.errThresh = str2double(get(handleList.errThresh, 'string'));
    lastVals.dataFilterType = get(handleList.dataFilterType, 'value') - 1;
    lastVals.derFilterType = get(handleList.derFilterType, 'value') - 1;
    lastVals.dataFilterLength = str2double(get(handleList.dataFilterLength, 'string'));
    lastVals.derFilterLength = str2double(get(handleList.derFilterLength, 'string'));
    lastVals.debugging = get(handleList.debugging, 'value');
    lastVals.outputAxis = 0;
    lastVals.dataStart = 0;
    lastVals.forceDisplay = 0;
    lastVals.alphaFit = get(handleList.alphaFit, 'value');
    lastVals.decayFit = get(handleList.decayFit, 'value');
    lastVals.riseFit = get(handleList.riseFit, 'value');    
    
function outText = struct2stream(inVals, dataStart)
    outText = [', ''minAmp'', ' num2str(inVals.minAmp) ...
        ', ''maxAmp'', ' num2str(inVals.maxAmp) ...
        ', ''minTau'', ' num2str(inVals.minTau) ...
        ', ''maxTau'', ' num2str(inVals.maxTau) ...
        ', ''minYOffset'', ' num2str(inVals.minYOffset) ...
        ', ''maxYOffset'', ' num2str(inVals.maxYOffset) ...
        ', ''minDecay'', ' num2str(inVals.minDecay) ...
        ', ''maxDecay'', ' num2str(inVals.maxDecay) ... 
        ', ''derThresh'', ' num2str(inVals.derThresh) ...
        ', ''closestEPSPs'', ' num2str(inVals.closestEPSPs) ...
        ', ''errThresh'', ' num2str(inVals.errThresh) ...
        ', ''dataFilterType'', ' num2str(inVals.dataFilterType) ...
        ', ''derFilterType'', ' num2str(inVals.derFilterType) ...
        ', ''dataFilterLength'', ' num2str(inVals.dataFilterLength) ...
        ', ''derFilterLength'', ' num2str(inVals.derFilterLength) ...
        ', ''debugging'', ' num2str(inVals.debugging) ...
        ', ''dataStart'', ' num2str(dataStart) ...
        ', ''forceDisplay'',  0' ...
        ', ''alphaFit'', ' num2str(inVals.alphaFit) ...
        ', ''decayFit'', ' num2str(inVals.decayFit) ...
        ', ''riseFit'', ' num2str(inVals.riseFit)];
        
function loadChannels(varargin)
    stringData = [];
    userData = [];
    handles = getappdata(0, 'pspDetector');    
    if isappdata(0, 'scopes')
        scopes = getappdata(0, 'scopes');
        handleList = get(scopes(1), 'userData');
        whatChoices = get(handleList.channelControl(1).channel, 'string');
        if ~iscell(whatChoices)
            whatChoices = {whatChoices};
        end
        for axisIndex = 1:handleList.axesCount
            whichChannel = get(handleList.channelControl(axisIndex).channel, 'value');

            stringData{end + 1} = whatChoices{whichChannel};
        end
        userData(end + 1:end + handleList.axesCount) = handleList.axes;
        set(handles.dataSource, 'string', stringData, 'userdata', userData, 'value', 1);
        setappdata(ancestor(handles.dataSource, 'figure'), 'xStep', handleList.xStep);        
    else
        set(handles.dataSource, 'string', '', 'userdata', [], 'value', 0);
        setappdata(ancestor(handles.dataSource, 'figure'), 'xStep', 1);        
    end
    
function addPreset(varargin)
    tempName = inputdlg('Please enter a name for the preset:');
    tempName = tempName{1};
    if ~isvarname(tempName)
        switch questdlg(['Change to ' genvarname(tempName) '?'], 'Input must be a valid variable name','Yes','No','Yes')
            case 'Yes'
                tempName = genvarname(tempName);
            case 'No'
                return
        end
    end
    
    tempPresets = getpref('pspGUI','presets');
    if ~ismember(tempName, tempPresets)
        tempPresets{end + 1} = ['preset' tempName];
        setpref('pspGUI','presets',tempPresets);
    end
    handleList = getappdata(0, 'pspDetector');
    setpref('pspGUI',['preset' tempName],{...
        get(handleList.ampMin, 'string'), get(handleList.ampMax, 'string'),...
        get(handleList.alphaTauMin, 'string'), get(handleList.alphaTauMax, 'string'),...
        get(handleList.decayMin, 'string'), get(handleList.decayMax, 'string'),...
        get(handleList.offsetMin, 'string'), get(handleList.offsetMax, 'string'),...
        get(handleList.dataFilterType, 'value'), get(handleList.dataFilterLength, 'string'),...
        get(handleList.derFilterType, 'value'), get(handleList.derFilterLength, 'string'),...
        get(handleList.debugging, 'value'), get(handleList.alphaFit, 'value'),...
        get(handleList.derThresh, 'string'), get(handleList.errThresh, 'string'),...
        get(handleList.closestPSPs, 'string'), get(handleList.decayFit, 'value'),...
        get(handleList.riseFit, 'value'), get(get(handleList.PSPtype,'SelectedObject'), 'tag')});
    
    uimenu(get(varargin{1},'parent'),'Label',tempName,'callback', @setPreset);
    
function removePreset(varargin)
    tempPresets = getpref('pspGUI','presets');
    for i = 1:numel(tempPresets)
        prettyPresets{i} = tempPresets{i}(7:end);
    end
    
    [selection,isOK] = listdlg('PromptString','Select presets to delete:',...
                    'SelectionMode','multiple',...
                    'okstring','Delete',...
                    'ListString',prettyPresets);
    
    if isOK
        for i = 1:numel(tempPresets)
            if ismember(i,selection)
                rmpref('pspGUI',tempPresets{i});
                delete(findobj('parent', get(varargin{1}, 'parent'), 'Label', tempPresets{i}(7:end)));
            end
        end
        
        setpref('pspGUI','presets',tempPresets(selection));
    end
    
function setPreset(varargin)
    tempPreset = getpref('pspGUI',['preset' get(varargin{1}, 'Label')]);
    
    handleList = getappdata(0, 'pspDetector');
    set(handleList.ampMin, 'string', tempPreset{1});
    set(handleList.ampMax, 'string', tempPreset{2});
    set(handleList.alphaTauMin, 'string', tempPreset{3});
    set(handleList.alphaTauMax, 'string', tempPreset{4});
    set(handleList.decayMin, 'string', tempPreset{5});
    set(handleList.decayMax, 'string', tempPreset{6});
    set(handleList.offsetMin, 'string', tempPreset{7});
    set(handleList.offsetMax, 'string', tempPreset{8});
    set(handleList.dataFilterType, 'value', tempPreset{9});
    set(handleList.dataFilterLength, 'string', tempPreset{10});
    set(handleList.derFilterType, 'value', tempPreset{11});
    set(handleList.derFilterLength, 'string', tempPreset{12});
    set(handleList.debugging, 'value', tempPreset{13});
    set(handleList.alphaFit, 'value', tempPreset{14});
    set(handleList.derThresh, 'string', tempPreset{15});
    set(handleList.errThresh, 'string', tempPreset{16});
    set(handleList.closestPSPs, 'string', tempPreset{17});
    set(handleList.decayFit, 'value', tempPreset{18});
    set(handleList.riseFit, 'value', tempPreset{19});    
    set(handleList.PSPtype, 'SelectedObject', handleList.(tempPreset{20}));