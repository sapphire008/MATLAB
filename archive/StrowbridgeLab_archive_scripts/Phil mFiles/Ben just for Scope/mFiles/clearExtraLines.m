function clearExtraLines

        for i = getappdata(0, 'scopes')'
            handles = get(i, 'userData');
            for j = 1:handles.axesCount
                kids = get(handles.axes(j), 'children');
                delete(kids(~strcmp(get(kids(1:end - 2), 'userData'), 'data')))
                set(kids(end - 1:end), 'ydata', get(handles.axes(j), 'ylim'));
            end
        end