function showFit(cell, stim, pspNumber, pspType)
% pulls up data trace and fits the alpha function to the PSP
    
if length(findstr(get(gcf, 'name'), 'Coupling')) < 1 || findstr(get(gcf, 'name'), 'Coupling') ~= 1
    error('Must first select a coupling figure')
end

if nargin < 1
    cell = 1;
end
if nargin < 2
    stim = 3;
end
if nargin < 3
    pspNumber = 1;
end
if nargin < 4
    pspType = 0;    
    params = inputdlg({'Cell:', 'Stimulus Number:', 'PSP Number', 'PSP Down (0 or 1)'},'',1, {num2str(cell), num2str(stim), num2str(pspNumber), num2str(pspType)});
    if isempty(params)
        return
    end
    cell = str2double(params{1});
    stim = str2double(params{2});
    pspNumber = params{3};
    pspType = str2double(params{4});
end

tempData = get(gcf, 'userData');
channels = tempData{1};
stims = tempData{3};
PSPdata = tempData{4};

if pspType == 0
    whichPSPs = find(PSPdata(cell, stim, 3, :) > 0);
else
    whichPSPs = find(PSPdata(cell, stim, 3, :) < 0);
end


try
    whichPSPs = eval(['whichPSPs(' pspNumber ')']);
catch
    error(['PSP number(s) inappropriate.  ' num2str(length(whichPSPs)) ' PSPs available.'])
end

fileRoot = get(gcf, 'name');
newRoot = '';
for pspIndex = whichPSPs'
    if isempty(newRoot)
        filePath = [fileRoot(11:end) '.S' num2str(PSPdata(cell, stim, 1, pspIndex)) '.E' num2str(PSPdata(cell, stim, 2, pspIndex)) '.dat'];
    else
        filePath = [newRoot fileRoot(11 + numChars:end) '.S' num2str(PSPdata(cell, stim, 1, pspIndex)) '.E' num2str(PSPdata(cell, stim, 2, pspIndex)) '.dat'];            
    end
    try
        zData = readTrace(filePath);
    catch
        error(['Error reading file ' filePath])
    end
    if isempty(zData)
        options.Resize = 'on';
        outputArgs = inputdlg({'Please truncate to old metaroot', 'Please enter new root'}, 'File not found', 2, {fileRoot(11:end), 'Y:\Larimer\Data\2005\Multidata'}, options);
        numChars = numel(outputArgs{1});
        newRoot = outputArgs{2};
        zData = readTrace([newRoot fileRoot(11 + numChars:end) '.S' num2str(PSPdata(cell, stim, 1, pspIndex)) '.E' num2str(PSPdata(cell, stim, 2, pspIndex)) '.dat']);            
    end    
    tempSpikes = detectSpikes(zData.traceData(stims(stim):stims(stim) + 20 * 5, channels(fix((stim + 1) / 2))));

    handles = newScope({zData.traceData(:, channels(fix((stim + 1) / 2))), zData.traceData(:, cell)}, zData.protocol.timePerPoint / 1000:zData.protocol.timePerPoint / 1000:zData.protocol.sweepWindow, {'Pre V', 'Post V'});
    set(handles.axes, 'xlim', stims(stim) * zData.protocol.timePerPoint / 1000 + [-2 50])
    updateTrace(handles.figure, 'all');
    % show spike time
    line(zData.protocol.timePerPoint ./ 1000 .* [tempSpikes(1) + stims(stim) tempSpikes(1) + stims(stim)], get(handles.axes(1), 'ylim'), 'parent', handles.axes(1), 'color', [0 1 0]);
    line(zData.protocol.timePerPoint ./ 1000 .* [tempSpikes(1) + stims(stim) tempSpikes(1) + stims(stim)], get(handles.axes(2), 'ylim'), 'parent', handles.axes(2), 'color', [0 1 0]);    

    % show start and peak
    line(zData.protocol.timePerPoint ./ 1000 .* (tempSpikes(1) + stims(stim)) + PSPdata(cell, stim, 5, pspIndex), zData.traceData(round(tempSpikes(1) + stims(stim) + 1000 / zData.protocol.timePerPoint * PSPdata(cell, stim, 5, pspIndex)), cell), 'parent', handles.axes(2), 'marker', '+', 'color', [1 0 0]);
    line(zData.protocol.timePerPoint ./ 1000 .* (tempSpikes(1) + stims(stim)) + sum(PSPdata(cell, stim, 4:5, pspIndex)), zData.traceData(round(tempSpikes(1) + stims(stim) + 1000 / zData.protocol.timePerPoint * sum(PSPdata(cell, stim, 4:5, pspIndex))), cell), 'parent', handles.axes(2), 'marker', '+', 'color', [0 0 1]);

    % show decay tau
    line(zData.protocol.timePerPoint ./ 1000 .* (tempSpikes(1) + stims(stim)) + sum(PSPdata(cell, stim, 4:5, pspIndex)) + [0 PSPdata(cell, stim, 6, pspIndex)], zData.traceData(tempSpikes(1) + stims(stim) + 1000 / zData.protocol.timePerPoint * sum(PSPdata(cell, stim, 4:5, pspIndex)), cell) + [0 0], 'parent', handles.axes(2), 'color', [0 1 0]);
    line(zData.protocol.timePerPoint ./ 1000 .* (tempSpikes(1) + stims(stim)) + sum(PSPdata(cell, stim, 4:5, pspIndex)) + [0 PSPdata(cell, stim, 6, pspIndex)], zData.traceData(tempSpikes(1) + stims(stim) + 1000 / zData.protocol.timePerPoint * sum(PSPdata(cell, stim, 4:5, pspIndex)), cell) - (1 - exp(-1)) * PSPdata(cell, stim, 3, pspIndex) + [0 0], 'parent', handles.axes(2), 'color', [0 1 0]);
end