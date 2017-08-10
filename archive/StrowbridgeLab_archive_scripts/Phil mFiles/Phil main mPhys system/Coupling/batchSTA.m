%search through specified directory and generate raster plots of spiking
%for any that demonstrate spikes in more than one cell

function batchSTA(directory)
warning off

% set up some constants
stepLength = 10; % ms
stepGap = 60; % ms
windowSize = 3.6; % ms length in which to look for change
windowDelay = 0.4; % ms length to lag the change search window

if nargin < 1
    directory = uigetdir('','Select directory in which to analyze data files')
end
if directory == 0
    error('Invalid Directory');
end

%set up results folder for results
analysisDir = strcat(directory, '\Analysis');
mkdir(directory, 'Analysis');

% setup excel for archiving data
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
            set(Excel.selection,'Value', {'Path'});
            Select(Range(Excel,sprintf('%s','B1:B1')));
            set(Excel.selection,'Value', {'From'});
            Select(Range(Excel,sprintf('%s','C1:C1')));
            set(Excel.selection,'Value', {'To'});
            Select(Range(Excel,sprintf('%s','D1:D1')));
            set(Excel.selection,'Value', {'Before'});
            Select(Range(Excel,sprintf('%s','E1:E1')));
            set(Excel.selection,'Value', {'After'});
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
    logFID = fopen(strcat(analysisDir, '\logFile.dat'),'w');
    
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
                        couplingWindow = checkSTA([currentDir, '\', strtrim(fileList{q})], windowSize, windowDelay);
                    catch
                        whoops = lasterror;
                        outError = '*****Error:';
                        for errorIndex = 1:numel(whoops.stack)
                           outError = [outError ' in ' whoops.stack(errorIndex).name ' at line ' num2str(whoops.stack(errorIndex).line) ';'];
                        end
                        fprintf(logFID, '%s\n %s', [outError ' File: ' currentDir filesep fileList{q}, whoops.message], char(13));  
                    end
                    break
                 end
            end
            if q == numel(fileList) || ~strcmp(fileList{q + 1}(1:find(fileList{q + 1} == 'S', 1, 'last') - 2), cellName)
                numRows = numRows + 1;
                userData = get(couplingWindow, 'userData');
                if size(userData, 2) == 7
                    PSPdata = userData{4};
                    numProcessed = userData{2};
                    windowSize = userData{6};
                    windowDelay = userData{7};

                    try
                        %write analysis to file
                        if size(PSPdata, 3) > 1
                            if ~isempty(currentDir(length(analysisDir) - 8:end))
                                mkdir(analysisDir, currentDir(length(analysisDir) - 8:end));
                            end
                            hgsave([analysisDir, '\', currentDir(length(analysisDir) - 8:end), '\', cellName, '.fig']);
                            fprintf(logFID, '%s\n', strcat('Completed Analysis for: ', currentDir, '\', cellName));
                        else
                            fprintf(logFID, '%s\n', strcat('Insufficient Hits for: ', currentDir, '\', cellName));
                        end
                    catch
                        fprintf(logFID, '%s\n %s\n', strcat('*****Error writing analysis file: ', currentDir, '\', fileList{q}), lasterr);  
                    end

                    % write data
                    for j = 1:size(PSPdata, 1)
                        for i = 1:size(PSPdata, 2)
                            if any(PSPdata(j, i, :))
                                beforeData = PSPdata(j, i, 1:windowSize);
                                afterData = PSPdata(j, i, windowSize + windowDelay + 1:end);
                                [h,significance] = ztest(mean(PSPdata(j, i, windowSize + windowDelay + 1:end)), mean(PSPdata(j, i, max([1 windowSize - 50]):windowSize)), std(PSPdata(j, i, max([1 windowSize - 50]):windowSize)), 0.01, 'both');

                                % write cell name
                                Select(Range(Excel,sprintf('%s',['A' num2str(numRows) ':A' num2str(numRows)])));
                                set(Excel.selection, 'Value', mat2cell([currentDir '\' cellName]));                                   

                                % write from
                                Select(Range(Excel,sprintf('%s',['B' num2str(numRows) ':B' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(round(i / 2 + .1)));

                                % write to
                                Select(Range(Excel,sprintf('%s',['C' num2str(numRows) ':C' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(j));

                                % write firstBefore                            
                                Select(Range(Excel,sprintf('%s',['D' num2str(numRows) ':D' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(mean(beforeData)));

                                % write firstAfter
                                Select(Range(Excel,sprintf('%s',['E' num2str(numRows) ':E' num2str(numRows)])));
                                set(Excel.selection, 'Value', num2str(mean(afterData)));

                                % write Difference
                                Select(Range(Excel,sprintf('%s',['F' num2str(numRows) ':F' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(mean(afterData) - mean(beforeData)));       

                                % write P-value          
                                Select(Range(Excel,sprintf('%s',['G' num2str(numRows) ':G' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(significance));           

                                % write numEpisodes          
                                Select(Range(Excel,sprintf('%s',['H' num2str(numRows) ':H' num2str(numRows)])));            
                                set(Excel.selection,'Value', num2str(numProcessed(j))); 

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

                                % write saved variables
    %                             fileNames{numRows - 1} = [analysisDir, '\', currentDir(length(analysisDir) - 8:end), '\', cellName, '.fig'];
    %                             dataVals(numRows - 1, :) =  ;

                                numRows = numRows + 1;  
                            end
                        end
                    end
                else
                    fprintf(logFID, '%s\n', strcat('No Appropriate Episodes for: ', currentDir, '\', cellName));
                end
                if ishandle(couplingWindow)
                    delete(couplingWindow)
                end
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