function doRepeat

experimentData =  getappdata(0, 'currentExperiment');
buttonHandle = findobj('type', 'uicontrol', 'tag', 'cmdRepeat');

% performs a repeated episode at the interval assigned
if strcmp(get(buttonHandle, 'string'), 'Repeat')
    protocol = getappdata(0, 'currentProtocol');
    if experimentData.repeatInterval * 1000 >= protocol.sweepWindow + 1000 
        delete(timerfind('name', 'repeatTimer'));
        repeatTimer = timer('startfcn', @(varargin) set(findobj('type', 'uicontrol', 'tag', 'cmdRepeat'), 'string', 'No More'), 'stopfcn', {@stopTimer, findobj('tag', 'cmdRepeat')}, 'name', 'repeatTimer', 'TimerFcn','doSingle', 'Period', experimentData.repeatInterval, 'executionMode', 'fixedRate', 'tasksToExecute', experimentData.repeatNumber);
        set(buttonHandle, 'userData', repeatTimer);
        start(repeatTimer);
%         set(buttonHandle, 'string', 'No more');
    else
        error('Repeat interval is too short for sweep window')
        % without this the ttl lines spasm white noise, so don't take it
        % out
    end
else
    if ~isempty(timerfind('name', 'repeatTimer'))
		stop(timerfind('name', 'repeatTimer'));
        delete(timerfind('name', 'repeatTimer'));
    end
	set(buttonHandle, 'string', 'Repeat');
end

function stopTimer(varargin)
    set(varargin{3}, 'string', 'Repeat');
    delete(timerfind('name', 'repeatTimer'));