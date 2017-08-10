function [scanPoints beamOnPoints scanOrder] = sequenceScan(scanOrder)
% Generate a galvo trajectory that rings the perimeter of all ellipses
% passed and is repeatable

% start with a tangent from the ellipse closest to the center to the
% ellipse farthest from the center

% loop through all the ellipses circling them [7pi/4 15pi/4) times
% then find the clockwise, non-switching tangent to every other ellipse and
% the distance of this line connecting them
% weighting by distance from the center, find the minimum circling distance
% to the next ellipse and go there

% scanOrder is a vector of indices into ROI
% if any member of scanOrder is negative then the indices passed are all
% included but the order in which they occur in the vector is disregarded
%
% scanPoints is a two column matrix of scanner-controller voltages,
% beamOnPoints is a one column boolean vector for controlling a pockel cell

% %%%%%%%%%%%%%%%%%%%%%%%
% line should have a ramp acceleration/decceleration
% need to upsample figures 
% also the lastROI is not unrotated so causes an error getting tangent
% %%%%%%%%%%%%%%%%%%%%%%%

debugging = 0;

lineResolution = .02; % in V / fast pixel

ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
info = getappdata(getappdata(0, 'imageBrowser'), 'info');

if nargin == 1 
    % remove any inappropriate indices    
    scanOrder = round(scanOrder(scanOrder < numel(ROI) + 0.5 & abs(scanOrder) >= 0.5));
    
    % only scan photometry ROI
    scanOrder = scanOrder([ROI(abs(scanOrder)).Type] == 4);
    
    if any(scanOrder < 0) || numel(scanOrder) == 1
        scanOrder = abs(scanOrder);
        ROI = ROI(scanOrder);
        clear scanOrder;
    end
else
    ROI = ROI([ROI.Type] == 4 & [ROI.Shape] ~= 6);
end

% initialize the variables
    scanPoints = nan(2 * numel(ROI) * sum([ROI.Rotations] .* [ROI.PointsPerRotation]), 2); % location of each pixel addressed
    beamOnPoints = nan(size(scanPoints, 1), 1); % when the pockel cell will be "on"
    currentPoint = 0;
    
% convert all ROI to voltages
voltSize = sscanf(info.SizeOnSource, 'Size = %g by %g mV');
centerLoc = sscanf(info.Comment, 'Center = %g x %g mV');    
pixelUs = str2double(get(findobj('tag', 'txtPixelUs'), 'string'));    
% return the points as voltages
scanPoints(:,1) = (scanPoints(:,1) - info.Width / 2) ./ info.Width .* voltSize(1) + centerLoc(1);
scanPoints(:,2) = (scanPoints(:,2) - info.Height / 2) ./ info.Height .* voltSize(2) + centerLoc(2);
for roiIndex = 1:numel(ROI)
    % convert axis lengths to volts, correcting the amplitude for the frequency
    if isempty(ROI(roiIndex).Lissajous)
        ROI(roiIndex).MajorAxisLength = correctY(ROI(roiIndex).MajorAxisLength / info.Width * voltSize(1), 1000000 / pixelUs / ROI(roiIndex).PointsPerRotation);
        ROI(roiIndex).MinorAxisLength = correctX(ROI(roiIndex).MinorAxisLength / info.Height * voltSize(2), 1000000 / pixelUs / ROI(roiIndex).PointsPerRotation);        
    else
        ROI(roiIndex).MajorAxisLength = correctY(ROI(roiIndex).MajorAxisLength / info.Width * voltSize(1), ROI(roiIndex).Lissajous(1) * 1000000 / pixelUs / ROI(roiIndex).PointsPerRotation);
        ROI(roiIndex).MinorAxisLength = correctX(ROI(roiIndex).MinorAxisLength / info.Height * voltSize(2), ROI(roiIndex).Lissajous(2) * 1000000 / pixelUs / ROI(roiIndex).PointsPerRotation);
    end
    
    % convert the centroid locations to voltages
    ROI(roiIndex).Centroid = (ROI(roiIndex).Centroid - [info.Width info.Height] ./ 2) ./ [info.Width info.Height] .* voltSize' + centerLoc';
