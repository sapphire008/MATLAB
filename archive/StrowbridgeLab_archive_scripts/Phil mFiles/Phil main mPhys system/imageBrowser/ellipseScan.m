function scanPoints = ellipseScan(ROI, tValues)
% create an ellipse scan pattern for the given ROI
% tValues is in radians and is a two element vector of the form
% [startRadians endRadians]

if ROI.Shape == 1
    % this is a scanning ellipse   
    if nargin < 2
        t = 0:2 * pi / ROI.PointsPerRotation:ROI.Rotations * 2 * pi - 2 * pi / ROI.PointsPerRotation;
    else
        t = tValues(1):2 * pi / ROI.PointsPerRotation:tValues(2);
    end
    
    % create the figure
    scanPoints = [ROI.Centroid(1) + ROI.MajorAxisLength .* cos(ROI.Orientation) .* cos(t) - ROI.MinorAxisLength .* sin(ROI.Orientation) .* sin(t);...
        ROI.Centroid(2) + ROI.MajorAxisLength .* sin(ROI.Orientation) .* cos(t) + ROI.MinorAxisLength .* cos(ROI.Orientation) .* sin(t)]';
    
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