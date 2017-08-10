% writes couplings to an excel file in the phil format
% column A is episode
% column B is presynaptic cell
% column C is postsynaptic cell
% column D is type (I or E)
% column E is time post spike of PSP onset
% column F is amplitude of PSP
% column G is tau of fit to PSP
% column H is yOffset of fit to PSP

function excelCoupling(PSPdata, FileName)

if nargin < 1
    userData = get(gcf, 'UserData');
    PSPdata = userData{4};
    clear userData;
    if ndims(PSPdata) < 4
        disp('Error in input')
        return
    end
end

if nargin < 2
    % display file box
    [FileName,PathName] = uiputfile({'*.xls','Excel Files (*.xls)'}, 'Save Data As...');
    FileName = strcat(PathName, FileName);
end

if isempty(strfind(FileName(end - 3:end), '.xls'))
    FileName = [FileName '.xls'];
end

if FileName ~= 0
    % Attempt to start Excel as ActiveX server.
    try
        Excel = actxserver('Excel.Application');

    catch
        disp('error writing to data file');
        return;
    end

    try
        if ~exist(FileName,'file')
            % Create new workbook.  

            %This is in place because in the presence of a Google Desktop
            %Search installation, calling Add, and then SaveAs after adding data,
            %to create a new Excel file, will leave an Excel process hanging.  
            %This workaround prevents it from happening, by creating a blank file,
            %and saving it.  It can then be opened with Open.
            ExcelWorkbook = Excel.workbooks.Add;
            ExcelWorkbook.SaveAs(FileName,1);
            ExcelWorkbook.Close(false);
        end

        %Open file
        ExcelWorkbook = Excel.workbooks.Open(FileName);
        sheet = 'PSP Data';
        
        try % select region.
            % Activate indicated worksheet.
            activate_sheet(Excel,sheet);

            % Write column headers
            Select(Range(Excel,sprintf('%s','A1:A1')));
            set(Excel.selection,'Value',{'Sequence'});
            Select(Range(Excel,sprintf('%s','B1:B1')));
            set(Excel.selection,'Value',{'Episode'});
            Select(Range(Excel,sprintf('%s','C1:C1')));
            set(Excel.selection,'Value',{'Cell'});
            Select(Range(Excel,sprintf('%s','D1:D1')));
            set(Excel.selection,'Value',{'Stim'});
            Select(Range(Excel,sprintf('%s','E1:E1')));
            set(Excel.selection,'Value',{'Type'});
            Select(Range(Excel,sprintf('%s','F1:F1')));
            set(Excel.selection,'Value',{'Amp'});
            Select(Range(Excel,sprintf('%s','G1:G1')));
            set(Excel.selection,'Value',{'Tau'});
            Select(Range(Excel,sprintf('%s','H1:H1')));
            set(Excel.selection,'Value',{'Latency'});
            Select(Range(Excel,sprintf('%s','I1:I1')));
            set(Excel.selection,'Value',{'Decay'});
            Select(Range(Excel,sprintf('%s','J1:J1')));
            set(Excel.selection,'Value',{'Time'});
            Select(Range(Excel,sprintf('%s','K1:K1')));
            set(Excel.selection,'Value',{'Drug'});
            
            % transform data to excel format, assuming two stims per channel
            whereAt = 2;
            for i = 1:size(PSPdata, 2)
                for j = 1:size(PSPdata, 1)
                    clear stringData
                    if ~isempty(find(PSPdata(j, i, 1, :), 1))
                        for k = 1:length(find(PSPdata(j, i, 1, :)))
                            if PSPdata(j, i, 3, k) > 0
                                stringData(k) = 'E';
                            else
                                stringData(k) = 'I';
                            end
                        end
                        % Export data to selected region.
                        Select(Range(Excel,sprintf('%s',['A' num2str(whereAt) ':B' num2str(whereAt + length(stringData) - 1)])));
                        set(Excel.selection,'Value',squeeze(PSPdata(j, i, 1:2, 1:length(stringData)))');
                        Select(Range(Excel,sprintf('%s',['C' num2str(whereAt) ':D' num2str(whereAt + length(stringData) - 1)])));
                        set(Excel.selection,'Value',squeeze(repmat([j i], length(stringData), 1)));
                        for h = whereAt:whereAt + length(stringData) - 1
                            Select(Range(Excel,sprintf('%s',['E' num2str(h) ':E' num2str(h)])));
                            set(Excel.selection,'Value',stringData(h - whereAt + 1));
                        end
                        Select(Range(Excel,sprintf('%s',['F' num2str(whereAt) ':K' num2str(whereAt + length(stringData) - 1)])));
                        set(Excel.selection,'Value',squeeze(PSPdata(j, i, 3:8, 1:length(stringData)))');
                        whereAt = whereAt + length(stringData);
                    end
                end
            end
            
            ExcelWorkbook.Save
            ExcelWorkbook.Close(false)  % Close Excel workbook.
            Excel.Quit;

        catch % Throw data range error.
            error('MATLAB:xlswrite:SelectDataRange',lasterr);
        end

    catch
        Excel.Quit;
        delete(Excel);                 % Terminate Excel server.
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