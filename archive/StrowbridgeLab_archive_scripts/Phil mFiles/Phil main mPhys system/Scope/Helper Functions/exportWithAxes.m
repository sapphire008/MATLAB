function exportWithAxes(figure)

% function for converting a newScope to an enhanced meta-file on the clipboard

    if nargin == 0
        figure = gcf;
    end

    handles = get(figure, 'userData');

    % hide the cursors
    for i = 1:handles.axesCount
       kidKids = get(handles.axes(i), 'children');
       set(kidKids(end - 1:end), 'visible', 'off');
    end

    set(handles.timeControl.frame, 'visible', 'off');
    set([handles.channelControl.frame], 'visible', 'off');

    if handles.axesCount > 1
        set(figure, 'PaperOrientation', 'portrait');
        set(figure, 'PaperPosition', [.25 .25 9.5 10.25])        
    else
        set(figure, 'PaperOrientation', 'landscape');
        set(figure, 'PaperPosition', [.25 .25 12.25 7.75])        
    end    
    
    % zbuffer is printing a bitmap, whereas painters use vector graphics
    print('-dmeta', '-loose', '-noui', figure)

    for i = 1:handles.axesCount
       kidKids = get(handles.axes(i), 'children');
       set(kidKids(end - 1:end), 'visible', 'on');
    end

    set(handles.timeControl.frame, 'visible', 'on');
    set([handles.channelControl.frame], 'visible', 'on');    