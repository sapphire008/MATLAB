function audioScope

% creates an audioScope figure

if ~isappdata(0, 'audioScope')
	% set the pref if not present
	if ~ispref('locations', 'audioScope')
		setpref('locations', 'audioScope', [2769 555 412 118]);
	end	
    % create one
    setappdata(0, 'audioScope', hgload('audioScope.fig'));
else
    % bring the existing one to the front
    figure(getappdata(0, 'audioScope'));
end

% set the default settings
set(gcf, 'position', getpref('locations', 'audioScope'));	
onScreen(gcf);
handles = guihandles(getappdata(0, 'audioScope'));

set(handles.enableButtons, 'selectionChangeFcn', @enableChange);
set(getappdata(0, 'audioScope'), 'closeRequestFcn', @closeMe);

set(handles.enableStereo, 'value', 1);
set(handles.leftVolume, 'value', -3);
set(handles.rightVolume, 'value', -3);
set(getappdata(0, 'audioScope'), 'name', 'Audio Scope');
set(handles.rightChannel, 'callback', @changeAudioChannel);
set(handles.leftChannel, 'callback', @changeAudioChannel);

% create the audio player object
set(getappdata(0, 'audioScope'), 'userData', audioplayer(0, 5000, 16));
changeAudioChannel;

function enableChange(varargin)
    handles = guihandles(getappdata(0, 'audioScope'));
    audioHandle = get(getappdata(0, 'audioScope'), 'userData');
    
    switch(varargin{2}.NewValue)
        case handles.enableStereo
            set(handles.pnlLeft, 'title', 'Left');            
            set(handles.pnlLeft, 'visible', 'on');
            set(handles.pnlRight, 'visible', 'on');            
        case handles.enableMono
            set(handles.pnlLeft, 'title', 'Mono');            
            set(handles.pnlLeft, 'visible', 'on');
            set(handles.pnlRight, 'visible', 'off');            
    end
	
function closeMe(varargin)
	set(gcf, 'units', 'pixel');
	setpref('locations', 'audioScope', get(gcf, 'position'));
    rmappdata(0, 'audioScope');
    delete(varargin{1});