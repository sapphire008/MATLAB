function bridgeBalance(ampNumber)

sweepTime = 80; % msec

if ~ispref('locations', 'bridgeBalance')
	setpref('locations', 'bridgeBalance', [1235 678 560 420]);
end

if isappdata(0, 'currentProtocol')
    protocolData = getappdata(0, 'currentProtocol');
else
    error('No current protocol data')
end

if nargin < 1
    handles = get(getappdata(0, 'runningProtocol'), 'userData');
    info = getappdata(handles.pnlAmps, 'tabData');    
    ampNumber = find(strcmp(get(info.lineHiders, 'visible'), 'on'));   
end

% don't allow a current and voltage step at the same time
if isappdata(0, 'sealTest')
	tempTitle = get(getappdata(0, 'sealTest'), 'name');
	if ampNumber == tempTitle(5) - 64
		close(getappdata(0, 'sealTest'));
	end
end

% change to CClamp mode if applicable
amplifiers = getpref('amplifiers', 'amplifiers');
whichAmp = strcmp(amplifiers, [amplifiers{get(handles.ampType(ampNumber), 'value')}(1:end - 2) 'CC']);
if sum(whichAmp) && ~strcmp(amplifiers{get(handles.ampType(ampNumber), 'value')}(end - 1:end), 'CC')
	oldValue = get(handles.ampType(ampNumber), 'value');
	set(handles.ampType(ampNumber), 'value', find(whichAmp));
	changeAmp(ampNumber, getappdata(0, 'runningProtocol'));
	saveProtocol;
else
	oldValue = 0;
end

if isappdata(0, 'bridgeBalance')
    figHandle = getappdata(0, 'bridgeBalance');
	figure(figHandle);
    delete(get(figHandle, 'children'));
    set(figHandle, 'name', ['Amp ' char(64 + ampNumber)]);
else
    figHandle = figure('handleVisibility', 'callback', 'position', getpref('locations', 'bridgeBalance'), 'menu', 'none', 'numbertitle', 'off', 'name', ['Amp ' char(64 + ampNumber)], 'closereq', @closeMe);
end

onScreen(figHandle);
axes('position', [.05 .05 .95 .95],...
    'units', 'normal',...
    'xlim', [0 sweepTime],...
    'drawmode', 'fast',...
    'color', [0 0 0])
line(protocolData.timePerPoint / 1000 * (1:sweepTime * 1000 / protocolData.timePerPoint)', zeros(sweepTime * 1000 / protocolData.timePerPoint, 1), 'color', [0 .8 0]);

setappdata(0, 'bridgeBalance', figHandle);

	function closeMe(varargin)
		rmappdata(0, 'bridgeBalance');
		set(gcf, 'units', 'pixel');	
		setpref('locations', 'bridgeBalance', get(gcf, 'position'));

		% change to VClamp mode if applicable
		if oldValue > 0
			set(handles.ampType(ampNumber), 'value', oldValue);
			changeAmp(ampNumber, getappdata(0, 'runningProtocol'));
			saveProtocol;
		end
		
		delete(gcf);
	end
end