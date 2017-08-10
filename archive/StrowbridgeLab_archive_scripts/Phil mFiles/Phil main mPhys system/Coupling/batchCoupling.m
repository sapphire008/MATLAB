%search through specified directory and generate raster plots of spiking
%for any that demonstrate spikes in more than one cell

function batchCoupling(directory)
warning off

% set up some constants
maxAmps = 4;
stepLength = 10; % ms
stepGap = 60; % ms
charStep = 3000; % ms length of cell characterization step
windowSize = 3.8; % ms length in which to look for PSPs
windowDelay = -0.2; % ms length to lag the PSP search window
couplingOptions = [0 1 1 1]; % [fitDecayRise, findPSPs, displayMatches, rezero] where fitDecay rise is:
% -1 don't even fit an alpha function to the PSP
%  0 fit an alpha function but no exponential to the decay
%  1 fit an alpha function and fit the decay with an exponential

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
            set(Excel.selection,'Value',mat2cell('From'));
            Select(Range(Excel,sprintf('%s','C1:C1')));
            set(Excel.selection,'Value',mat2cell('To'));
            Select(Range(Excel,sprintf('%s','D1:D1')));
            set(Excel.selection,'Value',mat2cell('First'));
            Select(Range(Excel,sprintf('%s','E1:E1')));
            set(Excel.selection,'Value',mat2cell('Second'));
            Select(Range(Excel,sprintf('%s','F1:F1')));            
            set(Excel.selection,'Value',mat2cell('Type'));
            Select(Range(Excel,sprintf('%s','G1:G1')));
            set(Excel.selection,'Value',mat2cell('Control'));
            Select(Range(Excel,sprintf('%s','H1:H1')));
            set(Excel.selection,'Value',mat2cell('Num Episodes Stim 1'));
            Select(Range(Excel,sprintf('%s','I1:I1')));
            set(Excel.selection,'Value',mat2cell('Num Episodes Stim 2'));
            Select(Range(Excel,sprintf('%s','J1:J1')));
            set(Excel.selection,'Value',mat2cell('Num Episodes Control'));            
            Select(Range(Excel,sprintf('%s','K1:K1')));
            set(Excel.selection,'Value',mat2cell('p ='));
            Select(Range(Excel,sprintf('%s','L1:L1')));
            set(Excel.selection,'Value',mat2cell('First Amp'));
            Select(Range(Excel,sprintf('%s','M1:M1')));
            set(Excel.selection,'Value',mat2cell('First Amp Err'));
            Select(Range(Excel,sprintf('%s','N1:N1')));
            set(Excel.selection,'Value',mat2cell('Second Amp'));
            Select(Range(Excel,sprintf('%s','O1:O1')));
            set(Excel.selection,'Value',mat2cell('Second Amp Err'));
            Select(Range(Excel,sprintf('%s','P1:P1')));
            set(Excel.selection,'Value',mat2cell('First Rise'));
            Select(Range(Excel,sprintf('%s','Q1:Q1')));
            set(Excel.selection,'Value',mat2cell('First Rise Err'));
            Select(Range(Excel,sprintf('%s','R1:R1')));
            set(Excel.selection,'Value',mat2cell('Second Rise'));
            Select(Range(Excel,sprintf('%s','S1:S1')));
            set(Excel.selection,'Value',mat2cell('Second Rise Err'));
            Select(Range(Excel,sprintf('%s','T1:T1')));
            set(Excel.selection,'Value',mat2cell('First Latency'));
            Select(Range(Excel,sprintf('%s','U1:U1')));
            set(Excel.selection,'Value',mat2cell('First Latency Err'));
            Select(Range(Excel,sprintf('%s','V1:V1')));
            set(Excel.selection,'Value',mat2cell('Second Latency'));
            Select(Range(Excel,sprintf('%s','W1:W1')));
            set(Excel.selection,'Value',mat2cell('Second Latency Err'));
            Select(Range(Excel,sprintf('%s','X1:X1')));
            set(Excel.selection,'Value',mat2cell('First Decay'));
            Select(Range(Excel,sprintf('%s','Y1:Y1')));
            set(Excel.selection,'Value',mat2cell('First Decay Err'));
            Select(Range(Excel,sprintf('%s','Z1:Z1')));
            set(Excel.selection,'Value',mat2cell('Second Decay'));
            Select(Range(Excel,sprintf('%s','AA1:AA1')));
            set(Excel.selection,'Value',mat2cell('Second Decay Err'));
            Select(Range(Excel,sprintf('%s','AB1:AB1')));            
            set(Excel.selection,'Value',mat2cell('First Succes Rate'));  
            Select(Range(Excel,sprintf('%s','AC1:AC1')));
            set(Excel.selection,'Value',mat2cell('Second Succes Rate'));    
            Select(Range(Excel,sprintf('%s','AD1:AD1')));
            set(Excel.selection,'Value',mat2cell('First Spike p'));    
            Select(Range(Excel,sprintf('%s','AE1:AE1')));
            set(Excel.selection,'Value',mat2cell('Second Spike p'));    
            Select(Range(Excel,sprintf('%s','AF1:AF1')));
            set(Excel.selection,'Value',mat2cell('p < 0.01'));    
            Select(Range(Excel,sprintf('%s','AG1:AG1')));
            set(Excel.selection,'Value',mat2cell('p < 0.0001'));       
            Select(Range(Excel,sprintf('%s','AH1:AH1')));
            set(Excel.selection,'Value',mat2cell('Pre IN Prob'));     
            Select(Range(Excel,sprintf('%s','AI1:AI1')));
            set(Excel.selection,'Value',mat2cell('Pre Rin'));     
            Select(Range(Excel,sprintf('%s','AJ1:AJ1')));
            set(Excel.selection,'Value',mat2cell('Pre Sag'));     
            Select(Range(Excel,sprintf('%s','AK1:AK1')));
            set(Excel.selection,'Value',mat2cell('Pre Fast AHP'));     
            Select(Range(Excel,sprintf('%s','AL1:AL1')));
            set(Excel.selection,'Value',mat2cell('Pre AP Width'));     
            Select(Range(Excel,sprintf('%s','AM1:AM1')));
            set(Excel.selection,'Value',mat2cell('Pre Single CV'));    
            Select(Range(Excel,sprintf('%s','AN1:AN1')));
            set(Excel.selection,'Value',mat2cell('Pre ISI CV'));     
            Select(Range(Excel,sprintf('%s','AO1:AO1')));
            set(Excel.selection,'Value',mat2cell('Post IN Prob'));     
            Select(Range(Excel,sprintf('%s','AP1:AP1')));
            set(Excel.selection,'Value',mat2cell('Post Rin'));     
            Select(Range(Excel,sprintf('%s','AQ1:AQ1')));
            set(Excel.selection,'Value',mat2cell('Post Sag'));   
            Select(Range(Excel,sprintf('%s','AR1:AR1')));
            set(Excel.selection,'Value',mat2cell('Post Fast AHP'));  
            Select(Range(Excel,sprintf('%s','AS1:AS1')));
            set(Excel.selection,'Value',mat2cell('Post AP Width'));   
            Select(Range(Excel,sprintf('%s','AT1:AT1')));
            set(Excel.selection,'Value',mat2cell('Post Single CV'));     
            Select(Range(Excel,sprintf('%s','AU1:AU1')));
            set(Excel.selection,'Value',mat2cell('Post ISI CV'));               
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
    fprintf(logFID, 'Window size is %1.1f ms, window delay is %1.1f ms, coupling options are [%s]\n', windowSize, windowDelay, num2str(couplingOptions));
    fprintf(logFID, 'Also, batchCoupling, setupCoupling, checkCoupling, detectPSPs, and detectSpikes were copied into this folder at the start of the run.\n\n\n');

    % copy over the pertinent files into the folder
    copyfile(which('batchCoupling'), [analysisDir '\batchCoupling.m']);
    copyfile(which('setupCoupling'), [analysisDir '\setupCoupling.m']);
    copyfile(which('checkCoupling'), [analysisDir '\checkCoupling.m']);
    copyfile(which('detectPSPs'), [analysisDir '\detectPSPs.m']);
    copyfile(which('detectSpikes'), [analysisDir '\detectSpikes.m']);
    
    %set up variable to contain results data
    numRows = 1;
    fileNames = '';
    dataVals = [];    
    
    dirStack{1} = directory;
    dirPointer = 1;
    while dirPointer <= numel(dirStack)    
        %generate a list of all directories in the current directory
        currentDir = dirStack{dirPointer};
        tempDir = dir(currentDir);
        [indices indices] = sort([tempDir.datenum]);
        tempDir = tempDir(indices);        
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
        cellRin = nan(1,maxAmps);
        cellSag = nan(1,maxAmps); 
        cellINprob = nan(10,maxAmps);
        cellFastAHP = nan(10,maxAmps);
        cellAPwidth = nan(10,maxAmps);
        cellClustering = nan(10,maxAmps);
        cellISICV = nan(10,maxAmps);
        cellMaxDeflection = zeros(1,maxAmps); % keeps track of the largest hyperpolarizing step that has been given to a cell
        cellNumPulses = zeros(1,maxAmps); % keeps track of how many APs have had their width measured
        couplingWindow = -1;
        
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
                    % looks like a two pulse protocol
                    try
                        couplingWindow = checkCoupling([currentDir filesep fileList{q}], windowSize, windowDelay, couplingOptions);
                        if ~all(cellNumPulses(logical(cell2mat(zData.protocol.ampEnable))) > 9)
                            zData = readTrace([currentDir filesep fileList{q}]);
                            for ampIndex = 1:numel(zData.protocol.ampType)
                                currentStims = findSteps(zData.protocol, ampIndex);                                
                                if ~isempty(whichChannel(zData.protocol, ampIndex, 'V')) && size(currentStims, 1) == 4 && cellNumPulses(ampIndex) < 9 && mean(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V'))) < -10 % to make sure that the cell isn't toasted
                                    spikeWidth = apWidthHM(zData.traceData(currentStims(1,1) * 1000 / zData.protocol.timePerPoint + 2:currentStims(4,1) * 1000 / zData.protocol.timePerPoint + 10, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                    if ~isempty(spikeWidth) && numel(spikeWidth) == 2
                                        cellNumPulses(ampIndex) = cellNumPulses(ampIndex) + 1;
                                        cellAPwidth(cellNumPulses(ampIndex), ampIndex) = spikeWidth(1) * zData.protocol.timePerPoint / 1000;
                                    end
                                end
                            end
                        end                        
                    catch
                        whoops = lasterror;
                        outError = '*****Error:';
                        for errorIndex = 1:numel(whoops.stack)
                           outError = [outError ' in ' whoops.stack(errorIndex).name ' at line ' num2str(whoops.stack(errorIndex).line) ';'];
                        end
                        fprintf(logFID, '%s\n %s', [outError ' File: ' currentDir filesep fileList{q}, whoops.message], char(13));  
                    end
                    break
                elseif size(currentStims, 1) == 2 && diff(currentStims(1:2,1)) >= charStep
                    % looks like a cell characterization protocol
                    try
                        zData = readTrace([currentDir filesep fileList{q}]);                    
                        if diff(currentStims(1:2,2)) < 0
                            % looks like a spike-inducer
                            for ampIndex = 1:numel(zData.protocol.ampType)
                                if zData.protocol.ampEnable{ampIndex} && zData.protocol.ampStimEnable{ampIndex} && ~isempty(whichChannel(zData.protocol, ampIndex, 'V'))
                                    tempSpikes = apHeight(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                    if length(tempSpikes) > 4 && min(tempSpikes) > .5 * max(tempSpikes)
                                        tempLength = find(~isnan(cellFastAHP(:, ampIndex)), 1, 'last') + 1;
                                        if isempty(tempLength)
                                            tempLength = 1;
                                        end
                                        tempData = fastAHP(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                        cellFastAHP(tempLength, ampIndex) = median(tempData(3:end - 1));
                                        
                                        cellINprob(tempLength, ampIndex) = burstingProbability(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                        cellClustering(tempLength, ampIndex) = CV2(detectSpikes(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V'))), 1);
                                        cellISICV(tempLength, ampIndex) = isiCv(zData.traceData(:, whichChannel(zData.protocol, ampIndex, 'V')), zData.protocol.timePerPoint / 1000);
                                    end
                                end
                            end
                        elseif diff(currentStims(1:2,2)) > 0
                           % looks like an input resistance test
                           for ampIndex = 1:numel(zData.protocol.ampType)
                               tempData = Rin(zData.traceData, zData.protocol, ampIndex);
                               tempSag = Sag(zData.traceData, zData.protocol, ampIndex);                               
                               if ~isnan(tempData) && diff(currentStims(1:2,2)) > cellMaxDeflection(ampIndex)
                                   cellRin(ampIndex) = tempData;
                                   cellSag(ampIndex) = tempSag;
                                   cellMaxDeflection(ampIndex) = diff(currentStims(1:2,2));
                               end
                           end
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
                whichAmps = logical(cell2mat(zData.protocol.ampEnable));
                cellRin = cellRin(:, whichAmps); 
                cellSag = cellSag(:, whichAmps); 
                cellINprob = cellINprob(:, whichAmps);
                cellClustering = cellClustering(:, whichAmps);
                cellISICV = cellISICV(:, whichAmps);
                cellFastAHP = cellFastAHP(:, whichAmps);
                cellAPwidth = cellAPwidth(:, whichAmps);                
                
                numRows = numRows + 1;
                if ~isempty(couplingWindow) && ishandle(couplingWindow) && size(get(couplingWindow, 'userData'), 2) == 6
                    userData = get(couplingWindow, 'userData');
                    PSPdata = userData{4};                    
                    numProcessed = userData{2};
                    numControlWindows = userData{6};

                    try
                        %write analysis to file
                        if size(PSPdata, 4) > 1
                            if ~isempty(currentDir(length(analysisDir) - 8:end))
                                mkdir(analysisDir, currentDir(length(analysisDir) - 8:end));
                            end
                            hgsave([analysisDir, '\', currentDir(length(analysisDir) - 8:end), '\', cellName, '.fig']);
                            fprintf(logFID, '%s\n', strcat('Completed Analysis for: ', currentDir, '\', cellName));
                        else
                            fprintf(logFID, '%s\n', strcat('Insufficient Hits for: ', currentDir, '\', cellName));
                        end
                    catch
                        fprintf(logFID, '%s\n %s\n', ['*****Error writing analysis file: ' currentDir filesep fileList{q}], lasterr);  
                    end 

                    % write data
                    for j = 1:size(PSPdata, 1)
                        for i = 1:2:(size(PSPdata, 2) - 2)                            
                            if ~isempty(find(PSPdata(j, i, 3, :) > 0 | PSPdata(j, i + 1, 3, :), 1)) % these are UP psps
                                % write cell name
                                Select(Range(Excel,sprintf('%s',['A' num2str(numRows) ':A' num2str(numRows)])));
                                set(Excel.selection, 'Value', mat2cell([currentDir '\' cellName]));    
                                
                                % write from
                                Select(Range(Excel,sprintf('%s',['B' num2str(numRows) ':B' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(round(i / 2 + .1)));

                                % write to
                                Select(Range(Excel,sprintf('%s',['C' num2str(numRows) ':C' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(j));

                                % first                            
                                Select(Range(Excel,sprintf('%s',['D' num2str(numRows) ':D' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(length(find(PSPdata(j, i, 3, :) > 0))));

                                % second
                                Select(Range(Excel,sprintf('%s',['E' num2str(numRows) ':E' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(length(find(PSPdata(j, i + 1, 3, :) > 0))));

                                % write type
                                Select(Range(Excel,sprintf('%s',['F' num2str(numRows) ':F' num2str(numRows)])));            
                                set(Excel.selection,'Value', mat2cell('Up'));       

                                % write control          
                                Select(Range(Excel,sprintf('%s',['G' num2str(numRows) ':G' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(length(find(PSPdata(j, end, 3, :) > 0))));           
                                
                                % write numEpisodes First
                                Select(Range(Excel,sprintf('%s',['H' num2str(numRows) ':H' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(i))); 

                                % write numEpisodes Second  
                                Select(Range(Excel,sprintf('%s',['I' num2str(numRows) ':I' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(i + 1))); 
                                
                                % write numEpisodes Control         
                                Select(Range(Excel,sprintf('%s',['J' num2str(numRows) ':J' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(size(PSPdata, 2) - 1 + j))); 
                                
                                % write p value for the connection
                                try
                                    Select(Range(Excel,sprintf('%s',['K' num2str(numRows) ':K' num2str(numRows)])));            
                                    set(Excel.selection,'Value', num2str(chiTest([length(find(PSPdata(j, i, 3, :) > 0)) + length(find(PSPdata(j, i + 1, 3, :) > 0)) numProcessed(i) + numProcessed(i + 1); length(find(PSPdata(j, end, 3, :) > 0)) numProcessed(size(PSPdata, 2) - 1 + j) * numControlWindows])));                                    
                                catch
                                    fprintf(logFID, '%s\n %s\n', strcat('*****Error in chiTest: ', currentDir, '\', fileList(q,:)), lasterr);  
                                end
                                
                                % write stimStats   
                                stimData = stimStats(round(i / 2 + .1), j);
                                Select(Range(Excel,sprintf('%s',['L' num2str(numRows) ':L' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,1))); 
                                Select(Range(Excel,sprintf('%s',['M' num2str(numRows) ':M' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,2))); 
                                Select(Range(Excel,sprintf('%s',['N' num2str(numRows) ':N' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,3))); 
                                Select(Range(Excel,sprintf('%s',['O' num2str(numRows) ':O' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,4))); 
                                Select(Range(Excel,sprintf('%s',['P' num2str(numRows) ':P' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,5))); 
                                Select(Range(Excel,sprintf('%s',['Q' num2str(numRows) ':Q' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,6))); 
                                Select(Range(Excel,sprintf('%s',['R' num2str(numRows) ':R' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,7))); 
                                Select(Range(Excel,sprintf('%s',['S' num2str(numRows) ':S' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,8))); 
                                Select(Range(Excel,sprintf('%s',['T' num2str(numRows) ':T' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,9))); 
                                Select(Range(Excel,sprintf('%s',['U' num2str(numRows) ':U' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,10))); 
                                Select(Range(Excel,sprintf('%s',['V' num2str(numRows) ':V' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,11))); 
                                Select(Range(Excel,sprintf('%s',['W' num2str(numRows) ':W' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,12))); 
                                Select(Range(Excel,sprintf('%s',['X' num2str(numRows) ':X' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,13))); 
                                Select(Range(Excel,sprintf('%s',['Y' num2str(numRows) ':Y' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,14))); 
                                Select(Range(Excel,sprintf('%s',['Z' num2str(numRows) ':Z' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,15))); 
                                Select(Range(Excel,sprintf('%s',['AA' num2str(numRows) ':AA' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,16))); 
                                Select(Range(Excel,sprintf('%s',['AB' num2str(numRows) ':AB' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,17))); 
                                Select(Range(Excel,sprintf('%s',['AC' num2str(numRows) ':AC' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(1,18))); 

                                try % write first spike p value
                                    Select(Range(Excel,sprintf('%s',['AD' num2str(numRows) ':AD' num2str(numRows)])));            
                                    set(Excel.selection,'Value', num2str(chiTest([length(find(PSPdata(j, i, 3, :) > 0)) numProcessed(i); length(find(PSPdata(j, end, 3, :) > 0)) numProcessed(size(PSPdata, 2) - 1 + j) * numControlWindows])));
                                catch
                                    fprintf(logFID, '%s\n %s', ['*****Error in chiTest: ' currentDir filesep fileList{q}], lasterr);  
                                end   
                                
                                try % write second spike p value
                                    Select(Range(Excel,sprintf('%s',['AE' num2str(numRows) ':AE' num2str(numRows)])));            
                                    set(Excel.selection,'Value', num2str(chiTest([length(find(PSPdata(j, i + 1, 3, :) > 0)) numProcessed(i + 1); length(find(PSPdata(j, end, 3, :) > 0)) numProcessed(size(PSPdata, 2) - 1 + j) * numControlWindows])));
                                catch
                                    fprintf(logFID, '%s\n %s', ['*****Error in chiTest: ' currentDir filesep fileList{q}], lasterr);  
                                end         
                                
                                % write format determiner          
                                Select(Range(Excel,sprintf('%s',['AF' num2str(numRows) ':AF' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(AND((RC[-28]+RC[-27])*' sprintf('%1.1f', numControlWindows / 2) '>RC[-25],OR(RC[-21]<0.01,AND(NOT(ISBLANK(RC[-2])),RC[-2]<0.01),AND(NOT(ISBLANK(RC[-1])),RC[-1]<0.01))),1,0)']);
                                                                
                                % write format determiner           
                                Select(Range(Excel,sprintf('%s',['AG' num2str(numRows) ':AG' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(AND((RC[-29]+RC[-28])*' sprintf('%1.1f', numControlWindows / 2) '>RC[-26],OR(RC[-22]<0.0001,AND(NOT(ISBLANK(RC[-3])),RC[-3]<0.0001),AND(NOT(ISBLANK(RC[-2])),RC[-2]<0.0001))),1,0)']);

                                % write pre IN prob
                                Select(Range(Excel,sprintf('%s',['AH' num2str(numRows) ':AH' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(min(cellINprob(cellINprob(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                 

                                % write pre Rin
                                Select(Range(Excel,sprintf('%s',['AI' num2str(numRows) ':AI' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellRin(:,round(i / 2 + .1))));                                 

                                % write pre Sag
                                Select(Range(Excel,sprintf('%s',['AJ' num2str(numRows) ':AJ' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellSag(round(i / 2 + .1))));                                 

                                % write pre fast AHP
                                Select(Range(Excel,sprintf('%s',['AK' num2str(numRows) ':AK' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellFastAHP(cellFastAHP(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                 

                                % write pre AP width
                                Select(Range(Excel,sprintf('%s',['AL' num2str(numRows) ':AL' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellAPwidth(cellAPwidth(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                   

                                % write pre clustering
                                Select(Range(Excel,sprintf('%s',['AM' num2str(numRows) ':AM' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(max(cellClustering(cellClustering(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));       
                                
                                % write pre ISI CV
                                Select(Range(Excel,sprintf('%s',['AN' num2str(numRows) ':AN' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellISICV(cellISICV(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                   
                                
                                % write post IN prob
                                Select(Range(Excel,sprintf('%s',['AO' num2str(numRows) ':AO' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(min(cellINprob(cellINprob(:, j) > 0, j))));                                 

                                % write post Rin
                                Select(Range(Excel,sprintf('%s',['AP' num2str(numRows) ':AP' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellRin(j)));                                 

                                % write post Sag
                                Select(Range(Excel,sprintf('%s',['AQ' num2str(numRows) ':AQ' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellSag(j)));                                 

                                % write post fast AHP
                                Select(Range(Excel,sprintf('%s',['AR' num2str(numRows) ':AR' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellFastAHP(cellFastAHP(:, j) > 0, j))));                                   

                                % write post AP width
                                Select(Range(Excel,sprintf('%s',['AS' num2str(numRows) ':AS' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellAPwidth(cellAPwidth(:, j) > 0, j))));                                
                                
                                % write post clustering
                                Select(Range(Excel,sprintf('%s',['AT' num2str(numRows) ':AT' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(max(cellClustering(cellClustering(:, j) > 0, j))));   

                                % write post ISI CV
                                Select(Range(Excel,sprintf('%s',['AU' num2str(numRows) ':AU' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellISICV(cellISICV(:, j) > 0, j))));
                                
                                numRows = numRows + 1;  
                            end % upPSPs

                            if ~isempty(find(PSPdata(j, i, 3, :) < 0 | PSPdata(j, i + 1, 3, :) < 0, 1)) % these are down psps
                                % write cell name
                                Select(Range(Excel,sprintf('%s',['A' num2str(numRows) ':A' num2str(numRows)])));
                                set(Excel.selection, 'Value', mat2cell([currentDir '\' cellName]));    
                                                                
                                % write from
                                Select(Range(Excel,sprintf('%s',['B' num2str(numRows) ':B' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(round(i / 2 + .1)));

                                % write to
                                Select(Range(Excel,sprintf('%s',['C' num2str(numRows) ':C' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(j));

                                % write first                            
                                Select(Range(Excel,sprintf('%s',['D' num2str(numRows) ':D' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(length(find(PSPdata(j, i, 3, :) < 0))));

                                % write second
                                Select(Range(Excel,sprintf('%s',['E' num2str(numRows) ':E' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(length(find(PSPdata(j, i + 1, 3, :) < 0))));

                                % write type
                                Select(Range(Excel,sprintf('%s',['F' num2str(numRows) ':F' num2str(numRows)])));            
                                set(Excel.selection,'Value', mat2cell('Down'));       

                                % write control          
                                Select(Range(Excel,sprintf('%s',['G' num2str(numRows) ':G' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(length(find(PSPdata(j, end, 3, :) < 0))));          
                                
                                % write numEpisodes First 
                                Select(Range(Excel,sprintf('%s',['H' num2str(numRows) ':H' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(i)));  

                                % write numEpisodes Second    
                                Select(Range(Excel,sprintf('%s',['I' num2str(numRows) ':I' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(i + 1)));  
                                
                                % write numEpisodes Control          
                                Select(Range(Excel,sprintf('%s',['J' num2str(numRows) ':J' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(size(PSPdata, 2) - 1 + j)));  
                                
                                % write p value for the connection
                                try
                                    Select(Range(Excel,sprintf('%s',['K' num2str(numRows) ':K' num2str(numRows)])));            
                                    set(Excel.selection,'Value', num2str(chiTest([length(find(PSPdata(j, i, 3, :) < 0)) + length(find(PSPdata(j, i + 1, 3, :) < 0)) numProcessed(i) + numProcessed(i + 1); length(find(PSPdata(j, end, 3, :) < 0)) numProcessed(size(PSPdata, 2) - 1 + j) * numControlWindows])));                                    
                                catch
                                    fprintf(logFID, '%s\n %s', ['*****Error in chiTest: ' currentDir filesep fileList{q}], lasterr);  
                                end       
                                
                                % write stimStats   
                                stimData = stimStats(round(i / 2 + .1), j);
                                Select(Range(Excel,sprintf('%s',['L' num2str(numRows) ':L' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,1))); 
                                Select(Range(Excel,sprintf('%s',['M' num2str(numRows) ':M' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,2))); 
                                Select(Range(Excel,sprintf('%s',['N' num2str(numRows) ':N' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,3))); 
                                Select(Range(Excel,sprintf('%s',['O' num2str(numRows) ':O' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,4))); 
                                Select(Range(Excel,sprintf('%s',['P' num2str(numRows) ':P' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,5))); 
                                Select(Range(Excel,sprintf('%s',['Q' num2str(numRows) ':Q' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,6))); 
                                Select(Range(Excel,sprintf('%s',['R' num2str(numRows) ':R' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,7))); 
                                Select(Range(Excel,sprintf('%s',['S' num2str(numRows) ':S' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,8))); 
                                Select(Range(Excel,sprintf('%s',['T' num2str(numRows) ':T' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,9))); 
                                Select(Range(Excel,sprintf('%s',['U' num2str(numRows) ':U' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,10))); 
                                Select(Range(Excel,sprintf('%s',['V' num2str(numRows) ':V' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,11))); 
                                Select(Range(Excel,sprintf('%s',['W' num2str(numRows) ':W' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,12))); 
                                Select(Range(Excel,sprintf('%s',['X' num2str(numRows) ':X' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,13))); 
                                Select(Range(Excel,sprintf('%s',['Y' num2str(numRows) ':Y' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,14))); 
                                Select(Range(Excel,sprintf('%s',['Z' num2str(numRows) ':Z' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,15))); 
                                Select(Range(Excel,sprintf('%s',['AA' num2str(numRows) ':AA' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,16))); 
                                Select(Range(Excel,sprintf('%s',['AB' num2str(numRows) ':AB' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,17))); 
                                Select(Range(Excel,sprintf('%s',['AC' num2str(numRows) ':AC' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(stimData(2,18))); 

                               try % write first spike p value
                                    Select(Range(Excel,sprintf('%s',['AD' num2str(numRows) ':AD' num2str(numRows)])));            
                                    set(Excel.selection,'Value', num2str(chiTest([length(find(PSPdata(j, i, 3, :) < 0)) numProcessed(i); length(find(PSPdata(j, end, 3, :) < 0)) numProcessed(size(PSPdata, 2) - 1 + j) * numControlWindows])));
                                catch
                                    fprintf(logFID, '%s\n %s', ['*****Error in chiTest: ' currentDir filesep fileList{q}], lasterr);  
                                end   
                                
                                try % write second spike p value
                                    Select(Range(Excel,sprintf('%s',['AE' num2str(numRows) ':AE' num2str(numRows)])));            
                                    set(Excel.selection,'Value', num2str(chiTest([length(find(PSPdata(j, i + 1, 3, :) < 0)) numProcessed(i + 1); length(find(PSPdata(j, end, 3, :) < 0)) numProcessed(size(PSPdata, 2) - 1 + j) * numControlWindows])));
                                catch
                                    fprintf(logFID, '%s\n %s', ['*****Error in chiTest: ' currentDir filesep fileList{q}], lasterr);  
                                end                     
                                                                
                                % write format determiner          
                                Select(Range(Excel,sprintf('%s',['AF' num2str(numRows) ':AF' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(AND((RC[-28]+RC[-27])*' sprintf('%1.1f', numControlWindows / 2) '>RC[-25],OR(RC[-21]<0.01,AND(NOT(ISBLANK(RC[-2])),RC[-2]<0.01),AND(NOT(ISBLANK(RC[-1])),RC[-1]<0.01))),1,0)']);
                                                                
                                % write format determiner           
                                Select(Range(Excel,sprintf('%s',['AG' num2str(numRows) ':AG' num2str(numRows)])));            
                                set(Excel.selection,'Value', ['=IF(AND((RC[-29]+RC[-28])*' sprintf('%1.1f', numControlWindows / 2) '>RC[-26],OR(RC[-22]<0.0001,AND(NOT(ISBLANK(RC[-3])),RC[-3]<0.0001),AND(NOT(ISBLANK(RC[-2])),RC[-2]<0.0001))),1,0)']);

                                % write pre IN prob
                                Select(Range(Excel,sprintf('%s',['AH' num2str(numRows) ':AH' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(min(cellINprob(cellINprob(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                 

                                % write pre Rin
                                Select(Range(Excel,sprintf('%s',['AI' num2str(numRows) ':AI' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellRin(:,round(i / 2 + .1))));                                 

                                % write pre Sag
                                Select(Range(Excel,sprintf('%s',['AJ' num2str(numRows) ':AJ' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellSag(round(i / 2 + .1))));                                 

                                % write pre fast AHP
                                Select(Range(Excel,sprintf('%s',['AK' num2str(numRows) ':AK' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellFastAHP(cellFastAHP(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                 

                                % write pre AP width
                                Select(Range(Excel,sprintf('%s',['AL' num2str(numRows) ':AL' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellAPwidth(cellAPwidth(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                   

                                % write pre clustering
                                Select(Range(Excel,sprintf('%s',['AM' num2str(numRows) ':AM' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(max(cellClustering(cellClustering(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));       
                                
                                % write pre ISI CV
                                Select(Range(Excel,sprintf('%s',['AN' num2str(numRows) ':AN' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellISICV(cellISICV(:, round(i / 2 + .1)) > 0, round(i / 2 + .1)))));                                   
                                
                                % write post IN prob
                                Select(Range(Excel,sprintf('%s',['AO' num2str(numRows) ':AO' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(min(cellINprob(cellINprob(:, j) > 0, j))));                                 

                                % write post Rin
                                Select(Range(Excel,sprintf('%s',['AP' num2str(numRows) ':AP' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellRin(j)));                                 

                                % write post Sag
                                Select(Range(Excel,sprintf('%s',['AQ' num2str(numRows) ':AQ' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(cellSag(j)));                                 

                                % write post fast AHP
                                Select(Range(Excel,sprintf('%s',['AR' num2str(numRows) ':AR' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellFastAHP(cellFastAHP(:, j) > 0, j))));                                   

                                % write post AP width
                                Select(Range(Excel,sprintf('%s',['AS' num2str(numRows) ':AS' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellAPwidth(cellAPwidth(:, j) > 0, j))));                                
                                
                                % write post clustering
                                Select(Range(Excel,sprintf('%s',['AT' num2str(numRows) ':AT' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(max(cellClustering(cellClustering(:, j) > 0, j))));   

                                % write post ISI CV
                                Select(Range(Excel,sprintf('%s',['AU' num2str(numRows) ':AU' num2str(numRows)])));                                            
                                set(Excel.selection,'Value', num2str(median(cellISICV(cellISICV(:, j) > 0, j))));
                                               
                                numRows = numRows + 1;                            
                            end % downPSPs               
                        end % for stim number
                    end % for cell number
                    
                    % write saved variables
                    numPSPs = nnz(PSPdata(:,:,3,:));
                    nextPSP = length(dataVals) + 1;
                    % pre-allocate space
                    dataVals(end + 1:end + numPSPs, :) = zeros(numPSPs, 11);
                    % loop
                    for j = 1:size(PSPdata, 1)
                        for i = 1:size(PSPdata, 2)
                            for k = 1:size(PSPdata, 4)
                                if PSPdata(j,i,3,k) ~= 0
                                    fileNames{nextPSP} = [currentDir filesep cellName '.S' strtrim(sprintf('%4.0f', PSPdata(j,i,1,k))) '.E' strtrim(sprintf('%4.0f', PSPdata(j,i,2,k)))];
                                    dataVals(nextPSP, :) = [j i squeeze(PSPdata(j,i,3:9,k))' numProcessed(i), numProcessed(size(PSPdata, 2) - 1 + j)];
                                    nextPSP = nextPSP + 1;
                                end
                            end
                        end
                    end                    
                else
                    fprintf(logFID, '%s\n', ['No Appropriate Episodes for: ' currentDir filesep cellName]);
                end
                if ishandle(couplingWindow)
                    delete(couplingWindow)
                end
                cellRin = nan(1,maxAmps);
                cellSag = nan(1,maxAmps); 
                cellINprob = nan(10,maxAmps);
                cellFastAHP = nan(10,maxAmps);
                cellAPwidth = nan(10,maxAmps);
                cellClustering = nan(10,maxAmps);
                cellISICV = nan(10,maxAmps);
                cellMaxDeflection = zeros(1,maxAmps); % keeps track of the largest hyperpolarizing step that has been given to a cell
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

%save variables to a file for later use
try
%     dataVals(~(cellfun('isclass', fileNames, 'char')), :) = [];
%     dataVals(nnz(cellfun('isclass', fileNames, 'char')) + 1, :) = [];
%     fileNames(~(cellfun('isclass', fileNames, 'char'))) = [];
% dataVals is of the format (cell, stim,, amp, rise, timePostSpike, decay, time since whole cell, drug #, spikeTime, number_of_presynaptic_triggers, total_episodes) for each row
% the last stim is actually the control epochs
    save([analysisDir '\results.mat'], 'fileNames', 'dataVals')
catch
    if ~isdeployed
        keyboard
    end
end


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