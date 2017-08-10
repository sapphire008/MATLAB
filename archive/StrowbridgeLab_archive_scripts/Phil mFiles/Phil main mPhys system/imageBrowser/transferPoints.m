function outCoords = transferPoints(inCoords, fromInfo, toInfo)
% transfer points from one objective to another

    if ispref('objectives', 'micronPerMit')
        objectiveNames = getpref('objectives', 'nominalMagnification');
        objectiveDeltas = getpref('objectives', 'deltas');
        objectiveOrigins = getpref('objectives', 'origins');

        % figure out the index of the objectives we are using
        toObjective = find(strcmp(objectiveNames, toInfo.Objective));
        fromObjective = find(strcmp(objectiveNames, fromInfo.Objective));
        if  ~isempty(toObjective) && ~isempty(fromObjective)
            theta = 0;
            if isfield(toInfo, 'SourceProcessing')
                resultData = sscanf(toInfo.SourceProcessing, 'Zoom = %g Rotation = %g');
                toInfo.delta = objectiveDeltas(toObjective) * resultData(1);
                toInfo.volts = sscanf(toInfo.SizeOnSource, 'Size = %g by %g mV');                
                theta = resultData(2) / 180 * pi;
            else
                toInfo.volts = [7; 5.25];
            end
            
            if isfield(fromInfo, 'SourceProcessing')
                resultData = sscanf(fromInfo.SourceProcessing, 'Zoom = %g Rotation = %g');
                fromInfo.delta = objectiveDeltas(fromObjective) * resultData(1);
                fromInfo.volts = sscanf(fromInfo.SizeOnSource, 'Size = %g by %g mV');                                
                theta = theta - resultData(2) / 180 * pi;
            else
                fromInfo.volts = [7; 5.25];
            end            
            
            numCoords = size(inCoords, 1);
            %             [              pixels from center                                         ] * [         (um / V)           *        V        /               pixels                          ] + [            um the microscope has moved         ] + [                       difference of objective centers                                 ] 
%             tempCoords = ((inCoords - repmat([fromInfo.Width / 2 fromInfo.Height / 2], numCoords, 1)).* repmat(fromInfo.delta([1 1]) .* fromInfo.volts' ./ [fromInfo.Width fromInfo.Height], numCoords, 1) - repmat((toInfo.origin([2 1]) - fromInfo.origin([2 1])) + objectiveOrigins(toObjective, 1:2) - objectiveOrigins(fromObjective, 1:2), numCoords, 1)) ./ repmat(toInfo.delta([1 1]) .* toInfo.volts' ./ [toInfo.Width toInfo.Height], numCoords, 1); % in pixels
            tempCoords = ((inCoords - repmat([fromInfo.Width / 2 fromInfo.Height / 2], numCoords, 1)).* repmat(fromInfo.delta([1 1]) .* fromInfo.volts' ./ [fromInfo.Width fromInfo.Height], numCoords, 1) - repmat((toInfo.origin([1 2]) - fromInfo.origin([1 2])) + objectiveOrigins(toObjective, 1:2) - objectiveOrigins(fromObjective, 1:2), numCoords, 1)) ./ repmat(toInfo.delta([1 1]) .* toInfo.volts' ./ [toInfo.Width toInfo.Height], numCoords, 1); % in pixels            
            outCoords = [cos(theta) * tempCoords(:,1) - sin(theta) * tempCoords(:,2) sin(theta) * tempCoords(:,1) + cos(theta) * tempCoords(:,2)]  + repmat([toInfo.Width / 2 toInfo.Height / 2], numCoords, 1); % rotate and transfer back to bottom-left based coordinates
        else
            msgbox('No calibration data available for objectives');
        end
    else
        msgbox('Must first enter calibration data for objectives on this scope');
    end    
    
%             %            [              pixels from center                                        ] * [         um / pixel                    ] +        [                      um the microscope has moved                     ] + [                       difference of objective centers                  ]                 / [              um / pixel             ] + [change from center-based to bottom-right coordinates   ]                                   
%             outCoords = ((inCoords - repmat([fromInfo.Width / 2 fromInfo.Height / 2], numCoords, 1)).* repmat(fromInfo.delta(1:2), numCoords, 1) + repmat((toInfo.origin(1:2) - fromInfo.origin(1:2)) .* 1000 .* micronPerMit(1:2) + objectiveOrigins(fromObjective, 1:2) - objectiveOrigins(toObjective, 1:2), numCoords, 1)) ./ repmat(toInfo.delta(1:2), numCoords, 1) + repmat([toInfo.XSize / 2 toInfo.YSize / 2], numCoords, 1);