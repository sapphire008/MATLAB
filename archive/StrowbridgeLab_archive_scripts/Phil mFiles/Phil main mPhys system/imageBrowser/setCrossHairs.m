function setCrossHairs(xCoord, yCoord)

if isappdata(0, 'referenceImage');
	axisHandle = findobj('tag', 'referenceImageAxis');
    figHandle = get(axisHandle, 'parent');
	kids = get(axisHandle, 'children');
    delete(kids(strcmp(get(kids, 'userData'), 'locationIndicator')));
	if isnan(xCoord)
		return % we have erased the location indicators so return
	end
    refInfo = getappdata(figHandle, 'info');    
    currentInfo = refInfo;
    currentInfo.origin = [xCoord yCoord 1];
        
    % get the calibration data for this setup
    if ispref('objectives', 'micronPerMit')
        objectiveDeltas = getpref('objectives', 'deltas');
        objectiveColors = getpref('objectives', 'colorBands');
        objectiveNames = getpref('objectives', 'nominalMagnification');        
        
        for i = 1:numel(objectiveDeltas)
            % transform to current reference image
            currentInfo.delta = [objectiveDeltas(i) objectiveDeltas(i) 1];
            currentInfo.Objective = objectiveNames{i};
            newCoords = transferPoints([1 1; 640 1; 640 480; 1 480; 1 1], currentInfo, refInfo);
            
            % draw  field of view
            line(newCoords(:,1), newCoords(:,2),...               
                'color', objectiveColors(i,:), 'parent', axisHandle,...
				'userData', 'locationIndicator');
        end
    else
        % draw crossHairs
        line([xCoord / refInfo.delta(1) xCoord / refInfo.delta(1)] + 320, get(findobj(figHandle, 'type', 'axes'), 'ylim'), 'color', [1 0 0], 'parent', axisHandle, 'userData', 'locationIndicator');
        line(get(findobj(figHandle, 'type', 'axes'), 'xlim'), [yCoord / refInfo.delta(2) yCoord / refInfo.delta(2)] + 240, 'color', [1 0 0], 'parent', axisHandle, 'userData', 'locationIndicator');
    end
    
end

% setpref('objectives', 'nominalMagnification', {'5x,.12 Zeiss', '40x,.80W Olympus',  '63x,.90W Zeiss'});
% setpref('objectives', 'deltas', [1.8797 .2568 .1515]);
% setpref('objectives', 'origins', [0 0; 97 201; 35.5 169]);
% setpref('objectives', 'colorBands', [1 0 0; 0 0 1; 0 1 0]);
% setpref('objectives', 'micronPerMit', [1.0908 1.0343]);
% 
% last good values
% setpref('objectives', 'deltas', [1.63 .23 .15]);
% setpref('objectives', 'origins', [-10 -10; 90 0; 30 -10]);


% setpref('objectives', 'nominalMagnification', {'Olympus 5x/0.1', 'Zeiss 5x/0.12', 'Zeiss 10x/0.25', 'Olympus 20x/0.5', 'Olympus 20x/0.75', 'Olympus 40x/0.8', 'Olympus 60x/0.9', 'Zeiss 63x/0.9', 'Olympus 100x/1.0'});
% setpref('objectives', 'deltas', [nan 1.8797 nan nan nan 0.2568 nan 0.1515 nan]);
% setpref('objectives', 'origins', [0 0; 0 0; 0 0; 0 0; 0 0; 0 0; 0 0; 0 0; 0 0;]);
% setpref('objectives', 'colorBands', [1 0 0; 1 0 0; 0 0 0; 0 1 0; 0 1 0; 0 0 .7; 0 0 1; 0 0 1; .2 .2 .2]);
% setpref('objectives', 'micronPerMit', [1.0908 1.0343]);

% 2PA 2.15.08
% setpref('objectives', 'nominalMagnification', {'5x,.12 Zeiss', 'Olympus 60x/0.9'});
% setpref('objectives', 'deltas', [165 13.8571]); % in um / V
% setpref('objectives', 'origins', [480.047 422.297; 40.3156 14.8531]); % in microns
% setpref('objectives', 'colorBands', [1 0 0; 0 0 1]);
% setpref('objectives', 'micronPerMit', [-27560 20943]); % mit is in inches, so we expect 25400

% empirical values 3.13.08
% setpref('objectives', 'origins', [0 0; -145 -10]); % in microns
% setpref('objectives', 'micronPerMit', [-27560 21300]);

% empricial values 9.12.08 on DIC1
% setpref('objectives', 'micronPerMit', [-25500 24000])
% setpref('objectives', 'nominalMagnification', {'5x,.12 Zeiss', 'Olympus 60x/0.9'});
% setpref('objectives', 'deltas', [165 13.8571]); % in um / V
% setpref('objectives', 'colorBands', [1 0 0; 0 0 1]);
% setpref('objectives', 'origins', [0 0; 55 -25]); % in microns