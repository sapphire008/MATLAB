function updateExperiment
% add appropriate check boxes on the experimental pane

if isappdata(0, 'currentProtocol')
    experimentHandles = guihandles(getappdata(0, 'experiment'));
    protocolData = getappdata(0, 'currentProtocol');

    if isfield(experimentHandles, 'ampEnable')
        delete(experimentHandles.ampEnable);
    end

	if isfield(protocolData, 'ampType')
        for i = numel(protocolData.ampType):-1:1
            uicontrol('value', 1, 'units', 'char', 'callback', 'saveExperiment; changeRunningChannel;', 'parent', experimentHandles.pnlEnable, 'style', 'check', 'tag', 'ampEnable', 'string', char(64 + i), 'position', [1.6 + (i - 1) * 6 .231 5.4 1.769 ]);
        end
	end
	if get(experimentHandles.internal, 'value') == numel(get(experimentHandles.internal, 'string'))
		% we have an 'other' categorization to deal with
		currentVals = getpref('experiment', 'internals');
		newValue = inputdlg('Enter information for new internal (preferably with an accompanying number)');
		if numel(newValue) > 0
			newVals = sort([currentVals newValue]);
			setpref('experiment', 'internals', newVals);
			set(experimentHandles.internal, 'string', [newVals [char(173) 'Other' char(173)]]);
			set(experimentHandles.internal, 'value', find(strcmp(newVals, newValue)));
		end
	end
	if get(experimentHandles.bath, 'value') == numel(get(experimentHandles.bath, 'string'))
		% we have an 'other' categorization to deal with
		currentVals = getpref('experiment', 'baths');
		newValue = inputdlg('Enter information for new bath');
		if numel(newValue) > 0
			newVals = sort([currentVals newValue]);
			setpref('experiment', 'baths', newVals);
			set(experimentHandles.bath, 'string', [newVals [char(173) 'Other' char(173)]]);
			set(experimentHandles.bath, 'value', find(strcmp(newVals, newValue)));
		end
	end
	if get(experimentHandles.drug, 'value') == numel(get(experimentHandles.drug, 'string'))
		% we have an 'other' categorization to deal with
		currentVals = getpref('experiment', 'drugs');
		newValue = inputdlg('Enter information for new drug (preferably with an accompanying molarity)');
		if numel(newValue) > 0
			newVals = sort([currentVals newValue]);
			setpref('experiment', 'drugs', newVals);
			set(experimentHandles.drug, 'string', [newVals [char(173) 'Other' char(173)]]);
			set(experimentHandles.drug, 'value', find(strcmp(newVals, newValue)));
		end
	end
	saveExperiment;
end