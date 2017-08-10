function transferROI
% places the ROI that we have onto the reference image

if isappdata(0, 'referenceImage')
    if ispref('objectives', 'micronPerMit')
        refImage = getappdata(0, 'referenceImage');
        refKid = get(refImage, 'children');
        refKid = refKid(2);

        refInfo = getappdata(refImage, 'info');

        currentInfo = getappdata(getappdata(0, 'imageBrowser'), 'info');

        % get the current ROI
        ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');

        %generate color scheme
        roiColors = colorspread(numel([ROI.segments]) + numel(ROI));

        t = 0:pi/20:2*pi;

        %http://www.alistairkeys.co.uk/rotation.shtml
        for x =1:numel(ROI)              
            ROI(x).Centroid = transferPoints(ROI(x).Centroid, currentInfo, refInfo);
            ROI(x).MajorAxisLength = ROI(x).MajorAxisLength * currentInfo.delta(1) / refInfo.delta(1);
            ROI(x).MinorAxisLength = ROI(x).MinorAxisLength * currentInfo.delta(1) / refInfo.delta(1);

			switch ROI(x).Shape			
				case 1 % ellipse
					line(ROI(x).Centroid(1) + ROI(x).MajorAxisLength * cos(t) * cos(ROI(x).Orientation) - ROI(x).MinorAxisLength * sin(t) * sin(ROI(x).Orientation), ROI(x).Centroid(2) + ROI(x).MajorAxisLength * cos(t) * sin(ROI(x).Orientation) + ROI(x).MinorAxisLength * sin(t) * cos(ROI(x).Orientation),...
						'LineWidth', 2,...
						'Color', roiColors(x,:),...
						'Parent', refKid);  
				case 2 % rectangle
					xy = [-ROI(x).MajorAxisLength -ROI(x).MinorAxisLength;...
						ROI(x).MajorAxisLength -ROI(x).MinorAxisLength;...
						ROI(x).MajorAxisLength ROI(x).MinorAxisLength;...
						-ROI(x).MajorAxisLength ROI(x).MinorAxisLength;...
						-ROI(x).MajorAxisLength -ROI(x).MinorAxisLength];		
					line(ROI(x).Centroid(1) + cos(ROI(x).Orientation) .* xy(:,1) - sin(ROI(x).Orientation) .* xy(:,2), ROI(x).Centroid(2) + sin(ROI(x).Orientation) .* xy(:,1) + cos(ROI(x).Orientation) .* xy(:,2),...
						'LineWidth', 2,...
						'Color', roiColors(x,:),...
						'Parent', refKid);					
				case 3 % wedge
					ROI(x).MinorAxisLength2 = ROI(x).MinorAxisLength2 * currentInfo.delta(1) / refInfo.delta(1);					
					xy = [2 * ROI(x).MajorAxisLength 0;...
						0 0;...
						0 ROI(x).MinorAxisLength;...
						2 * ROI(x).MajorAxisLength ROI(x).MinorAxisLength2];										
					line(ROI(x).Centroid(1) + cos(ROI(x).Orientation) .* xy(:,1) - sin(ROI(x).Orientation) .* xy(:,2), ROI(x).Centroid(2) + sin(ROI(x).Orientation) .* xy(:,1) + cos(ROI(x).Orientation) .* xy(:,2),...
						'LineWidth', 2,...
						'Color', roiColors(x,:),...
						'Parent', refKid);	
                case 4 % Lissajous
                    
                case 5 % Spiral
                    
			end
        end    
    else
        msgbox('Must first enter calibration data for objectives on this scope');
    end
else
    msgbox('No reference image currently set')
end