function doSingle
% called by the experiment Single button to record a single episode

% prepares stimuli from the protocol gui to generate episodes and then
% calls generateStim the required number of times

persistent abortRequest
persistent onTimes
persistent offTimes
persistent galvoHandle

    protocolData = getappdata(0, 'currentProtocol');
    experimentData = getappdata(0, 'currentExperiment');
	experimentHandles = guihandles(getappdata(0, 'experiment'));
	checkAcquisitionRate;
    
% if the button string is 'Abort' then stop a multi-episode single
if strcmp(get(gcbo, 'tag'), 'cmdSingle') && (strcmp(get(experimentHandles.cmdSingle, 'string'), 'Abort') || strcmp(get(experimentHandles.cmdSingle, 'string'), 'Abort Set'))
    if strcmp(get(experimentHandles.cmdSingle, 'string'), 'Abort')
        stop(timerfind('name', 'experimentClock'));
        feval(get(timerfind('name', 'experimentClock'), 'TimerFcn'), '-abortEpisode');
        clear(get(timerfind('name', 'experimentClock'), 'TimerFcn'), 'reducedNeurons');
		experimentData.nextEpisode = get(experimentHandles.nextEpisode, 'string');
		set(experimentHandles.nextEpisode, 'string', [experimentData.nextEpisode(1:find(experimentData.nextEpisode == 'E', 1, 'last')) num2str(str2double(experimentData.nextEpisode(find(experimentData.nextEpisode == 'E', 1, 'last') + 1:end)) - 1)])
        start(timerfind('name', 'experimentClock'));
    end
    if strcmp(get(experimentHandles.cmdSingle, 'string'), 'Abort Set')
        % need to reset the protocol to what it was
        
        
    end
    if ~isempty(timerfind('name', 'repeatTimer'))
		stop(timerfind('name', 'repeatTimer'));
		delete(timerfind('name', 'repeatTimer'));
		set(experimentHandles.cmdRepeat, 'string', 'Repeat');
    end

    set(experimentHandles.cmdSingle, 'string', 'Single');
    set(experimentHandles.progressBar, 'position', [0 0 .0001 .02], 'visible', 'on');
    abortRequest = 1;	
	return;
end

% determine whether any of the fields need to be iterated
    fields = fieldnames(protocolData);
    whichFields = [];
    whichInstances = [];
    fieldData = {};
    numEpisodes = [];

    protocolData.ttlEnable = experimentData.ttlEnable;
    for fieldIndex = 1:numel(fields)
        if iscell(protocolData.(fields{fieldIndex})) && ischar(protocolData.(fields{fieldIndex}){1}) && ~ismember(fields{fieldIndex}, {'ttlArbitrary', 'ampMatlabCommand', 'ampMatlabStim','ampTypeName', 'ampCellLocationName', 'ttlTypeName', 'sourceName','imageDuration', 'scanWhichRoi'})
            for instanceIndex = 1:numel(protocolData.(fields{fieldIndex}))
                tempValue = eval(protocolData.(fields{fieldIndex}){instanceIndex});
                secondCap = find(fields{fieldIndex} < 97, 2, 'first');                
                if numel(tempValue) > 1 && numel(secondCap) == 2 &&...
                        protocolData.([fields{fieldIndex}(1:secondCap(2) - 1) 'Enable']){instanceIndex} &&...
                        ((strcmp(fields{fieldIndex}(1:secondCap(1) - 1), 'amp') && protocolData.ampStimEnable{instanceIndex}) || protocolData.([fields{fieldIndex}(1:secondCap(1) - 1) 'Enable']){instanceIndex}) &&...
                        (~strcmp(fields{fieldIndex}(1:secondCap(2) - 1), 'ttlBurst') || protocolData.ttlTrainEnable{instanceIndex})
                    whichFields(end + 1) = fieldIndex;
					if strcmp(fields{fieldIndex}(1:secondCap(1) - 1), 'ttl')
						whichInstances(end + 1) = -instanceIndex;
					else
						whichInstances(end + 1) = instanceIndex;
					end
                    fieldData{end + 1} = tempValue;
                    numEpisodes(end + 1) = numel(tempValue);
                else
                    protocolData.(fields{fieldIndex}){instanceIndex} = tempValue; %str2double(protocolData.(fields{fieldIndex}){instanceIndex});
                end
            end
        end
    end

