function scanPoints = spiralScan(ROI, tValues)
% create a spiral scan pattern for the given ROI
% tValues is in radians and is a two element vector of the form
% [startRadians endRadians]

if ROI.Type == 4 && ROI.Shape == 5
    % this is a spiral scanning ellipse
    
    if nargin < 2
        t = 0:2 * pi / ROI.PointsPerRotation:ROI.Rotations * 2 * pi - 2 * pi / ROI.PointsPerRotation;
    else
        t = tValues(1):2 * pi / ROI.PointsPerRotation:tValues(2);
    end
    
    % create the nucleus translation coefficients
    ROI.CentroidX = linspace(ROI.Centroid(1), ROI.Centroid(1) + 2 * ROI.MajorAxisLength * (ROI.NucleusCenter(1) - 50) / 100, fix(numel(t) / 2 + .5));
    ROI.CentroidY = linspace(ROI.Centroid(2), ROI.Centroid(2) + 2 * ROI.MinorAxisLength * (ROI.NucleusCenter(2) - 50) / 100, fix(numel(t) / 2 + .5));
    ROI.CentroidX(end + 1:numel(t)) = ROI.CentroidX(min([end fix(numel(t) / 2)]):-1:1);
    ROI.CentroidY(end + 1:numel(t)) = ROI.CentroidY(min([end fix(numel(t) / 2)]):-1:1);
    
    % create the spiraling radii
    ROI.MajorAxisLength = linspace(ROI.MajorAxisLength, ROI.MajorAxisLength * ROI.NucleusSize(1) / 100, fix(numel(t) / 2 + .5));
    ROI.MinorAxisLength = linspace(ROI.MinorAxisLength, ROI.MinorAxisLength * ROI.NucleusSize(2) / 100, fix(numel(t) / 2 + .5));
    ROI.MajorAxisLength(end + 1:numel(t)) = ROI.MajorAxisLength(min([end fix(numel(t) / 2)]):-1:1);
    ROI.MinorAxisLength(end + 1:numel(t)) = ROI.MinorAxisLength(min([end fix(numel(t) / 2)]):-1:1);
    
    % create the figure
    scanPoints = [ROI.CentroidX + ROI.MajorAxisLength .* cos(ROI.Orientation) .* cos(t) - ROI.MinorAxisLength .* sin(ROI.Orientation) .* sin(t);...
        ROI.CentroidY + ROI.MajorAxisLength .* sin(ROI.Orientation) .* cos(t) + ROI.MinorAxisLength .* cos(ROI.Orientation) .* sin(t)]';
    
    if nargout == 0
        % draw the figure on the image
        if isempty(ROI.segments)
            set(ROI.handle, 'xData', scanPoints(:,1), 'yData', scanPoints(:,2));
        else
            ROI.segments = [1/ROI.PointsPerRotation ROI.segments 1];
            for segIndex = 1:numel(ROI.segments) - 1
                whichPoints = [];
                for rotIndex = 0:fix(ROI.Rotations) - 1
                    whichPoints = [whichPoints (ROI.segments(segIndex) * ROI.PointsPerRotation:ROI.segments(segIndex + 1) * ROI.PointsPerRotation) + ROI.PointsPerRotation * rotIndex];
                end
                set(ROI.handle(segIndex), 'xData', scanPoints(whichPoints, 1), 'yData', scanPoints(whichPoints, 2));
            end
        end
    end     
else
    % either the ROI passed is not marked for Lissajous scanning or is not
    % a rectangle so return nothing
    scanPoints = [];
end