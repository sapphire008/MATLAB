function setDataFolder

% set the folder to which data files will be saved
    handles = guihandles(getappdata(0, 'experiment'));
    
    folder = uigetdir(get(handles.mnuSetDataFolder, 'userData'),...
        'Select a directory into which files will be saved');
    
    if ischar(folder)
        set(handles.mnuSetDataFolder, 'userData', folder);
	else
		set(handles.mnuSetDataFolder, 'userData', pwd);
    end
    
    saveExperiment;