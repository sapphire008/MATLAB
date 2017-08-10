% looks through coupling traces for the following characteristics:
%   Input Resistance (for largest hyperpolarizing step of at least 3 secs for
% which the deflection is at least 5mV and the membrane gets to this level
% or below within the first 30% of the step)
%   Sag (the ratio of the deflection to the maximum deflection achieved in
% the first third of a hyperpolarizing step)
%   
function batchClassification(directory)
warning off

% set up some constants
maxAmps = 4;
stepLength = 10; % ms
stepGap = 60; % ms
charStep = 3000; % ms length of cell characterization step

if nargin < 1
    directory = uigetdir('','Select directory in which to analyze data files')
end

if directory == 0
    error('Invalid Directory');
end

%set up results folder for results
analysisDir = strcat(directory, '\Analysis');
mkdir(directory, 'Analysis');

%% setup excel for archiving data
    file = [analysisDir '\Summary.xls'];
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
            set(Excel.selection,'Value',mat2cell('Path'));
            Select(Range(Excel,sprintf('%s','B1:B1')));
            set(Excel.selection,'Value',mat2cell('Cell'));  
            Select(Range(Excel,sprintf('%s','C1:C1')));
            set(Excel.selection,'Value',mat2cell('IN Prob'));     
            Select(Range(Excel,sprintf('%s','D1:D1')));
            set(Excel.selection,'Value',mat2cell('Mean Spike Time'));     
            Select(Range(Excel,sprintf('%s','E1:E1')));
            set(Excel.selection,'Value',mat2cell('First Burst ISI slope'));   
            Select(Range(Excel,sprintf('%s','F1:F1')));
            set(Excel.selection,'Value',mat2cell('Fast AHP Slope'));  
            Select(Range(Excel,sprintf('%s','G1:G1')));
            set(Excel.selection,'Value',mat2cell('AP Width'));   
            Select(Range(Excel,sprintf('%s','H1:H1')));
            set(Excel.selection,'Value',mat2cell('CV2'));     
            Select(Range(Excel,sprintf('%s', 'I1:I1')));
            set(Excel.selection,'Value',mat2cell('CV2, 5 spikes'));
            Select(Range(Excel,sprintf('%s', 'J1:J1')));
            set(Excel.selection,'Value',mat2cell('CV2, 10 spikes'));            
            Select(Range(Excel,sprintf('%s', 'K1:K1')));
            set(Excel.selection,'Value',mat2cell('CV2, 25 spikes'));
            Select(Range(Excel,sprintf('%s', 'L1:L1')));
            set(Excel.selection,'Value',mat2cell('Slope spikes'));
            Select(Range(Excel,sprintf('%s', 'M1:M1')));
            set(Excel.selection,'Value',mat2cell('Slope Time'));
            Select(Range(Excel,sprintf('%s', 'N1:N1')));
            set(Excel.selection,'Value',mat2cell('Num APs'));
            Select(Range(Excel,sprintf('%s', 'O1:O1')));
            set(Excel.selection,'Value',mat2cell('Num APs in 500 ms'));            
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
    logFID = fopen(strcat(analysisDir, '\logFile.dat'),'w');

    % write into the log file some info about the run
    fprintf(logFID, 'Run of %s\n', directory);
    fprintf(logFID, 'Started on %s on %s\n', datestr(now,0), getenv('computername'));  
    fprintf(logFID, 'With maxAmps = %0.0f, stepLength = %1.1f ms, stepGap = %1.1f ms, charStep = %1.1f ms\n', maxAmps, stepLength, stepGap, charStep);
    fprintf(logFID, 'Also, batchClassification was copied into this folder at the start of the run.\n\n\n');

    % copy over the pertinent files into the folder
    copyfile(which('batchClassification'), [analysisDir '\batchClassification.m']);
    
    %set up variable to contain results data
    numRows = 1;
    
    dirStack{1} = directory;
    dirPointer = 1;
    while dirPointer <= numel(dirStack)    
        %generate a list of all directories in the current directory
        currentDir = dirStack{dirPointer};
        tempDir = dir(currentDir);
        whichFiles = find(cat(2,tempDir.isdir));
        for q = 1:size(whichFiles, 2)
            tempFile = tempDir(whichFiles(q)).name;
            if tempFile(1,1) ~= '.' && length(strfind('Analysis', tempFile(1,:))) < 1  %not a folder we created
                dirStack{end + 1} = [currentDir filesep tempFile];
            end
        end
        
        %check all files in current directory
        fileList = {tempDir(~cat(2, tempDir.isdir) & (cellfun(@(x) ~isempty(x), strfind({tempDir.name}, '.mat')) | cellfun(@(x) ~isempty(x), strfind({tempDir.name}, '.dat'))) & ~strcmp('logFile.dat', {tempDir.name})).name};

        if numel(fileList) > 0
            disp(['looking at ' currentDir]) 
        end
