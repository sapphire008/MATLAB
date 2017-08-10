function removeAmp(panelHandle, junk)

% deletes the currently selected amplifier
    
    handles = get(ancestor(panelHandle, 'figure'), 'userData');
    info = getappdata(handles.pnlAmps, 'tabData');
    if nargin < 1
        n = find(strcmp(get(info.lineHiders, 'visible'), 'on'));   
    else
        n = numel(info.removeButtons) + 1 - find(info.removeButtons == panelHandle);   
    end
    
	% free up channels that were being used
	set(handles.ampVoltage(n), 'value', numel(get(handles.ampVoltage(n), 'string')));
	changeVoltage(n);
	set(handles.ampCurrent(n), 'value', numel(get(handles.ampCurrent(n), 'string')));
	changeCurrent(n);
	set(handles.ampTelegraph(n), 'value', numel(get(handles.ampTelegraph(n), 'string')));
	changeTelegraph(n);
	
    delete([info.tabButtons(n) info.lineHiders(n) info.panels(n) info.removeButtons(end + 1 - n)]);
    info.tabButtons = info.tabButtons([1:n - 1 n + 1:end]);
    info.lineHiders = info.lineHiders([1:n - 1 n + 1:end]);
    info.panels = info.panels([1:n - 1 n + 1:end]);
	info.removeButtons = info.removeButtons([1:n - 1 n+ 1:end]);
    info.numAmps = info.numAmps - 1;
    setappdata(handles.pnlAmps, 'tabData', info);    
	if numel(info.panels) > 0
        if n > 1
            tabChange(info.tabButtons(n - 1));
        else
            tabChange(info.tabButtons(n));            
        end
        for i = n:numel(info.tabButtons)
            set(info.tabButtons(i), 'position', [1.2 + 17.4 * (i - 1) 28 17.6 1.692], 'string', ['Amp ' char(i + 64)]);
            set(info.lineHiders(i), 'position', [1.4 + 17.4 * (i - 1) 27.769 16.8 0.692]);    
        end            
	end
	
    % update the experiment panel if it is present
% 		set(getappdata(0, 'runningProtocol'), 'userData', guihandles(gcf));
		saveProtocol;
		set(ancestor(handles.pnlAmps, 'figure'), 'userData', guihandles(ancestor(handles.pnlAmps, 'figure')));
        if isappdata(0, 'experiment')
            updateExperiment;
        end	