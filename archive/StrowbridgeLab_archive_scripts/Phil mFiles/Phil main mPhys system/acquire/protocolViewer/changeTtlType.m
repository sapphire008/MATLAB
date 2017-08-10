function changeTtlType(ttlNum, newValue, figHandle)

    if nargin < 3
        handles = get(getappdata(0, 'runningProtocol'), 'userData');
    else
        handles = get(figHandle, 'userData');
    end
    
	if nargin < 1
		ttlNum = find(handles.ttlType == gcbo);
	end
	
	% deal with new cell types	
		strings = get(handles.ttlType(ttlNum), 'string');
		if nargin >= 2 || strcmp(strings{get(handles.ttlType(ttlNum), 'value')}, 'Other')
			% we have an 'other' categorization to deal with
			currentVals = getpref('experiment', 'ttlTypes');
			
			if nargin < 2
				newValue = inputdlg('Enter new TTL type');
				if numel(newValue) == 0
					return
				end
			end
			
			newVals = sort([currentVals newValue]);
			setpref('experiment', 'ttlTypes', newVals);
			lastValues = get(handles.ttlType, 'value');
			set(handles.ttlType, 'string', [newVals 'Other']);
			set(handles.ttlType(ttlNum), 'value', find(strcmp(newVals, newValue)));
			for i = [1:ttlNum - 1 ttlNum + 1:length(lastValues)]
				set(handles.ttlType(i), 'value', find(strcmp(newVals, strings(lastValues{i}))));
			end
		end