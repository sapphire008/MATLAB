function exportWithScaleBars(figure)

% function for converting a newScope to an enhanced meta-file on the clipboard

    if nargin == 0
        figure = gcf;
    end
    
    handles = get(figure, 'userData');
    mouseCallbacks = {get(figure, 'WindowButtonMotionFcn') get(figure, 'WindowButtonDownFcn') get(figure, 'WindowButtonUpFcn') get(figure, 'resizefcn')};
    set(figure, 'visible', 'off', 'WindowButtonMotionFcn', '', 'WindowButtonDownFcn', '', 'WindowButtonUpFcn', '', 'resizefcn', '');
    figPos = get(figure, 'position');
    
    % hide the cursors
    for i = 1:handles.axesCount
       kidKids = get(handles.axes(i), 'children');
       set(kidKids(end - 1:end), 'visible', 'off');
       analysisAxes{i} = fieldnames(handles.analysisAxis{i});
    end

    set(handles.timeControl.frame, 'visible', 'off');
    set([handles.channelControl.frame], 'visible', 'off');
    set(figure, 'inverthardcopy', 'off', 'color', [1 1 1]);
	enlargementFactor = 1;
    if ~ispref('newScope', 'exportSettings')
        setpref('newScope', 'exportSettings', [3 3 1 1]);
    end
    tempPref = getpref('newScope', 'exportSettings');        
    if tempPref(1) * enlargementFactor + 1 > 7.5
        tempPref(1) = 6.5 / enlargementFactor;
        warning(['Figures are too wide for the page. Width adjusted to ' num2str(tempPref(1)) ' inches.']);
    end
    if handles.axesCount * tempPref(2) * enlargementFactor + 1 > 7.5
        tempPref(2) = 6.5 / enlargementFactor / handles.axesCount;
        warning(['Figures are too tall for the page. Height adjusted to ' num2str(tempPref(2)) ' inches.']);
    end

    figUnits = get(figure, 'units');
    set(figure, 'units', 'inches');
    set(figure, 'position', [100 100 tempPref(1) * enlargementFactor + 2 handles.axesCount * tempPref(2) * enlargementFactor + 1]);
    set(figure, 'units', figUnits);
    
    for i = 1:handles.axesCount
        set(handles.axes(i), 'units', 'inches', 'position', [100 100 + (i - 1) * tempPref(2) * enlargementFactor tempPref(1) * enlargementFactor tempPref(2) * enlargementFactor]);
        set(handles.axes(i), 'units', 'characters'); 
        if numel(analysisAxes{i}) > 1
            for j = 2:numel(analysisAxes{i})
                set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'units', 'inches', 'position', [100 100 + (i - 1) * tempPref(2) * enlargementFactor tempPref(1) * enlargementFactor tempPref(2) * enlargementFactor]);
                set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'units', 'characters'); 
            end
        end
    end
    set(figure, 'units', 'character', 'paperOrientation', 'portrait');
    
    % add scale bar
    scaleHandles = [];
    for i = 1:handles.axesCount
        stringData = get(handles.channelControl(i).channel, 'string');
		if iscell(stringData)
            stringData = stringData{get(handles.channelControl(i).channel, 'value')};
		end
        scaleHandles = [scaleHandles prepForPrint(handles.axes(i), stringData(end))];

        if numel(analysisAxes{i}) > 1
            for j = 2:numel(analysisAxes{i})
                analysisColors{i}(j, :) = get(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'ycolor');                
                scaleHandles = [scaleHandles prepForPrint(handles.analysisAxis{i}.(analysisAxes{i}{j}), get(get(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'ylabel'), 'string'))];
            end
        end
    end
    
    % add text specifying which traces we have
    if ispref('newScope', 'exportSettings') && tempPref(3)
        tempHandle = annotation('textbox', [.1 .1 .8 .3], 'linestyle', 'none', 'interpreter', 'none', 'verticalAlignment', 'bottom', 'horizontalAlignment', 'left', 'fontsize', 1, 'string', get(figure, 'name'));
    end
    
    % meta files print at screen resolution so for high resolution data
    % export as a postscript file and then import with Corel
    try
        print('-dmeta', '-noui', figure)
        print('-depsc2', '-r4800', '-noui', [getenv('homedrive') getenv('homepath') filesep 'temp.eps'], figure)
    catch
        % error in export
        warning('Error in export')
    end
    
    for i = 1:handles.axesCount
        kidKids = get(handles.axes(i), 'children');
        set(kidKids(end - 1:end), 'visible', 'on');
        
        if numel(analysisAxes{i}) > 1
            for j = 2:numel(analysisAxes{i})
                set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'xtick', [], 'ytickmode', 'auto', 'yticklabelmode', 'auto', 'xcolor', [0 0 0], 'ycolor', analysisColors{i}(j, :));                
            end
        end       
    end
    delete(scaleHandles);
    if ispref('newScope', 'exportSettings') && tempPref(3)
        delete(tempHandle)
    end
    
    set(handles.axes(1), 'xtickmode', 'auto', 'ytickmode', 'auto', 'xticklabelmode', 'auto', 'yticklabelmode', 'auto', 'xcolor', [0 0 0], 'ycolor', [0 0 0]);
    set(handles.axes(2:end), 'xtick', [], 'ytickmode', 'auto', 'yticklabelmode', 'auto', 'xcolor', [0 0 0], 'ycolor', [0 0 0]);
    set(handles.timeControl.frame, 'visible', 'on');
    set([handles.channelControl.frame], 'visible', 'on');  
    set(figure, 'WindowButtonMotionFcn', mouseCallbacks{1}, 'WindowButtonDownFcn', mouseCallbacks{2}, 'WindowButtonUpFcn', mouseCallbacks{3}, 'resizefcn', mouseCallbacks{4});
    set(figure, 'color', [0.8 0.8 0.8], 'position', figPos, 'visible', 'on');    