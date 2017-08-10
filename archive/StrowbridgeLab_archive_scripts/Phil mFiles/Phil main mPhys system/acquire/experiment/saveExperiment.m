function inData = saveExperiment

% saves the current experiment

if ~isappdata(0, 'experiment')
    error('No current experimental data')
end

handles = guihandles(getappdata(0, 'experiment'));

fields = fieldnames(handles);

for fieldIndex = 1:numel(fields)
    if strcmp(get(handles.(fields{fieldIndex}), 'type'), 'uicontrol')
        switch get(handles.(fields{fieldIndex})(1), 'style')
            case 'text'
                if ismember(fields{fieldIndex}, {'cellTime', 'episodeTime', 'drugTime'})
                    inData.(fields{fieldIndex}) = time2sec(get(handles.(fields{fieldIndex}), 'string'));
                end
                if strcmp(fields{fieldIndex}, 'nextEpisode')
					get(handles.(fields{fieldIndex}), 'string');
                    inData.nextEpisode = get(handles.(fields{fieldIndex}), 'string');
                end
            case 'edit'
                if ismember(fields{fieldIndex}, {'repeatInterval', 'repeatNumber'})
                    inData.(fields{fieldIndex}) = str2double(get(handles.(fields{fieldIndex}), 'string'));
                else
                    inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'string');
                end
            case 'checkbox'
                inData.(fields{fieldIndex}) = get(handles.(fields{fieldIndex}), 'value');
				if ~iscell(inData.(fields{fieldIndex}))
                    inData.(fields{fieldIndex}) = {inData.(fields{fieldIndex})};
				end
			case 'popupmenu'
				stringData = get(handles.(fields{fieldIndex}), 'string');
				inData.(fields{fieldIndex}) = stringData{get(handles.(fields{fieldIndex}), 'value')};
        end
    end
end

inData.dataFolder = get(handles.mnuSetDataFolder, 'userData');

setappdata(0, 'currentExperiment', inData);
set(handles.experiment, 'userData', handles);

if nargout == 0
    clear inData
end