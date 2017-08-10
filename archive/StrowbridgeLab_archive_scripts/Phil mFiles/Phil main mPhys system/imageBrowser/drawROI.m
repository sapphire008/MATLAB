function ROI = drawROI(whichROI)
% put ROI on their plot form
    ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
    
    if nargin < 1
        whichROI = 1:numel(ROI);
    end
    
    %generate color scheme
    roiColors = colorSpread(numel([ROI.segments]) + numel(ROI));
    if nargin < 1
        colorIndex = 1;
    else
        colorIndex = numel([ROI(1:whichROI - 1).segments]) + whichROI;
    end

    %clear old ROI
%     if sum(size(get(findobj('tag', 'roiPlot'), 'UserData'))) > 2
%         delete(get(findobj('tag', 'roiPlot'), 'UserData')');
%         set(findobj('tag', 'roiPlot'), 'UserData', findobj('tag', 'chkPlotType'));
%     end

    %http://www.alistairkeys.co.uk/rotation.shtml

    for x = whichROI
        % handle segmented ROI
        if ~isempty(ROI(x).segments)
            if numel(ROI(x).handle) > numel(ROI(x).segments) + 1
                delete(ROI(x).handle(numel(ROI(x).segments):end));
                ROI(x).handle(numel(ROI(x).segments):end) = [];
            end
            for handleIndex = numel(ROI(x).handle) + 1:numel(ROI(x).segments) + 1
                ROI(x).handle(handleIndex) = line('parent', get(getappdata(0, 'imageDisplay'), 'children'));
            end
        else
            delete(ROI(x).handle(2:end));
            ROI(x).handle(2:end) = [];
        end
		switch ROI(x).Shape
			case 1 % ellipse
                ellipseScan(ROI(x));     
			case 2 % rectangle
				xy = [-ROI(x).MajorAxisLength -ROI(x).MinorAxisLength;...
					ROI(x).MajorAxisLength -ROI(x).MinorAxisLength;...
					ROI(x).MajorAxisLength ROI(x).MinorAxisLength;...
					-ROI(x).MajorAxisLength ROI(x).MinorAxisLength;...
					-ROI(x).MajorAxisLength -ROI(x).MinorAxisLength];
				set(ROI(x).handle, 'xdata', ROI(x).Centroid(1) + cos(ROI(x).Orientation) .* xy(:,1) - sin(ROI(x).Orientation) .* xy(:,2),...
                    'ydata', ROI(x).Centroid(2) + sin(ROI(x).Orientation) .* xy(:,1) + cos(ROI(x).Orientation) .* xy(:,2));
			case 3 % wedge
				if ROI(x).ExtendToEdge
					xy(2,:) = [ROI(x).Centroid(1) ROI(x).Centroid(2)];					
					% determine xy(1,:)
					if ROI(x).MajorAxisLength > 0
						if ROI(x).Orientation > 0
							if sqrt((info.Width - ROI(x).Centroid(1)) ^ 2 + ((info.Width - ROI(x).Centroid(1)) * tan(ROI(x).Orientation)) ^ 2) < sqrt(((info.Height - ROI(x).Centroid(2)) * tan(pi/2 - ROI(x).Orientation)) ^ 2 + (info.Height - ROI(x).Centroid(2)) ^ 2)
								xy(1,:) = [info.Width ROI(x).Centroid(2) + (info.Width - ROI(x).Centroid(1)) * tan(ROI(x).Orientation)];
							else
								xy(1,:) = [ROI(x).Centroid(1) + (info.Height - ROI(x).Centroid(2)) * tan(pi/2 - ROI(x).Orientation) info.Height];
							end
						else
							if sqrt((info.Width - ROI(x).Centroid(1)) ^ 2 + ((info.Width - ROI(x).Centroid(1)) * tan(ROI(x).Orientation)) ^ 2) < sqrt((ROI(x).Centroid(2) * tan(pi/2 - ROI(x).Orientation)) ^ 2 + ROI(x).Centroid(2) ^ 2)
								xy(1,:) = [info.Width ROI(x).Centroid(2) + (info.Width - ROI(x).Centroid(1)) * tan(ROI(x).Orientation)];
							else
								xy(1,:) = [ROI(x).Centroid(1) - ROI(x).Centroid(2) * tan(pi/2 - ROI(x).Orientation) 1];
							end
						end
					else
						if ROI(x).Orientation > 0
							if sqrt(ROI(x).Centroid(1) ^ 2 + (ROI(x).Centroid(1) * -tan(ROI(x).Orientation)) ^ 2) < sqrt((ROI(x).Centroid(2) * -tan(pi/2 - ROI(x).Orientation)) ^ 2 + ROI(x).Centroid(2) ^ 2)
								xy(1,:) = [1 ROI(x).Centroid(2) + ROI(x).Centroid(1) * -tan(ROI(x).Orientation)];
							else
								xy(1,:) = [ROI(x).Centroid(1) + ROI(x).Centroid(2) * -tan(pi/2 - ROI(x).Orientation) 1];
							end
						else
							if sqrt(ROI(x).Centroid(1) ^ 2 + (ROI(x).Centroid(1) * -tan(ROI(x).Orientation)) ^ 2) < sqrt(((info.Height - ROI(x).Centroid(2)) * -tan(pi/2 - ROI(x).Orientation)) ^ 2 + (info.Height - ROI(x).Centroid(2)) ^ 2)
								xy(1,:) = [1 ROI(x).Centroid(2) + ROI(x).Centroid(1) * -tan(ROI(x).Orientation)];
							else
								xy(1,:) = [ROI(x).Centroid(1) - (info.Height - ROI(x).Centroid(2)) * -tan(pi/2 - ROI(x).Orientation) info.Height];
							end
						end
					end
					% determine xy(4,:)
					tau = atan((ROI(x).MinorAxisLength2 - ROI(x).MinorAxisLength) / abs(ROI(x).MajorAxisLength) / 2) - ROI(x).Orientation;
					xy(3,:) = [ROI(x).Centroid(1) - sin(ROI(x).Orientation) * ROI(x).MinorAxisLength ROI(x).Centroid(2) + cos(ROI(x).Orientation) * ROI(x).MinorAxisLength];
					if ROI(x).MajorAxisLength > 0
						if tau > 0
							if sqrt((info.Width - xy(3,1)) ^ 2 + ((info.Width - xy(3,1)) * tan(tau)) ^ 2) < sqrt(((info.Height - xy(3,2)) * tan(pi/2 - tau)) ^ 2 + (info.Height - xy(3,2)) ^ 2)
								xy(4,:) = [info.Width xy(3,2) + (info.Width - xy(3,1)) * tan(tau)];
							else
								xy(4,:) = [xy(3,1) + (info.Height - xy(3,2)) * tan(pi/2 - tau) info.Height];
							end
						else
							if sqrt((info.Width - xy(3,1)) ^ 2 + ((info.Width - xy(3,1)) * tan(tau)) ^ 2) < sqrt((xy(3,2) * tan(pi/2 - tau)) ^ 2 + xy(3,2) ^ 2)
								xy(4,:) = [info.Width xy(3,2) + (info.Width - xy(3,1)) * tan(tau)];
							else
								xy(4,:) = [xy(3,1) - xy(3,2) * tan(pi/2 - tau) 1];
							end
						end
					else
						if tau > 0
							if sqrt(xy(3,1) ^ 2 + (xy(3,1) * tan(tau)) ^ 2) < sqrt((xy(3,2) * -tan(pi/2 - tau)) ^ 2 + xy(3,2) ^ 2)
								xy(4,:) = [1 xy(3,2) + xy(3,1) * tan(tau)];
							else
								xy(4,:) = [xy(3,1) + xy(3,2) * -tan(pi/2 - tau) info.Height];
							end
						else
							if sqrt(xy(3,1) ^ 2 + (xy(3,1) * -tan(tau)) ^ 2) < sqrt(((info.Height - xy(3,2)) * -tan(pi/2 - tau)) ^ 2 + (info.Height - xy(3,2)) ^ 2)
								xy(4,:) = [1 xy(3,2) - xy(3,1) * -tan(tau)];
							else
								xy(4,:) = [xy(3,1) - (info.Height - xy(3,2)) * -tan(pi/2 - tau) 1];
							end
						end
					end					
				else
					xy = [2 * ROI(x).MajorAxisLength 0;...
						0 0;...
						0 ROI(x).MinorAxisLength;...
						2 * ROI(x).MajorAxisLength ROI(x).MinorAxisLength2];					
				end
				set(ROI(x).handle, 'xdata', max([ones(size(xy, 1), 1) min([repmat(info.Width, size(xy, 1), 1) ROI(x).Centroid(1) + cos(ROI(x).Orientation) .* xy(:,1) - sin(ROI(x).Orientation) .* xy(:,2)], [], 2)], [], 2),...
                    'ydata', max([ones(size(xy, 1), 1) min([repmat(info.Height, size(xy, 1), 1) ROI(x).Centroid(2) + sin(ROI(x).Orientation) .* xy(:,1) + cos(ROI(x).Orientation) .* xy(:,2)], [], 2)], [], 2));				
            case 4 % Lissajous
                lissajousScan(ROI(x));
            case 5 % Spiral
                spiralScan(ROI(x));     
            case 6 % Line
                scanPoints = repmat(ROI(x).Centroid, ROI(x).PointsPerRotation, 1) + [(-ROI(x).MajorAxisLength:2 * ROI(x).MajorAxisLength / (ROI(x).PointsPerRotation - 1):ROI(x).MajorAxisLength)'...
                    zeros(ROI(x).PointsPerRotation, 1)] * [cos(-ROI(x).Orientation) -sin(-ROI(x).Orientation); sin(-ROI(x).Orientation) cos(-ROI(x).Orientation)];
                set(ROI(x).handle, 'xdata', scanPoints(:,1), 'yData', scanPoints(:,2));            
                
                if isempty(ROI(x).segments)
                    set(ROI(x).handle, 'xData', scanPoints(:,1), 'yData', scanPoints(:,2));
                else
                    ROI(x).segments = [1/ROI(x).PointsPerRotation ROI(x).segments 1];
                    for segIndex = 1:numel(ROI(x).segments) - 1
                        whichPoints = ROI(x).segments(segIndex) * ROI(x).PointsPerRotation:ROI(x).segments(segIndex + 1) * ROI(x).PointsPerRotation;
                        set(ROI(x).handle(segIndex), 'xData', scanPoints(whichPoints, 1), 'yData', scanPoints(whichPoints, 2));
                    end
                end                
		end
		
		% mark the roi by its type
        switch ROI(x).Type
			case 1 % Integrative
				set(ROI(x).handle, 'color', roiColors(colorIndex,:), 'linestyle', '-', 'marker', 'none', 'markerSize', 8);
			case 2 % Clearing
				set(ROI(x).handle, 'color', roiColors(colorIndex,:), 'linestyle', ':', 'marker', 'none', 'markerSize', 8);
			case 3 % Power Down
				set(ROI(x).handle, 'color', roiColors(colorIndex,:), 'linestyle', '-', 'marker', 'none', 'markerSize', 8);
			case 4 % Photometry
                if isempty(ROI(x).segments)
    				set(ROI(x).handle, 'color', roiColors(colorIndex,:), 'linestyle', 'none', 'marker', '.', 'markerSize', 8);
                    if numel(whichROI) == 1
                        set(ROI(x).handle, 'markersize', 18);
                    end                    
                else
                    for segHandle = ROI(x).handle
                        set(segHandle, 'color', roiColors(colorIndex,:), 'linestyle', 'none', 'marker', '.', 'visible', 'on', 'markerSize', 8);
                        colorIndex = colorIndex + 1;
                    end
                    colorIndex = colorIndex - 1;
                end
        end		
        colorIndex = colorIndex + 1;
    end
    
    if nargin < 1
        setappdata(getappdata(0, 'imageDisplay'), 'ROI', ROI);
        ROI = [];
    end