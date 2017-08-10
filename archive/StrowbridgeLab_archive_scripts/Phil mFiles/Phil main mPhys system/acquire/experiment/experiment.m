function experiment(inData)

% loads the experiment figure and sets it up
% experiment
% experiment(startingDirectory)

% load the figure
	if ~isappdata(0, 'experiment')
        handles = guihandles(hgload('experiment.fig'));
        setappdata(0, 'experiment', handles.experiment);
		
		% set its location
		if ~ispref('locations', 'experiment')
			setpref('locations', 'experiment', [2960 743 236 417]);
		end	
		set(handles.experiment, 'position', getpref('locations', 'experiment'), 'color', get(0, 'defaultUicontrolBackgroundColor'));
		
        if nargin == 1 && isnumeric(inData) && ismember(inData, [4 8 16])
            ttlSpecified = 1;
            numTTL = inData;
        else
            ttlSpecified = 0;
            numTTL = 4;
        end
		if nargin < 1 || isnumeric(inData)
			inData = pwd;
		end

		set(handles.mnuLoadProtocol, 'userData', inData);
		set(handles.mnuSaveProtocol, 'userData', inData);
		set(handles.mnuSetDataFolder, 'userData', inData);		
        set(handles.experiment, 'closeRequestFcn', @closeMe);
        
        createExpTTL(numTTL, handles.ttlHolder);
        
        if ~ispref('experiment', 'internals')
            setpref('experiment', 'internals', {'-None-', 'Cs-methanesulfonate (19)', 'K-methanesulfonate (27)'});
            setpref('experiment', 'baths', {'-None-', '0 Mg', '3 mM K', '5 mM K'});
            setpref('experiment', 'drugs', {'-None-', 'APV (25 uM)', 'NBQX (5 uM)', 'TTX (1 uM)'});
			setpref('experiment', 'cellTypes', {'CA1', 'CA3', 'DGCL', 'Hilar', 'IML'});
			setpref('experiment', 'ttlTypes', {'SIU, tungsten, PP', 'Puff (5 mM Glu)'});
            currentAmps;
        end
        set(handles.internal, 'string', [getpref('experiment', 'internals') [char(173) 'Other' char(173)]]);
        set(handles.bath, 'string', [getpref('experiment', 'baths') [char(173) 'Other' char(173)]]);
        set(handles.drug, 'string', [getpref('experiment', 'drugs') [char(173) 'Other' char(173)]]);
        
        experimentCommands = loadMatlabText('experimentCommands.txt');
        set(handles.matlabCommand,'userData', {size(experimentCommands, 2) + 1, experimentCommands},'keyPressFcn', @commandKeyPress);
        
        saveExperiment;        
        
        expTimer = timer('name', 'experimentClock', 'TimerFcn','', 'Period', 0.1, 'executionMode', 'fixedDelay', 'busyMode', 'queue');
        setappdata(0, 'readChannels', 0);
        setappdata(0, 'writeChannels', 0);
        % load the protocol gui
        loadProtocol(['defaultProtocol' num2str(numTTL) '.mat']);
        
        % determine what hardware is present
        if exist([getenv('systemroot') '\system32\itc18vb.dll'], 'file')
            % ITC-18 is ready to go
            whatHW{1} = 'ITC-18';
            hwIDs{1} = [];
            hwDrivers{1} = [];
        else
            whatHW = {};
            hwIDs = {};
            hwDrivers = {};            
        end
        try
            daqInfo = daqhwinfo;
            for i = daqInfo.InstalledAdaptors'
                % I edited line 176 of daqhwinfo to read:
                %  nidaqResults = []; %daq.engine.getadaptorinfo(nidaqAdaptorName);
                % so that the NI Traditional adapter won't be recognized
                % and mess up the nidaqmx adaptor use.

                daqBoards = daqhwinfo(i{1});
                
                % check to assure that analog input is allowed
                if ~all(all(cellfun(@(x) isempty(x), strfind(daqBoards.ObjectConstructorName, 'analoginput'))))
                    whatHW = [whatHW daqBoards.BoardNames];
                    hwIDs = [hwIDs daqBoards.InstalledBoardIds];
                    hwDrivers = [hwDrivers repmat(i, 1, numel(daqBoards.InstalledBoardIds))];
                end
            end
        catch
            warning('Error using Data Acquisition Toolbox');
        end
        if isempty(whatHW)
            whatHW{1} = 'None';
            hwDrivers{1} = '';
            hwIDs{1} = '';
            set(findobj(getappdata(0, 'runningProtocol'), 'tag', 'ampType'), 'value', 1, 'enable', 'off');
        end
        set(findobj(getappdata(0, 'runningProtocol'), 'tag', 'source'), 'userData', {hwDrivers hwIDs}, 'string', whatHW);
        changeAdBoard(getappdata(0, 'runningProtocol'));
        
        if isempty(hwDrivers{1})
            changeAmp(1, getappdata(0, 'runningProtocol'));
            saveProtocol;
        end
        
        set(handles.cellTime, 'userData', clock);
        set(handles.episodeTime, 'userData', clock);
        set(handles.drugTime, 'userData', clock);
        saveExperiment;
        timerCallback = get(expTimer, 'TimerFcn');
		clear(timerCallback);
        feval(timerCallback);
