function exportFrame(figHandle, axisHandle)

settings = getpref('imageBrowser', 'exportSettings');
info = getappdata(getappdata(0, 'imageBrowser'), 'info');

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
set(figHandle, 'position', [0 0 info.Width info.Height]);
drawnow
if settings(3)
    set(figHandle, 'resizeFcn', '');    
    set(figHandle, 'position', get(figHandle, 'position') + [0 0 40 0]);
    set(0, 'currentFigure', figHandle)    
    handles = [handles colorbar('eastOutside')];
end

% hide any clearing ROI
ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
if ~isempty(ROI)
	wasVisible = strcmp(get([ROI.handle], 'visible'), 'on')';
	set([ROI([ROI.Type] == 2 & wasVisible).handle], 'visible', 'off');
end

% print
print('-dmeta', figHandle);

set(figHandle, 'resizeFcn', fcnHandle);
set(figHandle, 'position', savedSize);
set(0, 'currentFigure', figHandle)

% clean up
if exist('handles', 'var')
    delete(handles);
end

% show clearing ROI again
if ~isempty(ROI)
	set([ROI([ROI.Type] == 2 & wasVisible).handle], 'visible', 'on');
end