end

if numel(ROI) == 1
    % simplest case
        addFigurePoints(1, 2 * pi / ROI.PointsPerRotation, 0)
        scanOrder = 1;
elseif isempty(ROI)
    % may have gotten here by rejecting a line scan so look for the first
    % line
    [scanPoints beamOnPoints scanOrder] = sequenceScan(1);  
    ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');

    % remove any inappropriate indices    
    scanOrder = round(scanOrder(scanOrder < numel(ROI) + 0.5 & abs(scanOrder) >= 0.5));
    
    % only scan photometry ROI
    ROI = ROI(1);
elseif ~exist('scanOrder', 'var')
    % 1 - the normalized distance from the center
        distanceFromCenter = sqrt(sum((cat(1, ROI.Centroid) - repmat([voltSize(1) / 2 + centerLoc(1) voltSize(2) / 2 + centerLoc(2)], numel(ROI), 1)) .^2, 2));
        distanceFromCenter = 1 - (distanceFromCenter - min(distanceFromCenter)) ./ range(distanceFromCenter);

    % find the tangent from the ROI closest to center to that farthest
        % middle-most and middle-least ROI
        [currentROI currentROI] = max(distanceFromCenter);
        [whichROI whichROI] = min(distanceFromCenter);

        % find the first tangent
        [tangentStart tangentStop firstT] = findTangent(ROI(currentROI), ROI(whichROI));

        % add the line data
        addLinePoints(tangentStart, tangentStop)

        % save the roiNum for the end
        firstROI = currentROI;
        currentROI = whichROI;
        startingT = tGivenX(tangentStop, currentROI);
        scanOrder = [firstROI currentROI];

    % do the same for the remaining ROI
        beenUsed = [firstROI currentROI];
        while numel(beenUsed) < numel(ROI)
            tangentStarts = nan(numel(ROI), 2);
            tangentStops = tangentStarts;
            tangentTs = nan(numel(ROI), 1);
            % determine intersection via the discriminant of the quadratic
            for roiIndex = setdiff(1:numel(ROI), beenUsed)
                [tangentStarts(roiIndex, :) tangentStops(roiIndex, :) tangentTs(roiIndex)] = findTangent(ROI(currentROI), ROI(roiIndex));
            end % for roiIndex

            % determine which will be next using distance from center and angle to the ROI
            angles = atan((tangentStops(:,2) - tangentStarts(:,2)) ./ (tangentStops(:,1) - tangentStarts(:,1)));
            [whichROI whichROI] = min(angles .* distanceFromCenter);
            scanOrder(end + 1) = whichROI;

            % add the ellipse data
            addFigurePoints(currentROI, startingT, tangentTs(whichROI)); 

            % add the line data
            addLinePoints(tangentStarts(whichROI, :), tangentStops(whichROI, :))

            % add the ROI to those already used
            beenUsed = [beenUsed whichROI];
            currentROI = whichROI;

            startingT = tGivenX(tangentStops(whichROI, :), currentROI);

        end % while numel(beenUsed) < numel(ROI)       
        % find the last tangent
        [tangentStart tangentStop lastT] = findTangent(ROI(currentROI), ROI(firstROI));

        % add the data for the last ellipse
        addFigurePoints(currentROI, startingT, lastT);

        % add the line data
        addLinePoints(tangentStart, tangentStop)        

        % add the data for the first ellipse
        startingT = tGivenX(tangentStop, firstROI); % not correct
        addFigurePoints(firstROI, startingT, firstT);

        % truncate the arrays
        scanPoints = scanPoints(~isnan(scanPoints(:,1)), :);
        beamOnPoints = beamOnPoints(~isnan(beamOnPoints));
