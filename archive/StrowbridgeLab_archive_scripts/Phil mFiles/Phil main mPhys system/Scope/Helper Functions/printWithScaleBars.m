function printWithScaleBars(figure, protocolData)

% function for printing a newScope

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

    % set(handles.axes, 'xtick', [], 'ytick', []);
    set(handles.timeControl.frame, 'visible', 'off');
    set([handles.channelControl.frame], 'visible', 'off');
    set(figure, 'inverthardcopy', 'off', 'color', [1 1 1]);
    if ispref('newScope', 'exportSettings')
        tempPref = getpref('newScope', 'exportSettings');        
    end  
    
    % add scale bar
    scaleHandles = [];
    for i = 1:handles.axesCount
        stringData = get(handles.channelControl(i).channel, 'string');
        if iscell(stringData)
            stringData = stringData{get(handles.channelControl(i).channel, 'value')};
        else
            stringData = 'AAAAAAAAA';
        end
        if i == 1
            scaleHandles = [scaleHandles prepForPrint(handles.axes(i), stringData(end))];
        else
            scaleHandles = [scaleHandles prepForPrint(handles.axes(i), stringData(end), 'yOnly')];
        end
        if numel(analysisAxes{i}) > 1
            for j = 2:numel(analysisAxes{i})
                analysisColors{i}(j, :) = get(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'ycolor');                
                scaleHandles = [scaleHandles prepForPrint(handles.analysisAxis{i}.(analysisAxes{i}{j}), get(get(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'ylabel'), 'string'), 'yOnly')];
                kidKids = get(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'children');
                set(kidKids(1:2), 'color', analysisColors{i}(j, :));
            end
        end        
    end
    
    % add text specifying which traces we have
    if ispref('newScope', 'exportSettings') && tempPref(3) 
        tempHandle = annotation('textbox', [0 0 1 .1], 'linestyle', 'none', 'interpreter', 'none', 'verticalAlignment', 'bottom', 'horizontalAlignment', 'left', 'fontsize', 8, 'string', get(figure, 'name'));    
    end
    
    % zbuffer is printing a bitmap, whereas painters use vector graphics
    set(figure, 'units', 'inches');
    if handles.axesCount > 1
        set(figure, 'PaperOrientation', 'portrait', 'paperposition', [.25 .25 8 10.5], 'position', [1 1 10.5 8]);
        for i = 1:handles.axesCount
            set(handles.axes(i), 'units', 'inches', 'position', [1 1 + sum(handles.axisPortion(1:i - 1)) * 9.25 6.75 9.25 * handles.axisPortion(i)]);
            set(handles.axes(i), 'units', 'characters');         
            if numel(analysisAxes{i}) > 1
                for j = 2:numel(analysisAxes{i})
                    set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'units', 'inches', 'position', [1 1 + sum(handles.axisPortion(1:i - 1)) * 9.25 6.75 9.25 * handles.axisPortion(i)]);
                    set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'units', 'characters'); 
                end
            end              
        end                      
    else
        set(figure, 'PaperOrientation', 'landscape', 'paperposition', [.25 .25 10.5 8], 'position', [1 1 8 10.5]);
        for i = 1:handles.axesCount
            set(handles.axes(i), 'units', 'inches', 'position', [1 1 + sum(handles.axisPortion(1:i - 1)) * 6.75 9.25 6.75 * handles.axisPortion(i)]);
            set(handles.axes(i), 'units', 'characters');         
        end        
        if numel(analysisAxes{i}) > 1
            for j = 2:numel(analysisAxes{i})
                set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'units', 'inches', 'position', [1 1 + sum(handles.axisPortion(1:i - 1)) * 6.75 9.25 6.75 * handles.axisPortion(i)]);
                set(handles.analysisAxis{i}.(analysisAxes{i}{j}), 'units', 'characters'); 
            end
        end                
    end

    set(figure, 'units', 'characters');
    
    if isdeployed
        deployprint('-noui');
    else
        print('-v', '-noui', figure);
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

    set(figure, 'color', [0.8 0.8 0.8]);
    set(handles.axes(1), 'xtickmode', 'auto', 'ytickmode', 'auto', 'xticklabelmode', 'auto', 'yticklabelmode', 'auto', 'xcolor', [0 0 0], 'ycolor', [0 0 0]);
    set(handles.axes(2:end), 'xtick', [], 'xticklabelmode', 'auto', 'ytickmode', 'auto', 'yticklabelmode', 'auto', 'xcolor', [0 0 0], 'ycolor', [0 0 0]);
    set(handles.timeControl.frame, 'visible', 'on');
    set([handles.channelControl.frame], 'visible', 'on');   
    set(figure, 'WindowButtonMotionFcn', mouseCallbacks{1}, 'WindowButtonDownFcn', mouseCallbacks{2}, 'WindowButtonUpFcn', mouseCallbacks{3}, 'resizefcn', mouseCallbacks{4});
    set(figure, 'color', [0.8 0.8 0.8], 'position', figPos, 'visible', 'on');   