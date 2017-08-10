function changeCell(ampNum, newValue, figHandle)

    if nargin < 3
        handles = get(getappdata(0, 'runningProtocol'), 'userData');
    else
        handles = get(figHandle, 'userData');
    end
    
    if nargin < 1
		ampNum = find(handles.ampCellLocation == gcbo);
    end
    
	% deal with new cell types	
		strings = get(handles.ampCellLocation(ampNum), 'string');
		if nargin > 1 || strcmp(strings{get(handles.ampCellLocation(ampNum), 'value')}, 'Other')
			% we have an 'other' categorization to deal with
			currentVals = getpref('experiment', 'cellTypes');
			if nargin < 2
				newValue = inputdlg('Enter new cell location');
				if numel(newValue) == 0
					return
				end
			end
			
			newVals = sort([currentVals newValue]);
			setpref('experiment', 'cellTypes', newVals);
			lastValues = get(handles.ampCellLocation, 'value');
			set(handles.ampCellLocation, 'string', [newVals 'Other']);
			set(handles.ampCellLocation(ampNum), 'value', find(strcmp(newVals, newValue)));
			for i = [1:ampNum - 1 ampNum + 1:length(lastValues)]
				set(handles.ampCellLocation(i), 'value', find(strcmp(newVals, strings(lastValues{i}))));
			end
		end
		
	% reset any stims or input resistance estimates
		clear(get(timerfind('name', 'experimentClock'), 'TimerFcn'), 'reducedNeurons');