else % exist('scanOrder', 'var')
    scanOrder = scanOrder([end 1:end - 1]);

   % find the first tangent
    [tangentStart tangentStop firstT] = findTangent(ROI(scanOrder(1)), ROI(scanOrder(2)));

    % add the line data
    addLinePoints(tangentStart, tangentStop)

    startingT = tGivenX(tangentStop, scanOrder(2));

    % do the same for the remaining ROI
    for roiIndex = 2:numel(scanOrder) - 1
        [tangentStart tangentStop tangentT] = findTangent(ROI(scanOrder(roiIndex)), ROI(scanOrder(roiIndex + 1)));

        % add the ellipse data
        addFigurePoints(scanOrder(roiIndex), startingT, tangentT); 

        % add the line data
        addLinePoints(tangentStart, tangentStop)

        startingT = tGivenX(tangentStop, scanOrder(roiIndex + 1));

    end % while numel(beenUsed) < numel(ROI)       
    % find the first tangent
    [tangentStart tangentStop lastT] = findTangent(ROI(scanOrder(end)), ROI(scanOrder(1)));

    % add the data for the last ellipse
    addFigurePoints(scanOrder(end), startingT, lastT);

    % add the line data
    addLinePoints(tangentStart, tangentStop)        

    % add the data for the first ellipse
    startingT = tGivenX(tangentStop, scanOrder(1));
    addFigurePoints(scanOrder(1), startingT, firstT);
end

% truncate the arrays
scanPoints = scanPoints(~isnan(scanPoints(:,1)), :);
beamOnPoints = beamOnPoints(~isnan(beamOnPoints));     
scanOrder = scanOrder([2:end 1]);

if nargout == 0
    figure('numbertitle', 'off', 'name', 'Click to Repeat', 'buttonDownFcn', @drawPath)
    set(gca, 'xlim', [centerLoc(1) - voltSize(1) / 2 centerLoc(1) + voltSize(1) / 2], 'ylim', [centerLoc(2) - voltSize(2) / 2 centerLoc(2) + voltSize(2) / 2]);
    line(scanPoints(:,1),scanPoints(:,2), 'lineStyle', 'none', 'marker', '.', 'color', [0 0 0], 'markerSize', 1)
    axis equal    
    for i = 1:numel(scanOrder)
        text(ROI(scanOrder(i)).Centroid(1), ROI(scanOrder(i)).Centroid(2), sprintf('%0.0f', i));
    end
    whereHandle = line('lineStyle', 'none', 'marker', '.', 'markerSize', 10);
    drawPath;
end

    function drawPath(varargin)
        for i = 1:size(scanPoints, 1)
            if beamOnPoints(i)
                set(whereHandle, 'xData', scanPoints(i,1), 'yData', scanPoints(i,2), 'color', [1 0 0]);
            else
                set(whereHandle, 'xData', scanPoints(i,1), 'yData', scanPoints(i,2), 'color', [0 0 1]);
            end
            drawnow
        end
    end

