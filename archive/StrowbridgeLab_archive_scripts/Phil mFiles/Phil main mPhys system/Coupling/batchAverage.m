%search through specified directory and generate raster plots of spiking
%for any that demonstrate spikes in more than one cell

function batchAverage(directory)
warning off

% set up some constants
pointsPerMs = 5;
stepLength = 10; % ms
stepGap = pointsPerMs * 60; % ms
baselineSize = pointsPerMs * 200; % ms length in which to look for change
maxHits = 150; % maximum number of hits on any connections to analyse
windowSize = pointsPerMs * 6; % ms
windowDelay = pointsPerMs * 10; % ms
spikeDelay = pointsPerMs * 5; % ms after the end of a step that a spike can be detected (should encompass falling side of spike)
savedChannels = [];
PSPdata = [];

if nargin < 1
    directory = uigetdir('','Select directory in which to analyze data files')
end
if directory == 0
    error('Invalid Directory');
end

% setup excel for archiving data
    file = [directory '\Summary.xls'];
    sheet = 'Summary';
    try
        Excel = actxserver('Excel.Application');

    catch
        disp('error writing to data file');
        return;
    end

    try
        if ~exist(file,'file')
            % Create new workbook.  

            %This is in place because in the presence of a Google Desktop
            %Search installation, calling Add, and then SaveAs after adding data,
            %to create a new Excel file, will leave an Excel process hanging.  
            %This workaround prevents it from happening, by creating a blank file,
            %and saving it.  It can then be opened with Open.
            ExcelWorkbook = Excel.workbooks.Add;
            ExcelWorkbook.SaveAs(file,1);
            ExcelWorkbook.Close(false);
        end

        %Open file
        ExcelWorkbook = Excel.workbooks.Open(file);

        try % select region.
            % Activate indicated worksheet.
            activate_sheet(Excel,sheet);

            % Write column headers
            Select(Range(Excel,sprintf('%s','A1:A1')));
            set(Excel.selection,'Value', {'Path'});
            Select(Range(Excel,sprintf('%s','B1:B1')));
            set(Excel.selection,'Value', {'Stim'});
            Select(Range(Excel,sprintf('%s','C1:C1')));
            set(Excel.selection,'Value', {'To'});
            Select(Range(Excel,sprintf('%s','D1:D1')));
            set(Excel.selection,'Value', {'Blank'});
            Select(Range(Excel,sprintf('%s','E1:E1')));
            set(Excel.selection,'Value', {'Peak / RMS'});
            Select(Range(Excel,sprintf('%s','F1:F1')));            
            set(Excel.selection,'Value', {'Difference'});       
            Select(Range(Excel,sprintf('%s','G1:G1')));
            set(Excel.selection,'Value', {'P-Value'});   
            Select(Range(Excel,sprintf('%s','H1:H1')));
            set(Excel.selection,'Value', {'NumEpisodes'});        
            Select(Range(Excel,sprintf('%s','I1:I1')));
            set(Excel.selection,'Value', {'p<0.05'});     
            Select(Range(Excel,sprintf('%s','J1:J1')));
            set(Excel.selection,'Value', {'p<0.01'});     
            Select(Range(Excel,sprintf('%s','K1:K1')));
            set(Excel.selection,'Value', {'p<0.001'});     
            Select(Range(Excel,sprintf('%s','L1:L1')));
            set(Excel.selection,'Value', {'p<0.0001'});                 
        catch % Throw data range error.
            error('MATLAB:xlswrite:SelectDataRange',lasterr);
        end

    catch
        Excel.Quit;
        delete(Excel);                 % Terminate Excel server.
    end                

