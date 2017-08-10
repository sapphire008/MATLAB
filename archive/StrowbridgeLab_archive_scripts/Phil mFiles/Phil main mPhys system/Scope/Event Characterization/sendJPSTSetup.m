function outText = sendJPSTSetup(varargin)
if ~nargin
    outText = 'JPSTH with';
else
    handleList = get(gcf, 'userData');
    stringData = get(handleList.channelControl(1).channel, 'string');
    ourVals = {stringData{cell2mat((get([handleList.channelControl.channel], 'value'))')}};
	kids = get(varargin{1}, 'children');
	if numel(kids) > numel(ourVals)
		delete(kids(numel(ourVals) + 1:end));
	end
	for i = 1:numel(kids)
		set(kids(i), 'label', ourVals{i});
	end
    for i = numel(kids) + 1:numel(ourVals)
		uimenu(varargin{1}, 'Label', ourVals{i}, 'callback', {@sendJPSTData, varargin{3}, varargin{4}, varargin{5}});
    end
end
    
function sendJPSTData(varargin)
global startstopRange

    % call functions of the U Penn MU lab
    handleList = get(gcf, 'userData');
        
    % from events 
    fromAxis = gca;
    fromEvents = getappdata(fromAxis, 'events');
    
    % to events
    whichKid = get(varargin{1}, 'Label');
    stringData = get(handleList.channelControl(1).channel, 'string');    
    ourVals = {stringData{cell2mat((get([handleList.channelControl.channel], 'value'))')}};    
    for i = 1:numel(ourVals)
        if strcmp(whichKid, ourVals{i})
            whichTrace = i;
            break
        end
    end    
    toEvents = getappdata(handleList.axes(whichTrace), 'events');
    
    % transform spikes to peristiimulus time
    gdfData = [];
    whichTTL = [];
    for i = 1:numel(fromEvents)
        protocol = readTrace(fromEvents(i).traceName, 1);
        stimTimes = findStims(protocol);
        if isempty(whichTTL)
            ttlOn = cellfun(@(x) ~isempty(x), stimTimes);
            if sum(ttlOn) < 1
                error('No stimulus found')
            end
            if sum(ttlOn > 1)
                % ask which ttl
                whichTTL = listdlg('ListString', protocol.ttlTypeName(ttlOn), 'SelectionMode', 'single', 'PromptString', 'Stimulus:');
            else
                whichTTL = ttlOn;
            end
            if numel(stimTimes{whichTTL}) > 1
                % ask which stim (or all)
                whichStim = inputdlg({'Which stimuli ('':'' for all)'},'',1, {'1'});      
                if strcmp(whichStim{1}, ':')
                    whichStim = whichStim{1};
                else
                    whichStim = str2num(whichStim{1});
                end
            else
                whichStim = 1;
            end
        end
        gdfData(end + (1:numel(fromEvents(i).data) + 1), :) = [30 protocol.cellTime * 1000000 / protocol.timePerPoint + stimTimes{whichTTL}(whichStim); ones(size(fromEvents(i).data')) (protocol.cellTime * 1000 + fromEvents(i).data') .* 1000 ./ protocol.timePerPoint];
    end    

    for i = 1:numel(toEvents)
        protocol = readTrace(toEvents(i).traceName, 1);
        gdfData(end + (1:numel(toEvents(i).data)), :) = [2 * ones(size(toEvents(i).data')) (protocol.cellTime * 1000 + toEvents(i).data') .* 1000 ./ protocol.timePerPoint];
    end    
    
    if isempty(findobj('tag', 'JPSTMain'))
        JPST;
    end
    JPST('setGDFTicks', 1000 / protocol.timePerPoint);
    JPSTGUI('transferGDF', sortrows(gdfData, 2));
    JPSTGUI('setTimeRange', [0 20000]);
    startstopRange = [0 20000];
    JPSTGUI('UpDateStart');   
    JPSTGUI('UpDateStop');    
    