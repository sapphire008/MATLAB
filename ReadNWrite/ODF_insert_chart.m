function [STATUS, MESSAGE] = ODF_insert_chart(file_path,DATA,worksheet_name,chart_type,chart_title,chart_position)
% [STATUS, MESSAGE] = ODF_insert_chart(file_path,DATA,worksheet_name,chart_type,chart_position)
%
% Insert a chart using ODF fileformat
% Requires JAVA odftookit-x.x-incubating.jar
% If not already compiled, download the incubator source from JAVA API,
% then use the command 
%       jar cf 'packagename.jar' 'source_1' 'source_2' ... 
% to compile
%
% Must add this package using javaclasspath beforehand
% 
% Inputs: All inputs are required
%       file_path: full path of file where the chart to be inserted
%
%       DATA: numeric values used to plot the data
%   
%       worksheet_name: which worksheet to insert the graph to; can be
%                       pre-existing worksheet or enter a new name so that 
%                       the function will create a new worksheet
%       
%       chart_type: type of chart to be inserted. Current selections
%                   include the following
%                a). 'hist': histogram
%                b). 'scatter': scatterplot (not implemented)
%
%       chart_title: title of the chart
%
%       chart_position: position of the chart, or which cell the upperleft
%                       corner of the chart will reside and the length and
%                       width, as in [x0,y0,L,W]
%       
% Outputs:
%       STATUS: status indicating whether the chart creation is successful
%               or not
%       MESSAGE: message that describes the event of successful or
%                unsuccessful creation of the chart

javaclasspath('/usr/local/pkg64/matlabpackages/odftookit-0.6-incubating.jar');
% import modules for ods writing and chart creation
import org.odftoolkit.simple.chart.*;
import org.odftoolkit.odfdom.doc.*;
import org.odftoolkit.odfdom.doc.table.*;
import org.odftoolkit.odfdom.doc.office.*;


%% Locate or create the file

% on a mac, use the odfdom interface to write the ods file
STATUS = true; MESSAGE = '';
[PATH,NAME,EXT] = fileparts(file_path);
EXT = '.ods';
file_path = fullfile(PATH,[NAME,EXT]);

if exist(file_path,'file')
    try
        odsDoc = OdfSpreadsheetDocument.loadDocument(file_path);
    catch ME
        STATUS = false; MESSAGE = ME.identifier; return;
    end
else
    % if the file doesn't exist, create a new spreadsheet document and add
    try
        odsDoc = OdfSpreadsheetDocument.newSpreadsheetDocument();
    catch ME
        STATUS = false; MESSAGE = ME.identifier; return;
    end
end

try
    odsSpreadSheet = odsDoc.getContentRoot();
    odsTables = odsSpreadSheet.getChildNodes();
catch ME
    STATUS = false; MESSAGE = ME.identifier; return;
end

% iterate over the tables until we find the worksheet that we want
len = odsTables.getLength(); found = 0;
for i=1:len
  child = odsTables.item(i-1);
  if strcmpi(child.getLocalName(),'table')
    odsTable = OdfTable.getInstance(child);
    if strcmp(odsTable.getTableName(),wksht), found = 1; break; end
  end
end

% add the worksheet if not found
if ~found
  try
    odsTable = OdfTable.newTable(odsDoc);
    odsTable.setTableName(wksht);
  catch ME
    STATUS = false; MESSAGE = ME.identifier; return;
  end
end

%% Create the chart

end


%% Sub-routines for each type of chart to be inserted
% Insert histogram using raw data
function Insert_Hist_raw_data()
end

% Insert histogram using spreadsheet data
function Insert_Hist_spreadsheet()
end

% Insert Scatter plot using raw_data
function Insert_Scatter_raw_data()
end

% Insert Scatter plot using spreadsheet data
function Insert_Scatter_spreadsheet()
end