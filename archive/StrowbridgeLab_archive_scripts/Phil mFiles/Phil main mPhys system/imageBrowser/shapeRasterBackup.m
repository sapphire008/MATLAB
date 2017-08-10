function ROI = shapeRaster(ROI)
% (x,y) coordinates of points in a ROI = shapeRaster(ROI_data)

% Bresenham algorithm modified from
% http://groups.google.com/group/comp.graphics.algorithms/tree/browse_frm/month/2000-06?_done=%2Fgroup%2Fcomp.graphics.algorithms%2Fbrowse_frm%2Fmonth%2F2000-06%3F&
    info = getappdata(getappdata(0, 'imageBrowser'), 'info');
    
	for i = 1:numel(ROI)
		switch ROI(i).Shape
			case {1, 5} % ellipse				
				points = [];
				ROI(i).MajorAxisLength = abs(ROI(i).MajorAxisLength);
				ROI(i).MinorAxisLength = abs(ROI(i).MinorAxisLength);
				for Y = ROI(i).Centroid(2) - ROI(i).MajorAxisLength - ROI(i).MinorAxisLength:ROI(i).Centroid(2) + ROI(i).MajorAxisLength + ROI(i).MinorAxisLength
					for X = ROI(i).Centroid(1) - ROI(i).MinorAxisLength - ROI(i).MajorAxisLength:ROI(i).Centroid(1) + ROI(i).MinorAxisLength + ROI(i).MajorAxisLength
						xo = X - ROI(i).Centroid(1);
						yo = Y - ROI(i).Centroid(2);
						xn = xo * cos(-ROI(i).Orientation) - yo * sin(-ROI(i).Orientation);
						yn = xo * sin(-ROI(i).Orientation) + yo * cos(-ROI(i).Orientation);
						xn = xn / ROI(i).MajorAxisLength;
						yn = yn / ROI(i).MinorAxisLength;
						if (xn * xn + yn * yn <= 1) && X > 0 && X <= info.Width && Y > 0 && Y <= info.Height
							points = [points; X Y];
						end
					end
				end
				ROI(i).points = points;
			case {2, 4} % rectangle
				xo = repmat(-ROI(i).MajorAxisLength + 0.5:0.5:ROI(i).MajorAxisLength, 1, 4 * ROI.MinorAxisLength);
				yo = reshape(repmat(-ROI(i).MinorAxisLength + 0.5:0.5:ROI(i).MinorAxisLength, 4 * ROI.MajorAxisLength, 1), 1, []);
				ROI(i).points = round([ROI(i).Centroid(1) + cos(ROI(i).Orientation) .* xo - sin(ROI(i).Orientation) .* yo; ROI(i).Centroid(2) + sin(ROI(i).Orientation) .* xo + cos(ROI(i).Orientation) .* yo]');
				
				% deal with the image edges
				whichBad = ROI(i).points(:,1) > info.Width | ROI(i).points(:,1) < 1 | ROI(i).points(:,2) > info.Height | ROI(i).points(:,2) < 1;
				ROI(i).points(whichBad,:) = [];

				% deinterpolate
				ROI(i).points = unique(ROI(i).points, 'rows');				
			case 3 % wedge
				xo = [];
				yo = [];
				xStep = sign(ROI(i).MajorAxisLength) * 0.5;				
				
				% extend wedges to edge of frame?
				if strcmp(questdlg('Extend wedge to edge of frame?', 'Wedge', 'Yes', 'No', 'Yes'), 'Yes')
					ROI(i).ExtendToEdge = true;	
					xy(2,:) = [ROI(i).Centroid(1) ROI(i).Centroid(2)];					
					% determine xy(1,:)
					if ROI(i).MajorAxisLength > 0
						if ROI(i).Orientation > 0
							if sqrt((info.Width - ROI(i).Centroid(1)) ^ 2 + ((info.Width - ROI(i).Centroid(1)) * tan(ROI(i).Orientation)) ^ 2) < sqrt(((info.Height - ROI(i).Centroid(2)) * tan(pi/2 - ROI(i).Orientation)) ^ 2 + (info.Height - ROI(i).Centroid(2)) ^ 2)
								xy(1,:) = [info.Width ROI(i).Centroid(2) + (info.Width - ROI(i).Centroid(1)) * tan(ROI(i).Orientation)];
							else
								xy(1,:) = [ROI(i).Centroid(1) + (info.Height - ROI(i).Centroid(2)) * tan(pi/2 - ROI(i).Orientation) info.Height];
							end
						else
							if sqrt((info.Width - ROI(i).Centroid(1)) ^ 2 + ((info.Width - ROI(i).Centroid(1)) * tan(ROI(i).Orientation)) ^ 2) < sqrt((ROI(i).Centroid(2) * tan(pi/2 - ROI(i).Orientation)) ^ 2 + ROI(i).Centroid(2) ^ 2)
								xy(1,:) = [info.Width ROI(i).Centroid(2) + (info.Width - ROI(i).Centroid(1)) * tan(ROI(i).Orientation)];
							else
								xy(1,:) = [ROI(i).Centroid(1) - ROI(i).Centroid(2) * tan(pi/2 - ROI(i).Orientation) 1];
							end
						end
					else
						if ROI(i).Orientation > 0
							if sqrt(ROI(i).Centroid(1) ^ 2 + (ROI(i).Centroid(1) * -tan(ROI(i).Orientation)) ^ 2) < sqrt((ROI(i).Centroid(2) * -tan(pi/2 - ROI(i).Orientation)) ^ 2 + ROI(i).Centroid(2) ^ 2)
								xy(1,:) = [1 ROI(i).Centroid(2) + ROI(i).Centroid(1) * -tan(ROI(i).Orientation)];
							else
								xy(1,:) = [ROI(i).Centroid(1) + ROI(i).Centroid(2) * -tan(pi/2 - ROI(i).Orientation) 1];
							end
						else
							if sqrt(ROI(i).Centroid(1) ^ 2 + (ROI(i).Centroid(1) * -tan(ROI(i).Orientation)) ^ 2) < sqrt(((info.Height - ROI(i).Centroid(2)) * -tan(pi/2 - ROI(i).Orientation)) ^ 2 + (info.Height - ROI(i).Centroid(2)) ^ 2)
								xy(1,:) = [1 ROI(i).Centroid(2) + ROI(i).Centroid(1) * -tan(ROI(i).Orientation)];
							else
								xy(1,:) = [ROI(i).Centroid(1) - (info.Height - ROI(i).Centroid(2)) * -tan(pi/2 - ROI(i).Orientation) info.Height];
							end
						end
					end
					% determine xy(4,:)
					tau = atan((ROI(i).MinorAxisLength2 - ROI(i).MinorAxisLength) / abs(ROI(i).MajorAxisLength) / 2) - ROI(i).Orientation;
					xy(3,:) = [ROI(i).Centroid(1) - sin(ROI(i).Orientation) * ROI(i).MinorAxisLength ROI(i).Centroid(2) + cos(ROI(i).Orientation) * ROI(i).MinorAxisLength];
					if ROI(i).MajorAxisLength > 0
						if tau > 0
							if sqrt((info.Width - xy(3,1)) ^ 2 + ((info.Width - xy(3,1)) * tan(tau)) ^ 2) < sqrt(((info.Height - xy(3,2)) * tan(pi/2 - tau)) ^ 2 + (info.Height - xy(3,2)) ^ 2)
								xy(4,:) = [info.Width xy(3,2) - (info.Width - xy(3,1)) * tan(tau)];
                                disp('a')
							else
								xy(4,:) = [xy(3,1) + (info.Height - xy(3,2)) * tan(pi/2 - tau) info.Height];
                                disp('b')
							end
						else
							if sqrt((info.Width - xy(3,1)) ^ 2 + ((info.Width - xy(3,1)) * tan(tau)) ^ 2) < sqrt((xy(3,2) * tan(pi/2 - tau)) ^ 2 + xy(3,2) ^ 2)
								xy(4,:) = [info.Width xy(3,2) + (info.Width - xy(3,1)) * tan(tau)];
                                disp('c')
							else
								xy(4,:) = [xy(3,1) - xy(3,2) * tan(pi/2 - tau) 1];
                                disp('d')
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
					for xIndex = 0:xStep:sign(xStep) * 2 * max([sqrt((xy(1,1) - xy(2,1)) ^ 2 + (xy(1,2) - xy(2,2)) ^ 2) sqrt((xy(4,1) - xy(3,1)) ^ 2 + (xy(4,2) - xy(3,2)) ^ 2)]); 
						yo = [yo (0:(ROI(i).MinorAxisLength2 - ROI(i).MinorAxisLength) / ROI(i).MajorAxisLength * xIndex / 2 + ROI(i).MinorAxisLength)];
						xo = [xo xIndex .* ones(1, length(yo) - length(xo))];
					end					
					set(ROI(i).handle, 'xData', xy(:,1),...
						'ydata', xy(:,2));					
				else % don't extend to edge of frame
					for xIndex = 0:xStep:2 * ROI(i).MajorAxisLength
						yo = [yo (0:(ROI(i).MinorAxisLength2 - ROI(i).MinorAxisLength) / ROI(i).MajorAxisLength * xIndex / 2 + ROI(i).MinorAxisLength)];
						xo = [xo xIndex .* ones(1, length(yo) - length(xo))];
					end	
				end		
				% deal with the image edges
				ROI(i).points = round([ROI(i).Centroid(1) + cos(ROI(i).Orientation) .* xo - sin(ROI(i).Orientation) .* yo; ROI(i).Centroid(2) + sin(ROI(i).Orientation) .* xo + cos(ROI(i).Orientation) .* yo]');													
				whichBad = ROI(i).points(:,1) > info.Width | ROI(i).points(:,1) < 1 | ROI(i).points(:,2) > info.Height | ROI(i).points(:,2) < 1;
				ROI(i).points(whichBad,:) = [];

				% deinterpolate
				ROI(i).points = unique(ROI(i).points, 'rows');				
		end
% 		figure, plot(ROI(i).points(:,1), ROI(i).points(:,2), 'linestyle', 'none', 'marker', '.')						
% 		axis equal
	end	