%%%%%%%%%%%%%%%%%%%
% private functions
%%%%%%%%%%%%%%%%%%%

    function addFigurePoints(roiNum, startingT, stoppingT)
        % add points for traversing whichROI from t = startingT to t =
        % stoppingT
        if stoppingT - startingT < - pi / 2
            stoppingT = stoppingT + 2 * pi;
        elseif stoppingT - startingT > 3 * pi / 2;
            stoppingT = stoppingT - 2 * pi;
        end        
        switch ROI(roiNum).Shape
            case 1 % ellipse
                tempData = ellipseScan(ROI(roiNum), [startingT stoppingT + 2 * pi * ROI(roiNum).Rotations] + ROI(roiNum).Orientation);
            case 4 % Lissajous
                tempData = lissajousScan(ROI(roiNum), [startingT stoppingT + 2 * pi * ROI(roiNum).Rotations] + ROI(roiNum).Orientation);
            case 5 % spiral
                tempData = spiralScan(ROI(roiNum), [startingT stoppingT + 2 * pi * ROI(roiNum).Rotations] + ROI(roiNum).Orientation);
            case 6 % line
                tempData = lineScan(ROI(roiNum));
        end
        scanPoints(currentPoint + (1:size(tempData, 1)), :) = tempData;        
        beamOnPoints(currentPoint + (1:size(tempData, 1))) = 1;
        currentPoint = currentPoint + size(tempData, 1);
    end

    function addLinePoints(tangentStart, tangentStop)
        % add points for a line segment from tangentStart to tangentStop
        linePoints = tangentStart(1, 1):sign(tangentStop(1, 1) - tangentStart(1, 1)) * lineResolution:tangentStop(1, 1);            
        scanPoints(currentPoint + (1:numel(linePoints)), 1) = linePoints;
        scanPoints(currentPoint + (1:numel(linePoints)), 2) = (tangentStop(2) - tangentStart(2)) / (tangentStop(1) - tangentStart(1)) * (linePoints - tangentStart(1,1)) + tangentStart(1, 2);
        beamOnPoints(currentPoint + (1:numel(linePoints))) = 0;
        currentPoint = currentPoint + numel(linePoints);
    end

    function [tangentStart tangentStop tangentT] = findTangent(sourceROI, destinationROI)
        % transform sourceROI into a reference frame with destinationROI at
        % the origin with .Orientation = 0
        if debugging
            tempROI2 = destinationROI;
            tempROI2.Orientation = tempROI2.Orientation - destinationROI.Orientation;
            tempROI2.Centroid = (tempROI2.Centroid - destinationROI.Centroid) * [cos(-destinationROI.Orientation) sin(-destinationROI.Orientation); -sin(-destinationROI.Orientation) cos(-destinationROI.Orientation)];
            [points slope] = pointsSlope(tempROI2);   
            figure('numbertitle', 'off', 'name', [num2str(find([ROI.handle] == sourceROI.handle)) ' to ' num2str(find([ROI.handle] == destinationROI.handle))]);
            plot(points(:,1), points(:,2))
            axis equal
            hold on;
        end
        tempROI = sourceROI;
        tempROI.Orientation = tempROI.Orientation - destinationROI.Orientation;
        tempROI.Centroid = (tempROI.Centroid - destinationROI.Centroid) * [cos(-destinationROI.Orientation) sin(-destinationROI.Orientation); -sin(-destinationROI.Orientation) cos(-destinationROI.Orientation)];
        tempROI.PointsPerRotation = 5000;
        [points slope] = pointsSlope(tempROI);
        t = 0:2 * pi /tempROI.PointsPerRotation:2 * pi - 2 * pi /tempROI.PointsPerRotation;                
        if debugging
            plot(points(:,1), points(:,2), 'color', 'red');
        end
        
        % determine the discriminant
        a = destinationROI.MinorAxisLength.^2 + destinationROI.MajorAxisLength.^2 .* slope.^2;
        b = 2 * destinationROI.MajorAxisLength.^2 .* slope .* (points(:,2) - slope .* points(:,1));
        c = destinationROI.MajorAxisLength.^2 .* (points(:,2) - slope .* points(:,1)).^2 - destinationROI.MajorAxisLength.^2 * destinationROI.MinorAxisLength.^2;
        discriminant = b.^2 - 4 .* a .* c;

        % find the place where the discriminant goes from zero to >= zero
        % this will automatically find the clockwise ones
        tangentLoc = find(discriminant(2:end) >= 0 & discriminant(1:end - 1) < 0, 2, 'first');
        if numel(tangentLoc) < 2
            error('ROI too close for current speeds.  Some ROI are inside of others in the scanner commands. Increase the dwell time on the ROI.')
        end
        if debugging
            xlims = get(gca, 'xlim');
            ylims = get(gca, 'ylim');
            line([points(tangentLoc(1), 1) - 500 points(tangentLoc(1), 1) + 500], [points(tangentLoc(1), 2) - 500 * slope(tangentLoc(1)) points(tangentLoc(1), 2) + 500 * slope(tangentLoc(1))], 'COLOR', 'black');
            line([points(tangentLoc(2), 1) - 500 points(tangentLoc(2), 1) + 500], [points(tangentLoc(2), 2) - 500 * slope(tangentLoc(2)) points(tangentLoc(2), 2) + 500 * slope(tangentLoc(2))], 'COLOR', 'green');        
        end
        
        % find the intersection of the line through the centeroids of the
        % two ellipses with the first tangent line
        intersectionX = (points(tangentLoc(1), 2) - slope(tangentLoc(1)) * points(tangentLoc(1), 1)) / (tempROI.Centroid(2) / tempROI.Centroid(1) - slope(tangentLoc(1)));
        if debugging
            line([tempROI.Centroid(1) tempROI2.Centroid(1)], [tempROI.Centroid(2) tempROI2.Centroid(2)], 'linestyle', ':', 'color', 'black');
            line(intersectionX, slope(tangentLoc(1)) * (intersectionX - points(tangentLoc(1), 1)) + points(tangentLoc(1), 2), 'marker', 'x', 'markersize', 20, 'color', 'red', 'lineStyle', 'none');
            set(gca, 'ylim', ylims, 'xlim', xlims);
            legend({'DestinationROI', 'SourceROI', 'Tangent 1', 'Tangent 2', 'Centroid line', 'Intersection'})
        end
        
        % determine whether this intersection is between the two centroids
        if intersectionX/tempROI.Centroid(1) > 0 && intersectionX/tempROI.Centroid(1) < 1
            % the intersection is between the centroids so use the other
            % tangent
            tangentLoc = tangentLoc(2);
        else
            tangentLoc = tangentLoc(1);
        end
        % keep theses points for later comparison
        tangentStart = [sourceROI.Centroid(1) + sourceROI.MajorAxisLength .* cos(sourceROI.Orientation) .* cos(t(tangentLoc)) - sourceROI.MinorAxisLength .* sin(sourceROI.Orientation) .* sin(t(tangentLoc)); sourceROI.Centroid(2) + sourceROI.MajorAxisLength .* sin(sourceROI.Orientation) .* cos(t(tangentLoc)) + sourceROI.MinorAxisLength .* cos(sourceROI.Orientation) .* sin(t(tangentLoc))]';
        % calculate the intersection of this line with the ellipse
        tangentStop = [-b(tangentLoc)/2/a(tangentLoc) slope(tangentLoc) * (-b(tangentLoc)/2/a(tangentLoc) - points(tangentLoc, 1)) + points(tangentLoc, 2)] * [cos(destinationROI.Orientation) sin(destinationROI.Orientation); -sin(destinationROI.Orientation) cos(destinationROI.Orientation)] + destinationROI.Centroid;
        tangentT = t(tangentLoc);        
    end

    function [points slope] = pointsSlope(roiData)
        % construct points and slopes in standard reference frame
