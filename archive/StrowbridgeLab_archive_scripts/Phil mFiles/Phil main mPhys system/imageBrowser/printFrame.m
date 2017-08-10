function printFrame(figHandle, axisHandle)

settings = getpref('imageBrowser', 'exportSettings');

% get the axis
handles = [];

% add the file path
if settings(1)
    handles = [handles text(min(get(axisHandle, 'xlim')), min(get(axisHandle, 'ylim')) - range(get(axisHandle, 'ylim')) / 20, get(figHandle, 'name'), 'interpreter', 'none', 'parent', axisHandle)];
end

% create a scale bar if requested
if settings(2) && isempty(findobj(figHandle, 'tag', 'scaleBar'))
    handles = [handles scaleBar(axisHandle, evalin('base', 'zImage.info'))];
end

% widen the figure and generate a color bar
fcnHandle = get(figHandle, 'resizeFcn');
savedSize = get(figHandle, 'position');
if settings(3)
    set(figHandle, 'resizeFcn', '');
    set(figHandle, 'position', savedSize + [0 0 40 0]);
    set(0, 'currentFigure', figHandle)
    handles = [handles colorbar('eastOutside')];
end

% print
if isdeployed
    deployprint;
else
    print('-v', figHandle);
end

set(figHandle, 'resizeFcn', fcnHandle);
set(figHandle, 'position', savedSize);
set(0, 'currentFigure', figHandle)

% clean up
if exist('handles', 'var')
    delete(handles);
end