% warn user in case they are confused
	if numEpisodes > 1
		if protocolData.ampsCorandomize{1}
			numNeeded = prod(numEpisodes);
		else
			whatInstances = unique(whichInstances);
			numNeeded = prod(numEpisodes(whichInstances == whatInstances(1)));
			for i = whatInstances(2:end)
				if numNeeded ~= prod(numEpisodes(whichInstances == whatInstances(i)))
					if strcmp(questdlg('The amps/ttls are not all generating the same number of episodes.  Therefore they cannot be randomized at the same time.  Would you like to randomize them amongst each other?', 'Whoops', 'Yes', 'Cancel', 'Cancel'), 'Yes')
						protocolData.ampCorandomize{1} = 1;
						numNeeded = prod(numEpisodes);
						set(findobj('tag', 'ampsCorandomize'), 'value', 1);
						saveprotocol;
					end
				end
			end
		end
        switch questdlg(['Your protocol will require ' num2str(numNeeded) ' episodes.'], 'Run check', 'Do it', 'Show me', 'Cancel', 'Do it')
            case 'Do it'                 
                % iterate through any necessary variables
				fieldIndices = zeros(numNeeded, size(fieldData, 2));
				
				if protocolData.ampsCorandomize{1}
					% make all possible combinations
					for i = 1:numel(numEpisodes)
						singleStep = reshape(repmat(1:numEpisodes(i), numNeeded / prod(numEpisodes(1:i)), 1), [], 1);
						fieldIndices(:,i) = repmat(singleStep, numNeeded / size(singleStep, 1), 1);
					end
					[randOrder randOrder] = sort(rand(size(fieldIndices, 1), 1));
					fieldIndices = fieldIndices(randOrder, :);
				else
					% make all intra-amp combinations
					for ampIndex = whatInstances
						bigProd = 1;
						for i = find(whichInstances == ampIndex)
							bigProd = bigProd * numEpisodes(i);
							singleStep = reshape(repmat(1:numEpisodes(i), numNeeded / bigProd, 1), [], 1);
							fieldIndices(:,i) = repmat(singleStep, numNeeded / size(singleStep, 1), 1);
						end
						if ampIndex > 0
							if protocolData.ampRandomizeFamilies{ampIndex}
								[randOrder randOrder] = sort(rand(size(fieldIndices, 1), 1));
								fieldIndices(:, whichInstances == ampIndex) = fieldIndices(randOrder, whichInstances == ampIndex);	
							end
						else
							% ttl lines are always randomized
								[randOrder randOrder] = sort(rand(size(fieldIndices, 1), 1));
								fieldIndices(:, whichInstances == ampIndex) = fieldIndices(randOrder, whichInstances == ampIndex);								
						end
					end				
				end
				
				set(experimentHandles.cmdSingle, 'string', 'Abort Set');
				abortRequest = 0;
                for episodeIndex = 1:numNeeded
                    tempProtocol = protocolData;
                    for i = 1:numel(numEpisodes)
                        tempProtocol.(fields{whichFields(i)}){abs(whichInstances(i))} = fieldData{i}(fieldIndices(episodeIndex, i));
                    end
                    doEpisode(tempProtocol);
					if episodeIndex < numNeeded
						waitfor(experimentHandles.cmdSingle, 'string');
                        set(experimentHandles.episodeLabel, 'string', ['Set: ' sprintf('%0.0f', episodeIndex) ' / ' sprintf('%0.0f', numNeeded) ' complete, Next:']);                        
						if abortRequest
                            break
						end                        
						set(experimentHandles.cmdSingle, 'string', 'Abort Set');
						pause(experimentData.repeatInterval - tempProtocol.sweepWindow / 1000 - .5);
						if abortRequest
                            break
						end
					end
                end   
                if ~abortRequest
                    waitfor(experimentHandles.cmdSingle, 'string');
                end
                set(experimentHandles.episodeLabel, 'string', 'Next Episode:');
                saveProtocol;
            case 'Show me'
                % create an output space
					set(experimentHandles.cmdSingle, 'string', 'Abort Set');				
                    ttlNums = find(cell2mat(experimentData.ttlEnable));
					if isfield(experimentData, 'ampEnable')
                        ampNums = find(cell2mat(experimentData.ampEnable));
                    else
                        ampNums = [];
					end
					if numel(ttlNums) + numel(ampNums) == 0
						error('No stimuli are being generated')
					end
                    xData = (protocolData.timePerPoint / 1000:protocolData.timePerPoint / 1000:protocolData.sweepWindow)'; % + 3 * protocolData.timePerPoint / 1000)';
                    for dataIndex = 1:numel(ttlNums) + numel(ampNums)
                        emptyData{dataIndex} = nan(size(xData));
                    end
                    handles = newScope(emptyData, xData);
                    chanNames = {};

                    if numel(ttlNums)
                        for i = ttlNums
                            chanNames{end + 1} = ['TTL ' num2str(4-i)];
                        end
                    end
                    if numel(ampNums)
                        for i = ampNums'
                            chanNames{end + 1} = ['Amp ' char(64 + i)];
                        end   
                    end
                    for index = 1:numel(chanNames)
                        set(handles.channelControl(index).channel, 'String', chanNames);
                    end
                
					fieldIndices = zeros(numNeeded, size(fieldData, 2));

					if protocolData.ampsCorandomize{1}
						% make all possible combinations
						for i = 1:numel(numEpisodes)
							singleStep = reshape(repmat(1:numEpisodes(i), numNeeded / prod(numEpisodes(1:i)), 1), [], 1);
							fieldIndices(:,i) = repmat(singleStep, numNeeded / size(singleStep, 1), 1);
						end
						[randOrder randOrder] = sort(rand(size(fieldIndices, 1), 1));
						fieldIndices = fieldIndices(randOrder, :);
					else
						% make all intra-amp combinations
						for ampIndex = whatInstances
							bigProd = 1;
							for i = find(whichInstances == ampIndex)
								bigProd = bigProd * numEpisodes(i);
								singleStep = reshape(repmat(1:numEpisodes(i), numNeeded / bigProd, 1), [], 1);
								fieldIndices(:,i) = repmat(singleStep, numNeeded / size(singleStep, 1), 1);
							end
							if ampIndex > 0
								if protocolData.ampRandomizeFamilies{ampIndex}
									[randOrder randOrder] = sort(rand(size(fieldIndices, 1), 1));
									fieldIndices(:, whichInstances == ampIndex) = fieldIndices(randOrder, whichInstances == ampIndex);	
								end
							else
								% ttl lines are always randomized
									[randOrder randOrder] = sort(rand(size(fieldIndices, 1), 1));
									fieldIndices(:, whichInstances == ampIndex) = fieldIndices(randOrder, whichInstances == ampIndex);								
							end
						end				
					end
                
				% guess at min and max y values
					set(handles.axes(end - numel(ttlNums) + 1:end), 'ylim', [-.05, 1.05]);
					noBoundsSet = ones(numel(ampNums), 1);
                    for i = 1:numel(ampNums)
						% find field tags with 'Amplitude', or 'Peak' at
						% their end and use the min and max values for
						% limits
						if any(~cellfun('isempty', strfind(fields(whichFields(whichInstances == i)), 'Amplitude')) | ~cellfun('isempty', strfind(fields(whichFields(whichInstances == i)), 'Peak')))
							% the min and max values will vary
							maxValue = 0;
							minValue = 0;
							whichAmplitudes = find((~cellfun('isempty', strfind(fields(whichFields), 'Amplitude')) | ~cellfun('isempty', strfind(fields(whichFields), 'Peak')))' & whichInstances == i);
							for j = whichAmplitudes
								maxValue = maxValue + max(fieldData{j});
								minValue = minValue + min(fieldData{j});
							end
							if maxValue ~= minValue
								set(handles.axes(i), 'ylim', [minValue - .05 * (maxValue - minValue) maxValue + .05 * (maxValue - minValue)]);
								noBoundsSet(i) = 0;
							end
						end
                    end
                    
				abortRequest = 0;	
                for episodeIndex = 1:numNeeded
                    tempProtocol = protocolData;
                    for i = 1:numel(numEpisodes)
                        tempProtocol.(fields{whichFields(i)}){abs(whichInstances(i))} = fieldData{i}(fieldIndices(episodeIndex, i));
                    end
                    [digStim analogStim] = generateStim(tempProtocol, experimentData);
                    for i = 1:size(digStim, 2)
                        line(xData, digStim(:,i), 'parent', handles.axes(end - size(digStim, 2) + i), 'color', 'red');
                    end
					for i = 1:size(analogStim, 2)
                        line(xData, analogStim(:,i), 'parent', handles.axes(i));
						if episodeIndex == 1 && noBoundsSet(i)
							newScale(handles.channelControl(i).scaleType)  					
						end						
					end
					drawnow
                    set(experimentHandles.episodeLabel, 'string', ['Set: ' sprintf('%0.0f', episodeIndex) ' / ' sprintf('%0.0f', numNeeded) ' complete, Next:']);                    
                    if abortRequest
                        break
                    end                    
					pause(.25)
					if abortRequest
                        break
					end
                end 
                
                set(experimentHandles.episodeLabel, 'string', 'Next Episode:');
                set(experimentHandles.cmdSingle, 'string', 'Single');
                saveProtocol;                
            otherwise
                % cancel was pressed or the window was closed
        end
	else % numEpisodes <= 1
        doEpisode(protocolData);
	end

	function doEpisode(protocol)
        if protocolData.takeImages{1}
            wasVisible = get(getappdata(0, 'photometryPath'), 'visible');
            set(getappdata(0, 'photometryPath'), 'visible', 'off');
            pixelUs = str2double(get(findobj('tag', 'txtPixelUs'), 'string'));  
            ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');            
            % determine which ROI will be scanned
            switch get(get(findobj('tag', 'imageScan'), 'selectedObject'), 'tag')
                case 'scanAllRoi'
                    [scanPoints beamOnPoints scanOrder] = sequenceScan;
                case 'scanCurrentRoi'
                    [scanPoints beamOnPoints scanOrder] = sequenceScan(get(findobj('tag', 'cboRoiNumber'), 'value'));
                    ROI = ROI(get(findobj('tag', 'cboRoiNumber'), 'value'));
                case 'scanSpecifiedRoi'
                    [scanPoints beamOnPoints scanOrder] = sequenceScan(str2num(protocolData.scanWhichRoi{1}));
                    ROI = ROI(str2num(protocolData.scanWhichRoi{1}));
            end
            
            % create a data set of location vs time in cycle
            numPoints = size(scanPoints, 1);
            galvoLocations = takeTwoPhotonNI([], repmat(scanPoints, 5, 1), [], pixelUs, 1);  
            info = getappdata(getappdata(0, 'imageBrowser'), 'info');
            voltSize = sscanf(info.SizeOnSource, 'Size = %g by %g mV'); 
            centerLoc = sscanf(info.Comment, 'Center = %g x %g mV');            
            galvoLocations = [(galvoLocations.photometry(numPoints * 3 + 1:numPoints * 4,1) - centerLoc(1)) ./ voltSize(1) .* info.Width + info.Width / 2 ...
                    (galvoLocations.photometry(numPoints * 3 + 1:numPoints * 4,2) - centerLoc(2)) ./ voltSize(2) .* info.Height + info.Height / 2];            
            if isempty(galvoHandle) || ~ishandle(galvoHandle)
                galvoHandle = line(0, 0,...
                    'lineWidth', 2,...
                    'color', [0 0 1],...
                    'parent', findobj('tag', 'imageAxis'));
            end
            set(galvoHandle, 'xData', galvoLocations(:, 1), 'yData', galvoLocations(:,2));
            if numPoints * pixelUs > 1000
                set(getappdata(0, 'imageBrowser'), 'name', [sprintf('%1.2f', numPoints * pixelUs / 1000) ' ms per circuit']);
            else
                set(getappdata(0, 'imageBrowser'), 'name', [sprintf('%1.1f', numPoints * pixelUs) ' ' char(181) 's per circuit']);
            end            
                
            if ischar(protocolData.imageDuration)
                protocolData.imageDuration = str2double(protocolData.imageDuration);
            end
            % build the scan to equal the scan duration
            if size(scanPoints, 1) < protocolData.imageDuration * 1000 / pixelUs
                scanPoints = repmat(scanPoints, fix(protocolData.imageDuration * 1000 / pixelUs / size(scanPoints, 1)), 1);
            end
            
            takeTwoPhotonNI([], scanPoints, [], pixelUs, 0, 1);    
        end        
		[digStim analogStim] = generateStim(protocol, experimentData);
        if numel(digStim) || numel(analogStim) || numel(cellfun(@(x) x>1, protocol.channelType))
			handles = get(getappdata(0, 'experiment'), 'userData');
			set(handles.cmdStream, 'string', 'Stop')
            if strcmp(get(handles.cmdSingle, 'string'), 'Abort')
                warning('Episode already in progress')
                % without this, if the post episode stuff takes longer than
                % the time until the next repeat then the TTLs spasm
                return
            end
			set(handles.cmdSingle, 'string', 'Abort');
			set(handles.cmdExtend, 'visible', 'on');
			stop(timerfind('name', 'experimentClock'));
			saveExperiment;
			setappdata(0, 'currentProtocol', protocol);
            feval(get(timerfind('name', 'experimentClock'), 'TimerFcn'), digStim, analogStim);
			experimentData.nextEpisode = get(handles.nextEpisode, 'string');
			set(handles.nextEpisode, 'string', [experimentData.nextEpisode(1:find(experimentData.nextEpisode == 'E', 1, 'last')) num2str(str2double(experimentData.nextEpisode(find(experimentData.nextEpisode == 'E', 1, 'last') + 1:end)) + 1)]);
			set(handles.episodeTime, 'userData', clock);
            pause(0.1); % to let the  buffer accrue data
			start(timerfind('name', 'experimentClock'));	
        end	
        if protocolData.takeImages{1}
            % process the returned data
            waitfor(experimentHandles.cmdSingle, 'string');
            pause(0.1);
            % read the data
            zImage = getappdata(getappdata(0, 'rasterScan'), 'zImage');
            photometry = zImage.photometry;
            photometryHeader = zImage.info;

            fileName = [get(experimentHandles.mnuSetDataFolder, 'userData') filesep experimentData.cellName '.' datestr(clock, 'ddmmmyy') '.' experimentData.nextEpisode '.mat'];
            if mod(size(photometry, 1), numPoints)
                photometry(numPoints * fix(size(photometry, 1) / numPoints) + (1:numPoints), 1) = photometry(numPoints * (fix(size(photometry, 1) / numPoints) - 1) + (1:numPoints), 1);
            end
            imageData = reshape(photometry(:,1), numPoints, [])';            

            percentSat = sum(sum(imageData > 2045));
            if percentSat > 0.02 * numel(imageData)
                msgbox(['Pixel saturation is ' num2str(percentSat / numel(imageData) * 100)]);
            end
            % use the scanOrder and beamOnPoints to deconvolve the data
            % into the individual ROI
            if isempty(onTimes)
                onTimes = find(beamOnPoints(2:end) & ~beamOnPoints(1:end - 1));
                if beamOnPoints(1)
                    onTimes = [1; onTimes];
                end
                offTimes = find(~beamOnPoints(2:end) & beamOnPoints(1:end - 1));
                if beamOnPoints(end)
                    offTimes = [offTimes; size(imageData, 2)];
                end
            end
            photometry = nan(size(imageData, 1), numel(ROI));
            roiDelay = nan(numel(ROI), 1);
            
            % generate a line scan type of figure
            colorData = get(getappdata(0, 'imageDisplay'), 'colormap');
            roiColors = [0 0 0; colorSpread(numel([ROI.segments]) + numel(ROI))];    
            colorIndex = 1;
            figHandle = getappdata(0, 'photometryPath');
            delete(get(figHandle, 'children'));
            set(0, 'currentFigure', figHandle);
            tempHandle = subplot(5, 1, 1:4);    
            if ROI(1).Shape == 6
                % this is a line scan so only plot the data in one direction
                imagesc(imageData(:, 1:end / 2));
            else
                imagesc(imageData);
            end
            ylabel('Time (ms)');
            pixelRange = range(get(gca, 'ylim'));
            set(gca, 'ydir', 'reverse', 'ytick', [0 .2 .4 .6 .8 1] .* pixelRange, 'yticklabel', round([0 .2 .4 .6 .8 1] .* pixelRange .* numPoints .* pixelUs ./ 1000));
            ylims = get(gca, 'ylim');
            for timeIndex = 1:numel(onTimes)
                % start lines
                h{timeIndex, 1} = imline(gca,[onTimes(timeIndex) onTimes(timeIndex)], ylims);
                h{timeIndex, 1}.setPositionConstraintFcn({@dragStartLine, timeIndex});    
                h{timeIndex, 1}.setColor(roiColors(colorIndex,:));
%                 api(timeIndex, 1).addNewPositionCallback({@resavePhotometry}); 

                % segment boundary lines
                for segIndex = 1:numel(ROI(scanOrder(timeIndex)).segments)
                    colorIndex = colorIndex + 1;
                    sh(timeIndex, segIndex) = line('color', roiColors(colorIndex,:), 'xData', onTimes(timeIndex) + (offTimes(timeIndex) - onTimes(timeIndex)) * [ROI(scanOrder(timeIndex)).segments(segIndex) ROI(scanOrder(timeIndex)).segments(segIndex)], 'yData', get(gca, 'ylim'), 'buttonDownFcn', {@showSegmentLocation, timeIndex, segIndex});
                end
                
                % stop lines
                h{timeIndex, 2} = imline(gca,[offTimes(timeIndex) offTimes(timeIndex)], ylims);
                h{timeIndex, 2}.setPositionConstraintFcn({@dragStopLine, timeIndex}); 
                h{timeIndex, 2}.setColor(roiColors(colorIndex,:));
                
                if ~numel(ROI(scanOrder(timeIndex)).segments)
                    colorIndex = colorIndex + 1;
                end
%                 api(timeIndex, 2).addNewPositionCallback({@resavePhotometry});
%                 line([onTimes(timeIndex) onTimes(timeIndex)], get(gca, 'ylim'), 'color', 'green');
%                 line([offTimes(timeIndex) offTimes(timeIndex)], get(gca, 'ylim'), 'color', 'red');
            end
            set(tempHandle, 'xtick', mean([onTimes offTimes], 2), 'xticklabel', num2str(scanOrder'));
            subplot(5, 1, 5);
            plot(mean(imageData, 1));
            set(gca, 'xlim', get(tempHandle, 'xlim'), 'tag', 'photometryPathAxis');          
            
            resavePhotometry;
            % there is a bit of garbage at the beginning that has to be eliminated
            photometry(2,:) = photometry(1,:);
            
            formName = get(getappdata(0, 'imageDisplay'), 'name');
            if ~exist(formName(find(formName == ':', 1, 'last')-1:end), 'file')
                % this file is not saved so save it
                refImage = write2PRaster(evalin('base', 'zImage'));
                photometryHeader.referenceImage = refImage.info.Filename;
                set(getappdata(0, 'imageDisplay'), 'name', refImage.info.Filename);
            else
                photometryHeader.referenceImage = formName(find(formName == ':', 1, 'last')-1:end);
            end
            save(fileName, '-append', 'photometry', 'photometryHeader', 'ROI', 'roiDelay');           
            fileBrowser(fileName);
            setappdata(getappdata(0, 'roiPlot'), 'roiData', photometry);
            fcnHandle = get(getappdata(getappdata(0, 'roiPlot'), 'roiCommand'), 'callback');
            if ~isempty(fcnHandle)
                fcnHandle(0);
            end
            % rescale the data
%             tempData(:,1) = (tempData(:,1) - min(tempData(:,1))) ./ range(tempData(:,1));

            set(figHandle, 'visible', wasVisible, 'userData', @resavePhotometry, 'colormap', colorData);        
        end
        
        function new_pos = dragStartLine(pos, whichPair)
            new_pos(1:2, 2) = get(gca, 'ylim');
            rightBound = h{whichPair, 2}.getPosition();            
            if whichPair > 1
                leftBound = h{whichPair - 1, 2}.getPosition();       
            else
                leftBound = h{end, 2}.getPosition();
            end
            
            if rightBound(1) > leftBound(1)
                new_pos(1:2, 1) = max([leftBound(1) min([rightBound(1) - 1 mean(pos(1:2, 1))])]);      
            elseif mean(pos(1:2,1)) <= leftBound(1)
                if mean(pos(1:2,1)) < 1
                    new_pos(1:2, 1) = max([leftBound(1) mean(pos(1:2, 1)) + max(get(gca, 'xlim'))]);  
                elseif mean(pos(1:2,1)) < rightBound(1)
                    new_pos(1:2, 1) = mean(pos(1:2, 1));  
                else
                    new_pos(1:2, 1) = leftBound(1);  
                end
            else
                new_pos(1:2, 1) = min([rightBound(1) + max(get(gca, 'xlim')) mean(pos(1:2, 1))]);                  
                if mean(pos(1:2,1)) > max(get(gca, 'xlim'))
                    new_pos(1:2, 1) = new_pos(1:2, 1) - max(get(gca, 'xlim'));  
                end
            end

            new_pos = round(new_pos);
            onTimes(whichPair) = new_pos(1,1);       
            resavePhotometry;
            
            % handle any segments
            for segIndex = 1:numel(ROI(scanOrder(whichPair)).segments)
                whereX = onTimes(whichPair) + (offTimes(whichPair) - onTimes(whichPair)) * [ROI(scanOrder(whichPair)).segments(segIndex) ROI(scanOrder(whichPair)).segments(segIndex)];
                if whereX > max(get(gca, 'xlim'))
                    whereX = whereX - max(get(gca, 'xlim'));
                end
                set(sh(whichPair, segIndex), 'xData', whereX);
            end         
            
            % show where we are on the image
            if offTimes(whichPair) > leftBound(1)
                set(galvoHandle, 'xData', galvoLocations(onTimes(whichPair):offTimes(whichPair), 1), 'yData', galvoLocations(onTimes(whichPair):offTimes(whichPair), 2));             
            else
                set(galvoHandle, 'xData', galvoLocations([onTimes(whichPair):end 1:offTimes(whichPair)], 1), 'yData', galvoLocations([onTimes(whichPair):end 1:offTimes(whichPair)], 2));             
            end
        end
        
        function new_pos = dragStopLine(pos, whichPair)
            new_pos(1:2, 2) = get(gca, 'ylim');
            leftBound = h{whichPair, 1}.getPosition();            
            if whichPair < size(h, 1)
                rightBound = h{whichPair + 1, 1}.getPosition();            
            else
                rightBound = h{1, 1}.getPosition();
            end
            
            if rightBound(1) > leftBound(1)
                new_pos(1:2, 1) = max([leftBound(1) min([rightBound(1) - 1 mean(pos(1:2, 1))])]);      
            elseif mean(pos(1:2,1)) <= leftBound(1)
                if mean(pos(1:2,1)) < 1
                    new_pos(1:2, 1) = max([leftBound(1) mean(pos(1:2, 1)) + max(get(gca, 'xlim'))]);  
                elseif mean(pos(1:2,1)) < rightBound(1)
                    new_pos(1:2, 1) = mean(pos(1:2, 1));  
                else
                    new_pos(1:2, 1) = leftBound(1);  
                end
            else
                new_pos(1:2, 1) = min([rightBound(1) + max(get(gca, 'xlim')) mean(pos(1:2, 1))]);                  
                if mean(pos(1:2,1)) > max(get(gca, 'xlim'))
                    new_pos(1:2, 1) = new_pos(1:2, 1) - max(get(gca, 'xlim'));  
                end
            end
            
            new_pos = round(new_pos);
            offTimes(whichPair) = new_pos(1,1);        
            resavePhotometry;
            
            % handle any segments
            for segIndex = 1:numel(ROI(scanOrder(whichPair)).segments)
                whereX = onTimes(whichPair) + (offTimes(whichPair) - onTimes(whichPair)) * [ROI(scanOrder(whichPair)).segments(segIndex) ROI(scanOrder(whichPair)).segments(segIndex)];
                if whereX > max(get(gca, 'xlim'))
                    whereX = whereX - max(get(gca, 'xlim'));
                end
                set(sh(whichPair, segIndex), 'xData', whereX);
            end         
            
            % show where we are on the image
            if offTimes(whichPair) > leftBound(1)
                set(galvoHandle, 'xData', galvoLocations(onTimes(whichPair):offTimes(whichPair), 1), 'yData', galvoLocations(onTimes(whichPair):offTimes(whichPair), 2));             
            else
                set(galvoHandle, 'xData', galvoLocations([onTimes(whichPair):end 1:offTimes(whichPair)], 1), 'yData', galvoLocations([onTimes(whichPair):end 1:offTimes(whichPair)], 2));             
            end
        end

        function resavePhotometry(varargin)
            if nargin
                % reset the ROI data
                ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI'); 
                
                % determine which ROI will be scanned
                switch get(get(findobj('tag', 'imageScan'), 'selectedObject'), 'tag')
                    case 'scanCurrentRoi'
                        ROI = ROI(get(findobj('tag', 'cboRoiNumber'), 'value'));
                    case 'scanSpecifiedRoi'
                        ROI = ROI(str2num(protocolData.scanWhichRoi{1}));
                end
                
                axisHandle = findobj(getappdata(0, 'photometryPath'), 'tag', 'photometryPathAxis');
                
                roiColors = [0 0 0; colorSpread(numel([ROI.segments]) + numel(ROI))];    
                colorIndex = numel([ROI(1:scanOrder(varargin{1}) - 1).segments]);

                % handle any segment lines
                for segIndex = 1:numel(ROI(scanOrder(varargin{1})).segments)
                    whereX = onTimes(varargin{1}) + (offTimes(varargin{1}) - onTimes(varargin{1})) * [ROI(scanOrder(varargin{1})).segments(segIndex) ROI(scanOrder(varargin{1})).segments(segIndex)];
                    if whereX > max(get(axisHandle, 'xlim'))
                        whereX = whereX - max(get(axisHandle, 'xlim'));
                    end
                    colorIndex = colorIndex + 1;
                    if segIndex > size(sh, 2)
                        sh(varargin{1}, segIndex) = copyobj(sh(varargin{1}, segIndex), get(sh(varargin{1}, segIndex), 'parent'));
                    end
                    set(sh(varargin{1}, segIndex), 'xData', whereX, 'color', roiColors(colorIndex,:));
                end   
                if segIndex < size(sh, 2)
                    delete(sh(varargin{1}, segIndex + 1:end));
                end
            end 
            if ROI(1).Shape ~= 6
                photometry = nan(size(imageData, 1), numel([ROI.segments]) + numel(ROI));
                roiDelay = nan(size(photometry, 2), 1);                   
                for roiIndex = 1:numel(onTimes)
                    offset = numel([ROI(1:scanOrder(roiIndex) - 1).segments]) + scanOrder(roiIndex);
                    if isempty(ROI(roiIndex).segments)
                        if offTimes(roiIndex) > onTimes(roiIndex)
                            roiDelay(offset) = (onTimes(roiIndex) + offTimes(roiIndex)) / 2 * pixelUs / 1000;       
                            photometry(:, offset) = mean(imageData(:, onTimes(roiIndex):offTimes(roiIndex)), 2);                                 
                        elseif offTimes(roiIndex) < size(imageData, 2) - onTimes(roiIndex)
                            roiDelay(offset) = (onTimes(roiIndex) + offTimes(roiIndex) + size(imageData, 2)) / 2 * pixelUs / 1000;                               
                            photometry(1, offset) = sum(imageData(1, 1:offTimes(roiIndex))) ./ offTimes(roiIndex);                        
                            photometry(2:end, offset) = (sum(imageData(1:end - 1, onTimes(roiIndex) + max(get(axisHandle, 'xlim')):end), 2) + sum(imageData(2:end, 1:offTimes(roiIndex)), 2)) ./ (offTimes(roiIndex) - onTimes(roiIndex));
                        else
                            roiDelay(offset) = (onTimes(roiIndex) + offTimes(roiIndex) - size(imageData, 2)) / 2 * pixelUs / 1000;                               
                            photometry(1:end - 1, offset) = (sum(imageData(1:end - 1, onTimes(roiIndex):end), 2) + sum(imageData(2:end, 1:offTimes(roiIndex) - max(get(axisHandle, 'xlim'))), 2)) ./ (offTimes(roiIndex) - onTimes(roiIndex));
                            photometry(end, offset) = sum(imageData(end, onTimes(roiIndex):end)) ./ (size(imageData, 2) - onTimes(roiIndex) + 1);                        
                        end
                    else
                        segments = onTimes(roiIndex) + round([1 (offTimes(roiIndex) - onTimes(roiIndex)) .* ROI(roiIndex).segments offTimes(roiIndex) - onTimes(roiIndex)]);
                        for segIndex = 1:numel(segments) - 1
                            if segments(segIndex + 1) > segments(segIndex)
                                roiDelay(offset + segIndex - 1) = (segments(segIndex) + segments(segIndex + 1)) / 2 * pixelUs / 1000;       
                                photometry(:, offset + segIndex - 1) = mean(imageData(:, segments(segIndex):segments(segIndex + 1)), 2);                        
                            elseif segments(segIndex + 1) < size(imageData, 2) - segments(segIndex)
                                roiDelay(offset + segIndex - 1) = (segments(segIndex) + segments(segIndex + 1) + size(imageData, 2)) / 2 * pixelUs / 1000;                               
                                photometry(1, offset + segIndex - 1) = sum(imageData(1, 1:segments(segIndex + 1))) ./ segments(segIndex + 1);                        
                                photometry(2:end, offset + segIndex - 1) = (sum(imageData(1:end - 1, segments(segIndex) + max(get(axisHandle, 'xlim')):end), 2) + sum(imageData(2:end, 1:segments(segIndex + 1)), 2)) ./ (segments(segIndex + 1) - segments(segIndex));
                            else
                                roiDelay(offset + segIndex - 1) = (segments(segIndex) + segments(segIndex + 1) - size(imageData, 2)) / 2 * pixelUs / 1000;                               
                                photometry(1:end - 1, offset + segIndex - 1) = (sum(imageData(1:end - 1, segments(segIndex):end), 2) + sum(imageData(2:end, 1:segments(segIndex + 1) - max(get(axisHandle, 'xlim'))), 2)) ./ (segments(segIndex + 1) - segments(segIndex));
                                photometry(end, offset + segIndex - 1) = sum(imageData(end, segments(segIndex):end)) ./ (size(imageData, 2) - segments(segIndex) + 1);                        
                            end
                        end
                    end
                end
            else % line scan, time offset will be correct for odd pixels only
                if isempty(ROI.segments)
                    [onLoc onLoc] = min(abs(galvoLocations(numPoints / 2:end, 1) - galvoLocations(onTimes, 1)));
                    [offLoc offLoc] = min(abs(galvoLocations(numPoints / 2:end, 1) - galvoLocations(offTimes, 1)));                                            
                    if offTimes > onTimes
                        roiDelay = (onTimes + offTimes) / 2 * pixelUs / 1000;     
                        photometry(2:2:size(imageData, 1) * 2) = mean(imageData(:, numPoints / 2 - 1 + (offLoc:onLoc)), 2);
                        photometry(1:2:size(imageData, 1) * 2) = mean(imageData(:, onTimes(1):offTimes(1)), 2);                        
                    else
                        roiDelay = (onTimes + offTimes + size(imageData, 2) / 2) / 2 * pixelUs / 1000;                               
                        photometry = mean(imageData(:, onTimes:numPoints / 2 - 1 + offLoc), 2);
                    end
                else
                    segments = onTimes + round([1 (offTimes - onTimes) .* ROI.segments offTimes - onTimes]);
                    if any(diff(segments) < 1)
                        % one wraps and will need to be duplicated
                        for segIndex = 1:numel(segments) - 1
                            [onLoc onLoc] = min(abs(galvoLocations(numPoints / 2:end, 1) - galvoLocations(segIndex, 1)));
                            [offLoc offLoc] = min(abs(galvoLocations(numPoints / 2:end, 1) - galvoLocations(segIndex + 1, 1)));                                                                        
                            if segments(segIndex + 1) > segments(segIndex)
                                roiDelay(segIndex) = (segments(segIndex) + segments(segIndex + 1)) / 2 * pixelUs / 1000;       
                                photometry(2:2:size(imageData, 1) * 2, segIndex) = mean(imageData(:, numPoints / 2 - 1 + (offLoc:onLoc)), 2);   
                                photometry(1:2:size(imageData, 1) * 2, segIndex) = mean(imageData(:, segments(segIndex):segIndex(segIndex + 1)), 2);                        
                            else
                                roiDelay(segIndex) = (segments(segIndex) + segments(segIndex + 1) - size(imageData, 2)) / 2 * pixelUs / 1000;                               
                                photometry(2:2:size(imageData, 1) * 2, segIndex) = mean(imageData(:, segments(segIndex):numPoints / 2 - 1 + offLoc), 2);   
                                photometry(1:2:size(imageData, 1) * 2, segIndex) = photometry(2:2:size(imageData, 1) * 2, segIndex);
                            end
                        end
                    else % none wrap
                        for segIndex = 1:numel(segments) - 1
                            [offLoc offLoc] = min(abs(galvoLocations(numPoints / 2:end, 1) - galvoLocations(segIndex + 1, 1)));                                                                        
                            roiDelay(segIndex) = (segments(segIndex) + segments(segIndex + 1)) / 2 * pixelUs / 1000;       
                            photometry(:, segIndex) = mean(imageData(:, segments(segIndex):numPoints / 2 - 1 + offLoc), 2);   
                        end
                    end
                end
            end
            
            save(fileName, '-append', 'photometry', 'photometryHeader', 'ROI', 'roiDelay');           
            setappdata(getappdata(0, 'roiPlot'), 'roiData', photometry);
            tickLocations = mean([onTimes offTimes], 2);
            wrongLoc = offTimes < onTimes;
            tickLocations(wrongLoc) = mean([onTimes(wrongLoc) offTimes(wrongLoc) + size(imageData, 2)], 2);
            tickLocations(tickLocations > size(imageData, 2)) = tickLocations(tickLocations > size(imageData, 2)) - size(imageData, 2);
            [tickLocations tickOrder] = sort(tickLocations);
            set(tempHandle, 'xtick', tickLocations, 'xticklabel', num2str(scanOrder(tickOrder)'));            
            feval(getappdata(findobj(getappdata(0, 'roiPlot'), 'tag', 'roiCommand'), 'callback'));
        end
        
        function showSegmentLocation(varargin)
            % show where we are on the image
            segments = [ROI(varargin{3}).segments 1];
            set(galvoHandle, 'xData', galvoLocations(onTimes(varargin{3}) + segments(varargin{4}) * (offTimes(varargin{3}) - onTimes(varargin{3})):onTimes(varargin{3}) + segments(varargin{4} + 1) * (offTimes(varargin{3}) - onTimes(varargin{3})), 1), 'yData', galvoLocations(onTimes(varargin{3}) + segments(varargin{4}) * (offTimes(varargin{3}) - onTimes(varargin{3})):onTimes(varargin{3}) + segments(varargin{4} + 1) * (offTimes(varargin{3}) - onTimes(varargin{3})), 2));             
        end
	end
end