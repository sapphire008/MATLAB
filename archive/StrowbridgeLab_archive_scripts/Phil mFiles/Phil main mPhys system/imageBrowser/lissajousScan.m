function scanPoints = lissajousScan(ROI, tValues)
% create a Lissajous scan pattern for the given ROI
% tValues is in radians and is a two element vector of the form
% [startRadians endRadians]

if ROI.Type == 4 && ROI.Shape == 4
    % this is a Lissajous scanning rectangle   
    if nargin < 2
        t = 0:2 * pi / ROI.PointsPerRotation:ROI.Rotations * 2 * pi - 2 * pi / ROI.PointsPerRotation;
    else
       t = tValues(1):2 * pi / ROI.PointsPerRotation:tValues(2); 
    end
    
    % create the figure in non-rotated space
    scanPoints = [...
       ROI.MajorAxisLength .* sin(t * ROI.Lissajous(2)); ...
       ROI.MinorAxisLength .* cos(t * ROI.Lissajous(1))]';
   
    % rotate the figure
    scanPoints = scanPoints *...
        [cos(-ROI.Orientation) -sin(-ROI.Orientation);...
         sin(-ROI.Orientation) cos(-ROI.Orientation)];

    % offset the figure
    scanPoints(:, 1) = scanPoints(:, 1) + ROI.Centroid(1);
    scanPoints(:, 2) = scanPoints(:, 2) + ROI.Centroid(2);
    
    if nargout == 0
        % draw the figure on the image
        if isempty(ROI.segments)
            set(ROI.handle, 'xData', scanPoints(:,1), 'yData', scanPoints(:,2));
        else
            ROI.segments = [0 ROI.segments 1];
            tempPoints = sin(t * ROI.Lissajous(2)) ./ 2 + 0.5; % just the 'x' points      
            for segIndex = 1:numel(ROI.segments) - 1
                set(ROI.handle(segIndex), 'xData', scanPoints(tempPoints > ROI.segments(segIndex) & tempPoints <= ROI.segments(segIndex + 1), 1), 'yData', scanPoints(tempPoints > ROI.segments(segIndex) & tempPoints <= ROI.segments(segIndex + 1), 2));
            end
        end
    end
else
    % either the ROI passed is not marked for Lissajous scanning or is not
    % a rectangle so return nothing
    scanPoints = [];
end