%         roiData.PointsPerRotation = min([1000 10 * roiData.PointsPerRotation]);
        switch roiData.Shape
            case 1 % ellipse
                points = ellipseScan(roiData);
            case 4 % Lissajous
                points = lissajousScan(roiData);
            case 5 % spiral
                points = spiralScan(roiData);
            case 6 % line
                points = lineScan(roiData);                
        end        
        slope = (points(3:end,2)-points(1:end - 2,2)) ./ (points(3:end,1)-points(1:end -2,1));
        slope = slope([1 1:end end]);
%         points = [roiData.Centroid(1) + roiData.MajorAxisLength .* cos(roiData.Orientation) .* cos(t) - roiData.MinorAxisLength .* sin(roiData.Orientation) .* sin(t); roiData.Centroid(2) + roiData.MajorAxisLength .* sin(roiData.Orientation) .* cos(t) + roiData.MinorAxisLength .* cos(roiData.Orientation) .* sin(t)]';
%         slope = ((-roiData.MajorAxisLength .* sin(roiData.Orientation) .* sin(t) + roiData.MinorAxisLength .* cos(roiData.Orientation) .* cos(t)) ./ (-roiData.MajorAxisLength .* cos(roiData.Orientation) .* sin(t) - roiData.MinorAxisLength .* sin(roiData.Orientation) .* cos(t)))';
        if debugging
            figure, plot(points(:,1), points(:,2))
            hold on
            colors = lines(numel(slope)/5);
            for j = 1:5:numel(slope)
                line([points(j, 1) points(j, 1) + 2], [points(j, 2) points(j, 2) + 2 * slope(j)], 'color', colors(round(j/5 + .8),:));
            end
            set(gca, 'xlim', [min(points(:, 1)) - .2*range(points(:,1)) max(points(:, 1)) + .2*range(points(:,1))],...
                'ylim', [min(points(:, 2)) - .2*range(points(:,2)) max(points(:, 2)) + .2*range(points(:,2))]);
        end
    end        

    function startingT = tGivenX(tangentPoint, roiNum)
        % rerotate and translate
        tempROI = ROI(roiNum);
        tempROI.Orienation = 0;
        tempROI.Centroid = [0 0];
        % determine the t value at which whichROI is intersected
        tIntersect = acos((tangentPoint(1,1) - ROI(roiNum).Centroid(1))/ROI(roiNum).MajorAxisLength);
        switch ROI(roiNum).Shape
            case 1 % ellipse
                points = ellipseScan(ROI(roiNum), [-tIntersect tIntersect]);
            case 4 % Lissajous
                points = lissajousScan(ROI(roiNum), [-tIntersect tIntersect]);                
            case 5 % spiral
                points = spiralScan(ROI(roiNum), [-tIntersect tIntersect]);                
        end
