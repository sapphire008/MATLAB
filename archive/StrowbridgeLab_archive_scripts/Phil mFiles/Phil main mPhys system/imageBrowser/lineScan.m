function scanPoints = lineScan(ROI)
% create a line scan pattern for the given ROI
% tValues is in radians and is a two element vector of the form
% [startRadians endRadians]

if ROI.Type == 4 && ROI.Shape == 6
    % this is a scanning line    

%     scanParameters.voltsX = ROI.MajorAxisLength;
%     scanParameters.voltsY = 0;
%     scanParameters.centerX = ROI.Centroid(1);
%     scanParameters.centerY = ROI.Centroid(2);
%     scanParameters.pixelUs = str2double(get(findobj('tag', 'txtPixelUs'), 'string'));
%     scanParameters.pixelsX = ROI.PointsPerRotation;
%     scanParameters.pixelsY = 2;
%     scanParameters.rotationRadians = ROI.Orientation;
%     scanParameters.maximumAcc = 10;
%     scanPoints = rasterScan(scanParameters);
    ROI.MajorAxisLength = ROI.MajorAxisLength * 3;
    t = (1:ROI.PointsPerRotation) ./ (2 * pi);
    scanPoints = [ROI.Centroid(1) + ROI.MajorAxisLength .* cos(ROI.Orientation) .* cos(t) - ROI.MinorAxisLength .* sin(ROI.Orientation) .* sin(t);...
        ROI.Centroid(2) + ROI.MajorAxisLength .* sin(ROI.Orientation) .* cos(t) + ROI.MinorAxisLength .* cos(ROI.Orientation) .* sin(t)]';

    
    if nargout == 0
        % draw the figure on the image
        set(ROI.handle, 'xData', scanPoints(:,1), 'yData', scanPoints(:,2));
    end    
else
    % the ROI passed is not marked for line scanning
    scanPoints = [];
end