%if cancel was pressed then do nothing, else
if directory ~= 0
    %set up a log file to keep track of what happens
    logFID = fopen(strcat(directory, '\logFile.dat'),'w');
    
    % write into the log file some info about the run
    fprintf(logFID, 'Run of %s\n', directory);
    fprintf(logFID, 'Started on %s on %s\n', datestr(now,0), getenv('computername'));  
    fprintf(logFID, 'With stepLength = %1.1f ms, stepGap = %1.0f points, baseline size is %1.0f points, max hits is %1.0f\n', stepLength, stepGap, baselineSize, maxHits);
    fprintf(logFID, 'Window size is %1.0f points, window delay is %1.0f points, spike delay is %1.0f points\n', windowSize, windowDelay, spikeDelay);
    fprintf(logFID, 'Also, batchAverage was copied into this folder at the start of the run.\n\n\n');

    % copy over the pertinent files into the folder
    copyfile(which('batchAverage'), [directory '\batchAverage.m']);
    
    %set up variable to contain results data
    numRows = 1;

    dirStack{1} = directory;
    dirPointer = 1;
    while dirPointer <= numel(dirStack)      
        %generate a list of all directories in the current directory
        currentDir = dirStack{dirPointer};
        tempDir = dir(currentDir);
        [indices indices] = sort([tempDir.datenum]);
        tempDir = tempDir(indices);
        dirStack = [dirStack; cellfun(@(x) [currentDir filesep x], {tempDir([tempDir.isdir] & ~strcmp({tempDir.name}, '.') & ~strcmp({tempDir.name}, '..')).name}', 'uniformOutput', false)];
        
        %check all files in current directory
        fileList = {tempDir(~cat(2, tempDir.isdir) & (cellfun(@(x) ~isempty(x), strfind({tempDir.name}, '.mat')) | cellfun(@(x) ~isempty(x), strfind({tempDir.name}, '.dat'))) & ~strcmp('logFile.dat', {tempDir.name})).name};

        if numel(fileList) > 0
            disp(['looking at ' currentDir]) 
        end
        
        for q = 1:numel(fileList)
            cellName = fileList{q}(1:find(fileList{q} == 'S', 1, 'last') - 2);
            
            %load file
            zData.protocol = readTrace([currentDir filesep fileList{q}], 1);
            if isempty(zData.protocol)
                fprintf(logFID, '%s\n', ['*****Error in file: ' currentDir filesep fileList{q}]);  
                continue
            end
            
            % check to see if this is a coupling type protocol
            for ampIndex = 1:sum(cell2mat(zData.protocol.ampEnable))
                [stims stimLength channels] = findSteps(zData.protocol);                
                if isempty(savedChannels)
                    numProcessed = zeros(4, 8);
                    PSPdata = zeros(4, 8, baselineSize + stepLength * pointsPerMs + stepGap + 1);
                end
                if ~isempty(stimLength) && stimLength == stepLength
                    % looks like a two pulse protocol
                    try
                        stims = stims .* pointsPerMs;
                        stimLength = stimLength * pointsPerMs;
                        
                        zData = readTrace([currentDir, '\', fileList{q}]);
                        if numel(channels) < numel(savedChannels)
                            % an amp was turned off so realign the data
                            newStatus = [];
                            for i = 1:length(channels)
                                tempChannel = find(savedStims == stims(i * 2));
                                if ~isempty(tempChannel)
                                    newStatus(end + 1) = tempChannel / 2;
                                else
                                    newStatus = [];
                                    break
                                end
                            end
                            numProcessed = numProcessed(newStatus(newStatus <= size(numProcessed, 1)),sort([newStatus(newStatus * 2 <= size(PSPdata, 2)) * 2 newStatus(newStatus * 2 - 1 <= size(PSPdata, 2)) * 2 - 1]));     
                            PSPdata = PSPdata(newStatus(newStatus <= size(PSPdata, 1)), sort([newStatus(newStatus * 2 <= size(PSPdata, 2)) * 2 newStatus(newStatus * 2 - 1 <= size(PSPdata, 2)) * 2 - 1]), :);   
                        end
                        
                        % find spikes
                        for cellIndex = 1:length(channels)
                            spikes{cellIndex} = detectSpikes(zData.traceData(:, channels(cellIndex)));
                        end
                        
                        numProcessed(5, 10) = 0; % grow it out beyond what it ought to be to avoid out of bounds errors
                        % look for coupling
                        for preIndex = 1:size(channels, 2)
                            for postIndex = 1:size(channels, 2)
                                if ~(preIndex == postIndex) && mean(zData.traceData(1:100, channels(postIndex))) > -95% don't look for stimuli onto self
                                    % do first AP
                                    if numProcessed(postIndex, preIndex * 2 - 1) < maxHits && sum(spikes{preIndex} >= stims(preIndex * 2 - 1) & spikes{preIndex} <= stims(preIndex * 2 - 1) + stimLength + spikeDelay) == 1 && sum(spikes{postIndex} >= stims(preIndex * 2 - 1) - baselineSize & spikes{postIndex} <= stims(preIndex * 2 - 1) + 2 * stepLength + stepGap + baselineSize) == 0 % have we looked at too many, is there a spike in the presynaptic cell, are there no spikes in the postsynaptic window
                                        % increment the number of episodes
                                        numProcessed(postIndex, preIndex * 2 - 1) = numProcessed(postIndex, preIndex * 2 - 1) + 1;

                                        % set pre/post-spike data
                                        PSPdata(postIndex, preIndex * 2 - 1, :) = (numProcessed(postIndex, preIndex * 2 - 1) - 1) / numProcessed(postIndex, preIndex * 2 - 1) * squeeze(PSPdata(postIndex, preIndex * 2 - 1, :)) + zData.traceData(spikes{preIndex}(spikes{preIndex} >= stims(preIndex * 2 - 1) & spikes{preIndex} <= stims(preIndex * 2 - 1) + stimLength + spikeDelay) + (-baselineSize:stepLength * pointsPerMs + stepGap), channels(postIndex)) / numProcessed(postIndex, preIndex * 2 - 1);
                                    end
                                    % do second AP
                                    if numProcessed(postIndex, preIndex * 2) < maxHits && sum(spikes{preIndex} >= stims(preIndex * 2) & spikes{preIndex} <= stims(preIndex * 2) + stimLength + spikeDelay) == 1 && sum(spikes{postIndex} >= stims(preIndex * 2) - baselineSize & spikes{postIndex} <= stims(preIndex * 2) + 2 * stepLength + stepGap + baselineSize) == 0 % have we looked at too many, is there a spike in the presynaptic cell, are there no spikes in the postsynaptic window
                                        % increment the number of episodes
                                        numProcessed(postIndex, preIndex * 2) = numProcessed(postIndex, preIndex * 2) + 1;

                                        % set pre/post-spike data
                                        PSPdata(postIndex, preIndex * 2, :) = (numProcessed(postIndex, preIndex * 2) - 1) / numProcessed(postIndex, preIndex * 2) * squeeze(PSPdata(postIndex, preIndex * 2, :)) + zData.traceData(spikes{preIndex}(spikes{preIndex} >= stims(preIndex * 2) & spikes{preIndex} <= stims(preIndex * 2) + stimLength + spikeDelay) + (-baselineSize:stepLength * pointsPerMs + stepGap), channels(postIndex)) / numProcessed(postIndex, preIndex * 2);
                                    end                                    
                                end
                            end
                        end
                        
                        savedChannels = channels;
                        savedStims = stims;
                    catch
                        whoops = lasterror;
                        outError = '*****Error:';
                        for errorIndex = 1:numel(whoops.stack)
                           outError = [outError ' in ' whoops.stack(errorIndex).name ' at line ' num2str(whoops.stack(errorIndex).line) ';'];
                        end
                        fprintf(logFID, '%s\n %s\n', [outError ' File: ' currentDir filesep fileList{q}, whoops.message], char(13));  
                    end
                    break
                 end
            end
            if q == numel(fileList) || ~strcmp(fileList{q + 1}(1:find(fileList{q + 1} == 'S', 1, 'last') - 2), cellName)
                numRows = numRows + 1;
                                
                if size(PSPdata, 1) >= numel(channels) && size(PSPdata, 2) >= 2* numel(channels) && nnz(PSPdata)
                    % write data
                    for j = 1:size(PSPdata, 1)
                        for i = 1:size(PSPdata, 2)
                            if any(PSPdata(j, i, :))
                                baselineData = squeeze(PSPdata(j, i, 1:baselineSize));
                                peakData = mean(squeeze(PSPdata(j, i, baselineSize + windowDelay + windowSize)));
                                [h, significance] = ttest(baselineData, peakData);
                                
                                % write cell name
                                Select(Range(Excel,sprintf('%s',['A' num2str(numRows) ':A' num2str(numRows)])));
                                set(Excel.selection, 'Value', mat2cell([currentDir '\' cellName]));                                   

                                % write from
                                Select(Range(Excel,sprintf('%s',['B' num2str(numRows) ':B' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(i));

                                % write to
                                Select(Range(Excel,sprintf('%s',['C' num2str(numRows) ':C' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(j));

                                % write SNR
                                Select(Range(Excel,sprintf('%s',['E' num2str(numRows) ':E' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(peakData - mean(baselineData) / sqrt(sum(baselineData.^2)/length(baselineData))));  

                                % write Difference
                                Select(Range(Excel,sprintf('%s',['F' num2str(numRows) ':F' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(peakData - mean(baselineData)));                                       
                                
                                % write P-value          
                                Select(Range(Excel,sprintf('%s',['G' num2str(numRows) ':G' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(significance));           

                                % write numEpisodes          
                                Select(Range(Excel,sprintf('%s',['H' num2str(numRows) ':H' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(j, i))); 

                                % write format determiner          
                                Select(Range(Excel,sprintf('%s',['I' num2str(numRows) ':I' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(G' num2str(numRows) '<0.05,IF(F' num2str(numRows) '>0,1,-1),0)']); 

                                % write format determiner           
                                Select(Range(Excel,sprintf('%s',['J' num2str(numRows) ':J' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(G' num2str(numRows) '<0.01,IF(F' num2str(numRows) '>0,1,-1),0)']); 

                                % write format determiner           
                                Select(Range(Excel,sprintf('%s',['K' num2str(numRows) ':K' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(G' num2str(numRows) '<0.001,IF(F' num2str(numRows) '>0,1,-1),0)']); 

                                % write format determiner           
                                Select(Range(Excel,sprintf('%s',['L' num2str(numRows) ':L' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(G' num2str(numRows) '<0.0001,IF(F' num2str(numRows) '>0,1,-1),0)']); 
                                                                
                                % write episode file
                                % startingValues contains [offset deltaV p_value numEpisodes winners AP#]
                                zData.protocol.startingValues = [mean(baselineData) peakData - mean(baselineData) significance numProcessed(j, i) (significance < .01 && numProcessed(j, i) > 50 && abs(peakData - mean(baselineData)) > .05) ~mod(i, 2) + 1 ];
                                if mod(i, 2)
                                    zData.protocol.channelNames = {[cellName ' from stim ' sprintf('%1.0f', i) ' on cell ' sprintf('%1.0f', j) ', AP1']};
                                else
                                    zData.protocol.channelNames = {[cellName ' from stim ' sprintf('%1.0f', i) ' on cell ' sprintf('%1.0f', j) ', AP2']};    
                                end                  
                                zData.protocol.sweepWindow = size(PSPdata, 3) / pointsPerMs;
                                traceData = squeeze(PSPdata(j,i,:));
                                protocol = zData.protocol;
                                save([directory '\STA.' datestr(clock, 'ddmmmyy') '.S1.E' sprintf('%1.0f', numRows) '.mat'], 'traceData', 'protocol');
                                
                                numRows = numRows + 1;                                  
                            end
                        end
                    end
                else
                    fprintf(logFID, '%s\n', strcat('No Appropriate Episodes for: ', currentDir, '\', cellName));
                end
                fprintf(logFID, '%s\n', strcat('Completed Analysis for: ', currentDir, '\', cellName));
                savedChannels = [];
                PSPdata = [];
            end
        end % for q = 1:numel(fileList)
        dirPointer = dirPointer + 1;
    end  % while dirPointer <= numel(dirStack) 
end

%close log file
fclose(logFID);

%close excel connection
ExcelWorkbook.Save
ExcelWorkbook.Close(false)  % Close Excel workbook.
Excel.Quit;

function message = activate_sheet(Excel,Sheet)
% Activate specified worksheet in workbook.

% Initialise worksheet object
WorkSheets = Excel.sheets;
message = struct('message',{''},'identifier',{''});

% Get name of specified worksheet from workbook
try
    TargetSheet = get(WorkSheets,'item',Sheet);
catch
    % Worksheet does not exist. Add worksheet.
    TargetSheet = addsheet(WorkSheets,Sheet);
    warning('MATLAB:xlswrite:AddSheet','Added specified worksheet.');
    if nargout > 0
        [message.message,message.identifier] = lastwarn;
    end
end

% activate worksheet
Activate(TargetSheet);

function newsheet = addsheet(WorkSheets,Sheet)
% Add new worksheet, Sheet into worsheet collection, WorkSheets.

if isnumeric(Sheet)
    % iteratively add worksheet by index until number of sheets == Sheet.
    while WorkSheets.Count < Sheet
        % find last sheet in worksheet collection
        lastsheet = WorkSheets.Item(WorkSheets.Count);
        newsheet = WorkSheets.Add([],lastsheet);
    end
else
    % add worksheet by name.
    % find last sheet in worksheet collection
    lastsheet = WorkSheets.Item(WorkSheets.Count);
    newsheet = WorkSheets.Add([],lastsheet);
end
% If Sheet is a string, rename new sheet to this string.
if ischar(Sheet)
    set(newsheet,'Name',Sheet);
end