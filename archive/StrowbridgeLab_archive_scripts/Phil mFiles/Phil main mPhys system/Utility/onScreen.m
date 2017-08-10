function figHandle = onScreen(figHandle)
    tempPos = get(figHandle, 'position');
    set(0, 'units', get(figHandle, 'units'));
    screenLims = get(0, 'monitorPosition');
    screenLims = [min(screenLims(:,1:2), [], 1) max(screenLims(:,3:4), [], 1)];
    set(0, 'units', 'norm');
    menuBarSize = hgconvertunits(figHandle, [40 40 40 40], 'pix', get(figHandle, 'units'), 0);
    screenLims(4) = screenLims(4) - menuBarSize(4);
    set(figHandle, 'position', [max([screenLims(1) min([screenLims(3) - tempPos(3) tempPos(1)])]) max([screenLims(2) min([screenLims(4) - tempPos(4) tempPos(2)])]) tempPos(3:4)]);