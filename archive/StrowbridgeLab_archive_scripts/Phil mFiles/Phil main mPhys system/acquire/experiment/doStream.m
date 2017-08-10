function doStream

% called by pressing the doStream button on the GUI

handles = guihandles(getappdata(0, 'experiment'));

if strcmp(get(handles.cmdStream, 'string'), 'Stream')
    % start a stream
	set(handles.lblEpisodeTime, 'string', 'Stream:');
    set(handles.cmdStream, 'string', 'Stop');
	saveExperiment;
	nextEpisode = get(handles.nextEpisode, 'string');	
	set(handles.nextEpisode, 'string', [nextEpisode(1:find(nextEpisode == 'E', 1, 'last')) num2str(str2double(nextEpisode(find(nextEpisode == 'E', 1, 'last') + 1:end)) + 1)]);	
    stop(timerfind('name', 'experimentClock'));
	feval(get(timerfind('name', 'experimentClock'), 'TimerFcn'), '-startStream');
	start(timerfind('name', 'experimentClock'));
	set(handles.episodeTime, 'userData', clock);	
else
    % stop a stream
	set(handles.lblEpisodeTime, 'string', 'Episode:');	
    stop(timerfind('name', 'experimentClock'));	
	feval(get(timerfind('name', 'experimentClock'), 'TimerFcn'), '-stopStream');
	start(timerfind('name', 'experimentClock'));	
end