%         if sum(([ROI(roiNum).MajorAxisLength * cos(tIntersect); ROI(roiNum).MinorAxisLength * cos(tIntersect)]' - tangentPoint) .^2) < sum(([ROI(roiNum).MajorAxisLength * cos(-tIntersect); ROI(roiNum).MinorAxisLength * cos(-tIntersect)]' - tangentPoint) .^2)
        if sum((points(1,:) - tangentPoint) .^ 2) > sum((points(end, :) - tangentPoint) .^ 2)
            % the intersection occurs at positive tIntersect
            startingT = tIntersect;
        else
            startingT = -tIntersect;
        end   
        startingT = startingT - ROI(roiNum).Orientation;
    end
end
% x = C1 + M*cos(theta)*cos(t) - m*sin(theta)*sin(t)
% y = C2 + M*sin(theta)*cos(t) + m*cos(theta)*sin(t)
% 
% dx/dt = -M*cos(theta)*sin(t) - m*sin(theta)*cos(t)
% dy/dt = -M*sin(theta)*sin(t) + m*cos(theta)*cos(t)
% 
% slope = dy/dx = (dy/dt) / (dx/dt)
%
% y - yo = m(x - xo)
%
% looking for intersection(s) of line that is a tangent from the current
% ellipse with the next ellipse.
% for each t on [7pi/4 15pi/4) with the given radial precision find the
% slope and point on the first ellipse.
% for each ellipse find where the discriminant of the intersection of this
% line with the second ellipse goes from negative to zero or positive (the
% clockwise tangent).  determine the value of x and y for the second cell
% at which this occurs and thus the length of the tangent.
% use the distance from the center and the tangent length to determine what
% ellipse to go to next.
% circle the new ellipse twice and repeat the above process.