%         pause(.3); % to allow persistent variables and what not to be set
        start(expTimer);
		
% 		if ispref('mitutoyo', 'xComm')
%             if ispref('ASI', 'commPort')
% 				switch questdlg('Both ASI and Mitutoyo indicators have been setup on this system.  Which would you like to use for location', '', 'ASI', 'Mitutoyo', 'ASI')
% 					case 'ASI'
% 						asiGui;
% 					case 'Mitutoyo'
% 						mitutoyoGui;
% 				end
% 			else
% 				mitutoyoGui;
%             end
%         else
%             if ispref('ASI', 'commPort')
%                 asiGui;
%             end
% 		end
else
    handles.experiment = figure(getappdata(0, 'experiment'));
end    

onScreen(handles.experiment);    
if nargin < 1 || ttlSpecified
	setDataFolder;
else
	set(findobj('tag', 'mnuSetDataFolder'), 'userData', inData);
end

function commandText = loadMatlabText(fileName)
fid = fopen(fileName);
whichCommand = 1;
if fid > 0
    while 1
        tline = fgetl(fid);
        if ~ischar(tline)
            break
        end
        commandText{whichCommand} = tline;
        whichCommand = whichCommand + 1;
    end
    fclose(fid);
else
    commandText = '';
end

function addText(src, eventInfo)
userData = get(src, 'userData');
commandText = userData{2};
newCommand = cell2mat(get(src, 'string'));
if find(strcmp(commandText, newCommand))
    commandText(find(strcmp(commandText, newCommand)):length(commandText) - 1) = commandText(find(strcmp(commandText, newCommand)) + 1:length(commandText));
    commandText{length(commandText)} = newCommand;
    set(src, 'userData', {length(commandText), commandText});
else
    commandText{end + 1} = newCommand;
    set(src, 'userData', {length(commandText), commandText});		
end

function commandKeyPress(src, eventInfo)
userData = get(src, 'userData');
commandText = userData{2};
whichCommand = userData{1};

if whichCommand <= length(commandText) + 1 && whichCommand > -1
    if strcmp(eventInfo.Key, 'downarrow')  % down arrow
        if whichCommand < length(commandText)
            whichCommand = whichCommand + 1;
            set(src, 'string', commandText{whichCommand});
        elseif whichCommand == length(commandText)
            whichCommand = whichCommand + 1;
            set(src, 'string', '');
        end
    end

    if strcmp(eventInfo.Key, 'uparrow') && whichCommand > 1 % up arrow
        whichCommand = whichCommand - 1;
        set(src, 'string', commandText{whichCommand});
    end
end

set(src, 'userData', {whichCommand, commandText})

if strcmp(eventInfo.Key, 'return')
    handles = get(gcf, 'userdata');
    pause(.05);
    addText(src, eventInfo);
end    

function closeMe(varargin)
	stop(timerfind('name', 'experimentClock'));
    delete(timerfind('name', 'experimentClock'));
	if ~isempty(timerfind('name', 'repeatTimer'))
		stop(timerfind('name', 'repeatTimer'));
		delete(timerfind('name', 'repeatTimer'));
	end
	set(getappdata(0, 'runningProtocol'), 'units', 'pixel');
	setpref('locations', 'runningProtocol', get(getappdata(0, 'runningProtocol'), 'position'));		
	if isappdata(0, 'sealTest')
		close(getappdata(0, 'sealTest'))
	end
    
	if isappdata(0, 'bridgeBalance')
		close(getappdata(0, 'bridgeBalance'))
	end
	
    if isappdata(0, 'runningScope')
		close(getappdata(0, 'runningScope'))
    end
    delete(getappdata(0, 'runningProtocol'));
	
    rmappdata(0, 'experiment');
    rmappdata(0, 'currentExperiment');
    rmappdata(0, 'runningProtocol');
    rmappdata(0, 'currentProtocol');
    rmappdata(0, 'daScaleFactors');
    rmappdata(0, 'adScaleFactors');
    
    oldHardware = getappdata(0, 'adBoard');
    if isstruct(oldHardware) && isfield(oldHardware, 'analogIn')
        delete(oldHardware.analogIn);
        delete(oldHardware.analogOut);
    end    
    rmappdata(0, 'adBoard');
	
	set(gcf, 'units', 'pixels');
	setpref('locations', 'experiment', get(gcf, 'position'));		
    delete(gcf);