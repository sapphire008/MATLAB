function showFrameMarker(axisHandle)

ylims = get(axisHandle, 'ylim');
kids = get(axisHandle, 'children');

% deal with frame marker if present
markerHandle = kids(strcmp(get(kids, 'userData'), 'frameMarker'));
if ~isempty(markerHandle)
    set(markerHandle, 'ydata', [ylims(1) ylims(1)]);
end