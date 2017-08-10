function photometrySetup(duration)

wasVisible = get(getappdata(0, 'photometryPath'), 'visible');
set(getappdata(0, 'photometryPath'), 'visible', 'off');
pixelUs = str2double(get(findobj('tag', 'txtPixelUs'), 'string'));  
ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');    

% determine which ROI will be scanned
switch get(get(findobj('tag', 'imageScan'), 'selectedObject'), 'tag')
    case 'scanAllRoi'
        [scanPoints beamOnPoints scanOrder] = sequenceScan;
    case 'scanCurrentRoi'
        [scanPoints beamOnPoints scanOrder] = sequenceScan(get(findobj('tag', 'cboRoiNumber'), 'value'));
        ROI = ROI(get(findobj('tag', 'cboRoiNumber'), 'value'));
    case 'scanSpecifiedRoi'
        [scanPoints beamOnPoints scanOrder] = sequenceScan(str2num(protocolData.scanWhichRoi{1}));
        ROI = ROI(str2num(protocolData.scanWhichRoi{1}));
end

% create a data set of location vs time in cycle
numPoints = size(scanPoints, 1);
galvoLocations = takeTwoPhotonImage([], repmat(scanPoints, 5, 1), [], pixelUs, 1);  
info = getappdata(getappdata(0, 'imageBrowser'), 'info');
voltSize = sscanf(info.SizeOnSource, 'Size = %g by %g mV'); 
centerLoc = sscanf(info.Comment, 'Center = %g x %g mV');            
galvoLocations = [(galvoLocations.photometry(numPoints * 3 + 1:numPoints * 4,1) - centerLoc(1)) ./ voltSize(1) .* info.Width + info.Width / 2 ...
        (galvoLocations.photometry(numPoints * 3 + 1:numPoints * 4,2) - centerLoc(2)) ./ voltSize(2) .* info.Height + info.Height / 2];            
galvoHandle = findobj(findobj('tag', 'imageAxis'), 'tag', 'galvoHandle');
if isempty(galvoHandle);
    galvoHandle = line(0, 0,...
        'lineWidth', 2,...
        'color', [0 0 1],...
        'parent', findobj('tag', 'imageAxis'),...
        'tag', 'galvoHandle');
end
set(galvoHandle, 'xData', galvoLocations(:, 1), 'yData', galvoLocations(:,2));
if numPoints * pixelUs > 1000
    set(getappdata(0, 'imageBrowser'), 'name', [sprintf('%1.2f', numPoints * pixelUs / 1000) ' ms per circuit']);
else
    set(getappdata(0, 'imageBrowser'), 'name', [sprintf('%1.1f', numPoints * pixelUs) ' ' char(181) 's per circuit']);
end            

% build the scan to equal the scan duration
if size(scanPoints, 1) < duration * 1000 / pixelUs
    scanPoints = repmat(scanPoints, fix(duration * 1000 / pixelUs / size(scanPoints, 1)), 1);
end

% truncate the points to the limits of the AD board
if any(any(abs(scanPoints) > 10))
    switch questdlg(['At the current pixel duration of ' sprintf('%0.1f', pixelUs) ' ' char(181) 's the scan requires voltage deviations of ' sprintf('%0.1f', max(max(abs(scanPoints)))) ' volts, exceeding those allowed by the AD board (10 volts).  Would you like to use a truncated version or abort the scan to adjust the pixel duration?'], 'Too Fast', 'Truncate', 'Abort', 'Truncate')
        case 'Truncate'
            scanPoints(scanPoints > 10) = 10;
            scanPoints(scanPoints < -10) = -10;
        otherwise
            return
    end
end

setappdata(getappdata(0, 'rasterScan'), 'onTimes', onTimes);
setappdata(getappdata(0, 'rasterScan'), 'offTimes', offTimes);
setappdata(getappdata(0, 'rasterScan'), 'beamOnPoints', beamOnPoints);
setappdata(getappdata(0, 'rasterScan'), 'scanOrder', scanOrder);
setappdata(getappdata(0, 'rasterScan'), 'ROI', ROI);
setappdata(getappdata(0, 'rasterScan'), 'wasVisible', wasVisible);
takeTwoPhotonImage([], scanPoints, [], pixelUs, 0, 1);