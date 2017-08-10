function currentAmps
% end any current channel name with I, voltage with V for the browser to
% recognize the units
    amplifiers = {};
    voltageChannels = {};
    voltageFactors = {};
    currentChannels = {};
    currentFactors = {};
    stimFactors = [];

    otherChannels = {};
    otherChannelFactors = [];
	
	% Matlab in current clamp
		amplifiers{end + 1} = 'Izh CC';
		voltageChannels{end + 1, 1} = 'simulated V';
		voltageFactors{end + 1, 1} = NaN;
		currentChannels{end + 1, 1} = 'injected I';
		currentFactors{end + 1, 1} = NaN; % tells other subs that this is a simulation amp
		stimFactors(end + 1) = 1;
		
    % AxoPatch in voltage clamp
        amplifiers{end + 1} = 'AxoPatch VC';
        voltageChannels{end + 1, 1} = '10x V';
        voltageChannels{end, 2} = '1x V';
        voltageFactors{end + 1, 1} = 0.1;
        voltageFactors{end, 2} = 1;
        currentChannels{end + 1, 1} = 'Direct I';
        currentChannels{end, 2} = 'Scaled I';
        currentFactors{end + 1, 1} = 1;
        currentFactors{end, 2} = @(x)axoPatchAlpha(1, x);
        stimFactors(end + 1) = 50;

    % AxoPatch in current clamp
        amplifiers{end + 1} = 'AxoPatch CC';
        voltageChannels{end + 1, 1} = '10x V';
        voltageChannels{end, 2} = '1x V';
        voltageFactors{end + 1, 1} = 0.1;
        voltageFactors{end, 2} = 1;
        currentChannels{end + 1, 1} = 'Direct I';
        currentChannels{end, 2} = 'Scaled I';
        currentFactors{end + 1, 1} = 1;
        currentFactors{end, 2} = @(x)axoPatchAlpha(1, x);
        stimFactors(end + 1) = 5;

    % Dagan in voltage clamp
        amplifiers{end + 1} = 'Dagan VC';
        voltageChannels{end + 1, 1} = '50x V';
        voltageChannels{end, 2} = '1x V';
        voltageFactors{end + 1, 1} = 0.02;
        voltageFactors{end, 2} = 1;
        currentChannels{end + 1, 1} = 'Direct I';
        currentFactors{end + 1, 1} = 1;
        stimFactors(end + 1) = 50;

    % Dagan in current clamp
        amplifiers{end + 1} = 'Dagan CC';
        voltageChannels{end + 1, 1} = '50x V';
        voltageChannels{end, 2} = '1x V';
        voltageFactors{end + 1, 1} = 0.02;
        voltageFactors{end, 2} = 1;
        currentChannels{end + 1, 1} = 'Direct I';
        currentFactors{end + 1, 1} = 1;
        stimFactors(end + 1) = 5;   
        
    % Linear SIU
        amplifiers{end + 1} = 'Linear SIU (%)';
        voltageChannels{end + 1, 1} = 'NA';
        voltageFactors{end + 1, 1} = 1;
        currentChannels{end + 1, 1} = 'NA';
        currentFactors{end + 1, 1} = 1;
        stimFactors(end + 1) = 100;

	% Pockel Cell
        amplifiers{end + 1} = 'Pockel Cell (%)';
        voltageChannels{end + 1, 1} = 'NA';
        voltageFactors{end + 1, 1} = 1;
        currentChannels{end + 1, 1} = 'NA';
        currentFactors{end + 1, 1} = 1;
        stimFactors(end + 1) = 1000;
        
%     % AxoClamp at 0.1L
%         amplifiers{end + 1} = 'AxoClamp 0.1L';
%         voltageChannels{end + 1, 1} = '10x V';
%         voltageChannels{end, 2} = '1x V';
%         voltageFactors{end + 1, 1} = 0.02;
%         voltageFactors{end, 2} = 1;
%         currentChannels{end + 1, 1} = 'Direct I';
%         currentFactors{end + 1, 1} = 1;
%         stimFactors(end + 1) = 1;        
% 
%     % AxoClamp at 1.0L
%         amplifiers{end + 1} = 'AxoClamp 1.0L';
%         voltageChannels{end + 1, 1} = '10x V';
%         voltageChannels{end, 2} = '1x V';
%         voltageFactors{end + 1, 1} = 0.02;
%         voltageFactors{end, 2} = 1;
%         currentChannels{end + 1, 1} = 'Direct I';
%         currentFactors{end + 1, 1} = 1;
%         stimFactors(end + 1) = 10;         
% 
%      % MultiClamp
%         amplifiers{end + 1} = 'MultiClamp';
%         voltageChannels{end + 1, 1} = 'Scaled';
%         voltageChannels{end, 2} = 'Raw';    
%         voltageFactors{end + 1, 1} = 1;
%         voltageFactors{end, 2} = 1;
%         currentChannels{end + 1, 1} = 'Scaled';
%         currentChannels{end, 2} = 'Raw';    
%         currentFactors{end + 1, 1} = 1;
%         currentFactors{end, 2} = 1;
%         stimFactors(end + 1) = 50;        

    % other channel types
        otherChannels{end + 1} = 'Disabled';
        otherChannelFactors{end + 1} = nan;
        otherChannels{end + 1} = 'Field 100x V';
        otherChannelFactors{end + 1} = .01;
        otherChannels{end + 1} = 'Field 1000x V';
        otherChannelFactors{end + 1} = .001;
        otherChannels{end + 1} = 'Field 10 000x V';
        otherChannelFactors{end + 1} = .0001; 
        otherChannels{end + 1} = 'Unscaled';
        otherChannelFactors{end + 1} = 1;        


    % set these values into the preferences
        if ispref('amplifiers', 'amplifiers')
            answer = questdlg('Overwrite existing amplifiers?', 'Amps Already Present', 'Yes', 'Cancel', 'Yes');
            if ~strcmp(answer, 'Yes')
                warning('Failed to write amplifiers')
				return
            end
        end

        setpref('amplifiers', 'amplifiers', amplifiers)
        setpref('amplifiers', 'voltageChannels', voltageChannels);
        setpref('amplifiers', 'voltageFactors', voltageFactors);
        setpref('amplifiers', 'currentChannels', currentChannels);
        setpref('amplifiers', 'currentFactors', currentFactors);
        setpref('amplifiers', 'stimFactors', stimFactors);
        setpref('amplifiers', 'otherChannels', otherChannels);
        setpref('amplifiers', 'otherChannelFactors', otherChannelFactors);
        setpref('amplifiers', 'gainNames', {'1x', '2x', '5x', '10x', '20x', '50x', '100x'})
        setpref('amplifiers', 'gainScales', [1 .5 .2 .1 .05 .02 .01]); % multiplier of any external filter            
        disp('Amplifiers set')
        
% set some harware preferences
    setpref('itc18', 'rangeNames', {'±1 Volt', '±2 Volts FS', '±5 Volts FS', '±10 Volts FS'});
    setpref('itc18', 'rangeScales', [.03125 .06250 .15625 .3125]); % mV / point with setRange of [1 2 5 10] V full sweep    