%         cellRin = nan(1,maxAmps);
%         cellSag = nan(1,maxAmps);
%         cellMeanVariance = nan(1,maxAmps);         
        cellINprob = nan(10,maxAmps);
        cellMeanSpikeTime = nan(10,maxAmps);
        cellIsiSlope = nan(10,maxAmps);        
        cellFastAHP = nan(10,maxAmps);
        cellAPwidth = nan(10,maxAmps);
        cellClustering = nan(10,maxAmps);
        cellClustering5 = cellClustering;
        cellClustering10 = cellClustering;
        cellClustering25 = cellClustering;
        cellSlopeSpikes = nan(10,maxAmps);
        cellSlopeTime = nan(10,maxAmps);    
        cellNumAps = nan(10,maxAmps);
        cellNumApsEarly = cellNumAps;
%         cellISICV = nan(10,maxAmps);
%         cellMaxDeflection = zeros(1,maxAmps); % keeps track of the largest hyperpolarizing step that has been given to a cell
        cellNumPulses = zeros(1,maxAmps); % keeps track of how many APs have had their width measured
        
        for q = 1:numel(fileList)
            cellName = fileList{q}(1:find(fileList{q} == 'S', 1, 'last') - 2);
            
            %load file
            zData.protocol = readTrace([currentDir filesep fileList{q}], 'infoOnly');
            if isempty(zData.protocol)
                fprintf(logFID, '%s\n %s', ['*****Error in file: ' currentDir '\' fileList{q}], lasterr);  
                continue
            end

            % check to see if this is a coupling type protocol
            for ampIndex = 1:sum(cell2mat(zData.protocol.ampEnable))
                currentStims = findSteps(zData.protocol, ampIndex);
                if size(currentStims, 1) == 4 && diff(currentStims(1:2,1)) == stepLength && diff(currentStims([1 3], 1)) == stepGap
%                     % looks like a two pulse protocol
%                     try
%                         if ~all(cellNumPulses(logical(cell2mat(zData.protocol.ampEnable))) > 9)
%                             zData = readTrace([currentDir filesep fileList{q}]);
%                             for ampIndex = 1:numel(zData.protocol.ampType)
%                                 currentStims = findSteps(zData.protocol, ampIndex);                                
%                                 if size(currentStims, 1) == 4 && cellNumPulses(ampIndex) < 9 && mean(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V'))) < -10 % to make sure that the cell isn't toasted
%                                     spikeWidth = apWidthHM(zData.traceData(currentStims(1,1) * 1000 / zData.protocol.timePerPoint + 2:currentStims(4,1) * 1000 / zData.protocol.timePerPoint + 10, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
%                                     if ~isempty(spikeWidth) && numel(spikeWidth) == 2
%                                         cellNumPulses(ampIndex) = cellNumPulses(ampIndex) + 1;
%                                         cellAPwidth(cellNumPulses(ampIndex), ampIndex) = spikeWidth(1) * zData.protocol.timePerPoint / 1000;
%                                     end
%                                 end
%                             end
%                         end                        
%                     catch
%                         whoops = lasterror;
%                         outError = '*****Error:';
%                         for errorIndex = 1:numel(whoops.stack)
%                            outError = [outError ' in ' whoops.stack(errorIndex).name ' at line ' num2str(whoops.stack(errorIndex).line) ';'];
%                         end
%                         fprintf(logFID, '%s\n %s', [outError ' File: ' currentDir filesep fileList{q}, whoops.message], char(13));  
%                     end
                    break
                elseif size(currentStims, 1) == 2 && diff(currentStims(1:2,1)) >= charStep
                    % looks like a cell characterization protocol
                    try
                        zData = readTrace([currentDir filesep fileList{q}]);                    
                        if diff(currentStims(1:2,2)) < 0
                            % looks like a spike-inducer
                            for ampIndex = 1:numel(zData.protocol.ampType)
                                if zData.protocol.ampEnable{ampIndex} && zData.protocol.ampStimEnable{ampIndex}
                                    tempSpikes = apHeight(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                    if length(tempSpikes) > 4 %&& min(tempSpikes) > .5 * max(tempSpikes)
                                        tempLength = find(~isnan(cellFastAHP(:, ampIndex)), 1, 'last') + 1;
                                        if isempty(tempLength)
                                            tempLength = 1;
                                        end
                                        [tempData cellMeanSpikeTime(tempLength, ampIndex) cellIsiSlope(tempLength, ampIndex) cellSlopeSpikes(tempLength, ampIndex) cellSlopeTime(tempLength, ampIndex)] = fastAHPSlope2(zData.traceData(currentStims(1, 1) * 1000 / zData.protocol.timePerPoint:currentStims(2,1) * 1000 / zData.protocol.timePerPoint, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                        cellFastAHP(tempLength, ampIndex) = nanmedian(tempData);
                                        
                                        spikeTimes = detectSpikes(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')));
                                        spikeTimes = spikeTimes(~isnan(spikeTimes));
%                                         if any(spikeTimes < 12500) && any(spikeTimes >= 12500)
                                            cellClustering(tempLength, ampIndex) = CV2(spikeTimes, 1);
                                            cellINprob(tempLength, ampIndex) = burstingProbability(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000, 60);                                        
%                                         end
%                                         if numel(spikeTimes) > 4
%                                             cellClustering5(tempLength, ampIndex) = CV2(spikeTimes(1:5), 1);
%                                         end
%                                         if numel(spikeTimes) > 9
%                                             cellClustering5(tempLength, ampIndex) = CV2(spikeTimes(1:10), 1);
%                                         end
%                                         if numel(spikeTimes) > 24
%                                             cellClustering5(tempLength, ampIndex) = CV2(spikeTimes(1:25), 1);
%                                         end    
%                                         whichStims = findSteps(zData.protocol, ampIndex);
%                                         cellNumAps(tempLength, ampIndex) = numel(spikeTimes) ./ diff(whichStims(1:2,2));
%                                         cellNumApsEarly(tempLength, ampIndex) = sum(spikeTimes < 2500) ./ diff(whichStims(1:2,2));
                                    end
                                end
                            end
                        elseif diff(currentStims(1:2,2)) > 0
                           % looks like an input resistance test
%                            for ampIndex = 1:numel(zData.protocol.ampType)
%                                tempData = Rin(zData.traceData, zData.protocol, ampIndex);
%                                tempSag = Sag(zData.traceData, zData.protocol, ampIndex);                               
%                                if ~isnan(tempData) && diff(currentStims(1:2,2)) > cellMaxDeflection(ampIndex)
%                                    cellRin(ampIndex) = tempData;
%                                    cellSag(ampIndex) = tempSag;
%                                    cellMaxDeflection(ampIndex) = diff(currentStims(1:2,2));
%                                end
%                            end
%                         else
%                             % looks like a great place to check the mean variance and PSP size
%                             for ampIndex = 1:numel(zData.protocol.ampType)
%                                 if zData.protocol.ampEnable{ampIndex} && zData.protocol.ampStimEnable{ampIndex}
%                                     cellMeanVariance(ampIndex) = meanVariance(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), 5000, .5);
%                                 end
%                             end
                        end
                        break
                    catch
                        whoops = lasterror;
                        outError = '*****Error:';
                        for errorIndex = 1:numel(whoops.stack)
                           outError = [outError ' in ' whoops.stack(errorIndex).name ' at line ' num2str(whoops.stack(errorIndex).line) ';'];
                        end
                        fprintf(logFID, '%s\n %s', [outError ' File: ' currentDir filesep fileList{q}], whoops.message, char(13));                          
                    end
                end
            end
            if q == numel(fileList) || ~strcmp(fileList{q + 1}(1:find(fileList{q + 1} == 'S', 1, 'last') - 2), cellName)
                fprintf(logFID, '%s\n', strcat('Completed Analysis for: ', currentDir, '\', cellName));                
                whichAmps = find(logical(cell2mat(zData.protocol.ampEnable)));
                
                numRows = numRows + 1;

                % write data
                ampCount = 0;
                for j = whichAmps  
                    ampCount = ampCount + 1;
                    % write cell path
                    Select(Range(Excel,sprintf('%s',['A' num2str(numRows) ':A' num2str(numRows)])));
                    set(Excel.selection, 'Value', mat2cell([currentDir '\' cellName]));     
                    
                    % write cell number
                    Select(Range(Excel,sprintf('%s',['B' num2str(numRows) ':B' num2str(numRows)])));
                    set(Excel.selection, 'Value', num2str(ampCount));                         

                    % write cell IN prob
                    Select(Range(Excel,sprintf('%s',['C' num2str(numRows) ':C' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmax(cellINprob(:,j))));                                 

                    % write cell mean spike time
                    Select(Range(Excel,sprintf('%s',['D' num2str(numRows) ':D' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellMeanSpikeTime(:,j))));                                 

                    % write cell ISI slope
                    Select(Range(Excel,sprintf('%s',['E' num2str(numRows) ':E' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellIsiSlope(:,j))));                                 

                    % write cell fast AHP
                    Select(Range(Excel,sprintf('%s',['F' num2str(numRows) ':F' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmax(cellFastAHP(:,j))));                                   

                    % write cell AP width
                    Select(Range(Excel,sprintf('%s',['G' num2str(numRows) ':G' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellAPwidth(:,j))));                                

                    % write cell clustering
                    Select(Range(Excel,sprintf('%s',['H' num2str(numRows) ':H' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellClustering(:, j))));   

                    % write cell clustering
                    Select(Range(Excel,sprintf('%s',['I' num2str(numRows) ':I' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellClustering5(:, j)))); 

                    % write cell clustering
                    Select(Range(Excel,sprintf('%s',['J' num2str(numRows) ':J' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellClustering10(:, j)))); 

                    % write cell clustering
                    Select(Range(Excel,sprintf('%s',['K' num2str(numRows) ':K' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellClustering25(:, j)))); 
                    
                    whichSlope = find(cellIsiSlope(:,j) == nanmedian(cellIsiSlope(:,j)), 1, 'first');
                    if ~isempty(whichSlope)
                        % write cell ISI CV
                        Select(Range(Excel,sprintf('%s',['L' num2str(numRows) ':L' num2str(numRows)])));                                            
                        set(Excel.selection,'Value', num2str(cellSlopeSpikes(whichSlope, j)));                       

                        % write cell mean variance
                        Select(Range(Excel,sprintf('%s',['M' num2str(numRows) ':M' num2str(numRows)])));                                            
                        set(Excel.selection,'Value', num2str(cellSlopeTime(whichSlope, j)));  
                    end

                    % write num APs
                    Select(Range(Excel,sprintf('%s',['N' num2str(numRows) ':N' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellNumAps(:, j))));     
                    
                    % write num APs early
                    Select(Range(Excel,sprintf('%s',['O' num2str(numRows) ':O' num2str(numRows)])));                                            
                    set(Excel.selection,'Value', num2str(nanmedian(cellNumApsEarly(:, j))));  
                    
                    numRows = numRows + 1;                            
                end % for cell number     
%                 cellRin = nan(1,maxAmps);
%                 cellSag = nan(1,maxAmps);
%                 cellMeanVariance = nan(1, maxAmps);
                cellINprob = nan(10,maxAmps);
                cellMeanSpikeTime = nan(10,maxAmps);
                cellIsiSlope = nan(10, maxAmps);
                cellFastAHP = nan(10,maxAmps);
                cellAPwidth = nan(10,maxAmps);
                cellClustering = nan(10,maxAmps);
                cellClustering5 = cellClustering;
                cellClustering10 = cellClustering;
                cellClustering25 = cellClustering;                
                cellSlopeSpikes = nan(10,maxAmps);
                cellSlopeTime = nan(10,maxAmps);      
                cellNumAps = nan(10,maxAmps);
                cellNumApsEarly = cellNumAps;                
%                 cellISICV = nan(10,maxAmps);
%                 cellMaxDeflection = zeros(1,maxAmps); % keeps track of the largest hyperpolarizing step that has been given to a cell
                cellNumPulses = zeros(1,maxAmps); % keeps track of how many APs have had their width measured
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