function printWithAxes(figure)

% function for printing a newScope

    if nargin == 0
        figure = gcf;
    end

    handles = get(figure, 'userData');
    mouseCallbacks = {get(figure, 'WindowButtonMotionFcn') get(figure, 'WindowButtonDownFcn') get(figure, 'WindowButtonUpFcn')};
    set(figure, 'visible', 'off', 'WindowButtonMotionFcn', '', 'WindowButtonDownFcn', '', 'WindowButtonUpFcn', '');
    figPos = get(figure, 'position');    

    % hide the cursors
    for i = 1:handles.axesCount
       kidKids = get(handles.axes(i), 'children');
       set(kidKids(end - 1:end), 'visible', 'off');
    end

    set(handles.timeControl.frame, 'visible', 'off');
    set([handles.channelControl.frame], 'visible', 'off');
    
    % zbuffer is printing a bitmap, whereas painters use vector graphics
    if handles.axesCount > 1
        set(figure, 'PaperOrientation', 'portrait', 'PaperPosition', [.25 .25 8 10], 'units', 'inches', 'position', [1 1 9.5 10.5])        
    else
        set(figure, 'PaperOrientation', 'landscape', 'PaperPosition', [.25 .25 10.5 7.5], 'units', 'inches', 'position', [1 1 12 7.5])        
    end
    set(figure, 'units', 'characters');
    
    if isdeployed
        deployprint('-noui');
    else
        print('-v', '-loose', '-noui', figure)
    end

    for i = 1:handles.axesCount
       kidKids = get(handles.axes(i), 'children');
       set(kidKids(end - 1:end), 'visible', 'on');
    end

    set(handles.timeControl.frame, 'visible', 'on');
    set([handles.channelControl.frame], 'visible', 'on');  
    set(figure, 'WindowButtonMotionFcn', mouseCallbacks{1}, 'WindowButtonDownFcn', mouseCallbacks{2}, 'WindowButtonUpFcn', mouseCallbacks{3});
    set(figure, 'position', figPos, 'visible', 'on');       