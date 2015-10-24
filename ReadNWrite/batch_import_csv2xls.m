% batch import csv files into an Excel worksheet
base_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/extracted_timeseries/';
csv_save_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/extracted_timeseries/concatenated_sheets/';
xls_save_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/extracted_timeseries/concatenated_sheets/TimeSeriesSummary.xls';
subjects = {...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};%sheet names


%   'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
%     'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
%the imported csv will be concatenated one after another on the same sheet
%{'TYPE','Label','Names1','Names2',...}
% tier 1: DIR = directory name to search the files
CONCATENATION{1} = {'NULL','OneBack','TwoBack','ZeroBack'};
% tier 2: EXT = file extension to search the file
CONCATENATION{2} = {'SNleft','STNleft'};
% column header
col_head = [{'ROIs','Conditions'},cellfun(@(x) ['TR',num2str(x)],num2cell(1:10),'un',0)];

%% concatenate csv files
for s = 1:length(subjects)
    clear current_sheet;
    % start current sheet
    current_sheet = col_head;
    % import each sheet
    for n = 1:length(CONCATENATION{1})
        for m = 1:length(CONCATENATION{2})
            %load csv
            current_csv = dir(fullfile(base_dir,CONCATENATION{1}{n},...
                [subjects{s},'*',CONCATENATION{2}{m},'*.csv']));
            if isempty(current_csv)
                error('csv file does not exist');
            else
                current_csv = ReadTable(fullfile(base_dir,CONCATENATION{1}{n},...
                    current_csv.name));
                tmp_sheet = repmat([CONCATENATION{1}(n),CONCATENATION{2}(m)],size(current_csv,1),1);
                tmp_sheet = [tmp_sheet,num2cell(current_csv)];
                if size(tmp_sheet,2)<length(col_head)
                    % pad if col number is not enough
                    tmp_sheet = [tmp_sheet,repmat({''},size(current_csv,1),length(col_head)-size(tmp_sheet,2))];
                end
                current_sheet = [current_sheet;tmp_sheet];
                clear tmp_sheet;
            end
        end
    end
    cell2csv(fullfile(csv_save_dir,[subjects{s},'_TimeSeries.csv']),current_sheet,',');
end

%% write concatenated files to Excel
javaclasspath('/usr/local/pkg64/matlabpackages/ReadNWrite/odfdom-java-0.8.7.jar');
for s = 1:length(subjects)
    A = ReadTable(fullfile(csv_save_dir,[subjects{s},'_TimeSeries.csv']),',');
    myxlswrite(xls_save_dir,A,subjects{s},'A1');
end