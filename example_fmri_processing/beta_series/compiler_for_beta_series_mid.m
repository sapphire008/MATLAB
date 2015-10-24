% compiler for beta series
clear all;
addpath(genpath('/usr/local/pkg64/matlabpackages/xlwrite/'));
addpath('/usr/local/pkg64/matlabpackages/ReadNWrite/');
addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
addpath('/nfs/jong_exp/midbrain_pilots/scripts/beta_series/');
data_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/beta_series/extracted_betas_all_ROIsPeak/';
save_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/beta_series/';
file_suffix = {'_TR2_SNleft_peakvoxel','_TR2_STNleft_peakvoxel',...
    '_TR2_RNleft_peakvoxel','_TR2_SNright_peakvoxel',...
    '_TR2_STNright_peakvoxel','_TR2_RNright_peakvoxel',...
    '_TR2_VTAleft_peakvoxel','_TR2_VTAright_peakvoxel',...
    '_TR2_VTAbilateral_peakvoxel','_TR2_VTAleft_extended_peakvoxel',...
    '_TR2_VTAright_extended_peakvoxel',...
    '_TR2_VTAbilateral_extended_peakvoxel','_TR2_SNVTAleft_peakvoxel',...
    '_TR2_SNVTAright_peakvoxel','_TR2_SNVTAbilateral_peakvoxel',...
    '_TR2_VTA_blob_peakvoxel','_TR2_SNVTA_blob_peakvoxel'};
file_ext = '.csv';
% sort the column of the pivot table according to the following (will only
% retain listed columns)
column_order = {...
    'Cue_lose5','Cue_lose1','Cue_lose0',...
    'Cue_gain0','Cue_gain1','Cue_gain5',...
    'Feedback_lose5_miss','Feedback_lose1_miss','Feedback_gain5_miss',...
    'Feedback_gain1_miss','Feedback_lose0_miss','Feedback_gain0_miss',...
    'Feedback_lose0_hit','Feedback_gain0_hit','Feedback_lose1_hit',...
    'Feedback_lose5_hit','Feedback_gain1_hit','Feedback_gain5_hit',...
    };
filter_subject = {'haldol'};%exclude any row labels that has these words
separate_block_and_condition = false;%is block and condition in the same string?
counter = 1;% count how many sheets being created

%% Main compiler algorithm
% javaclasspath('/usr/local/pkg64/matlabpackages/odfdom-java-0.8.7.jar');
% javaaddpath('/usr/local/pkg64/matlabpackages/xlwrite/poi_library/poi-3.8-20120326.jar');
% javaaddpath('/usr/local/pkg64/matlabpackages/xlwrite/poi_library/poi-ooxml-3.8-20120326.jar');
% javaaddpath('/usr/local/pkg64/matlabpackages/xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar');
% javaaddpath('/usr/local/pkg64/matlabpackages/xlwrite/poi_library/xmlbeans-2.3.0.jar');
% javaaddpath('/usr/local/pkg64/matlabpackages/xlwrite/poi_library/dom4j-1.6.1.jar');
for f = 1:length(file_suffix)
disp(['Current working on ',file_suffix{f}]);
clear files worksheet pivot_worksheet OutWorksheet;       
files = dir(fullfile(data_dir,['*',file_suffix{f},file_ext]));
files = {files.name};
if isempty(files)%flag if directory is empty
    error('Directory is empty');
end

% create the work sheet from each loaded csv file
for n = 1:length(files)
    clearvars tmp* ind subj_name;
    %read in the table
    tmp = ReadTable(fullfile(data_dir,files{n}));
    % get subject name according to the table
    ind = regexp(files{n},file_suffix{f});
    subj_name = files{n}(1:ind-1);
    %if there is TR information in the subject name, remove it
    subj_name = regexprep(subj_name, '_TR(\d*)','');
    % combine data with subjects
    tmp_worksheet=[cellstr(repmat(subj_name,size(tmp,1),1)),tmp];
    % initialize worksheet if this is the first subject
    if n < 2
        worksheet = cell(0,size(tmp_worksheet,2));
    end
    worksheet = [worksheet;tmp_worksheet];
end

% separate block and condition if necessary
if separate_block_and_condition
    %for frac back betas, need to separate block and condition
    worksheet(:,4) = worksheet(:,3);%shift one column
    blocks = cellfun(@(x) regexp(x,'Sn_(\d*)','match'),worksheet(:,2),'un',0);
    blocks = cellfun(@(x) x{1},blocks,'un',0);
    conds = cellfun(@(x) x(regexp(x,'Sn_(\d*)','end')+2:end),worksheet(:,2),'un',0);
    conds = cellfun(@(x) regexprep(x,'NULL','Fixation'),conds,'un',0);
    worksheet(:,2) = blocks;
    worksheet(:,3) = conds;
end

% make the pivot table
tmp_pivot_worksheet = pivottable(worksheet,1,3,4, @mean);
tmp_pivot_worksheet{1,1} = 'Subjects';

% % filter the subject
% if ~isempty(filter_subject)
%     S = cellregexp(tmp_pivot_worksheet(:,1),filter_subject,[],true,true);
%     tmp_pivot_worksheet = tmp_pivot_worksheet(find(~sum(S,2)),:);
%     clear S;
% end

%sort the pivot table according to column
if ~isempty(column_order)
    pivot_table = cell(size(tmp_pivot_worksheet,1),numel(column_order)+1);
    pivot_table(:,1) = tmp_pivot_worksheet(:,1);
    [~,LOCB] = ismember(tmp_pivot_worksheet(1,:),column_order);
    LOCtmp = find(LOCB);
    LOCB(LOCB==0) = [];
    pivot_table(:,LOCB+1) = tmp_pivot_worksheet(:,LOCtmp);
else
    pivot_table = tmp_pivot_worksheet;%return as is
end

% Fill any empty cell with NaN
pivot_table(cellfun(@isempty,pivot_table)) = {NaN};

%% combine the raw data worksheet with the pivot table in the same
% worksheet, leave 2 columns of spaces between these two tables
[Xw,Yw] = size(worksheet);
[Xp,Yp] = size(pivot_table);
%create the final output worksheet
OutWorksheet = cell(max(Xw,Xp),max(Yw,Yp)+2);
%write in data
OutWorksheet(1:Xw,1:Yw) = worksheet;
OutWorksheet(1:Xp,2+Yw+(1:Yp)) = pivot_table;

%write the worksheet to the Excel/ODF workbook
% [S,M] = myxlswrite(fullfile(save_dir,'compiled_worksheet'),...
%     OutWorksheet,[file_suffix{f}(2:end-4),'_extracted_betas'],'A1');
% if ~S
%     disp(M);
% end
try
S=xlwrite(fullfile(save_dir,['compiled_worksheet_part',num2str(counter),'.xlsx']),...
     OutWorksheet,[file_suffix{f}(2:end-4),'_extracted_betas'],'A1');
 if ~S
     disp('Writing Error at extracted_betas');
 end
catch ERR
    counter = counter+1;
    S=xlwrite(fullfile(save_dir,['compiled_worksheet_part',num2str(counter),'.xlsx']),...
        OutWorksheet,[file_suffix{f}(2:end-4),'_extracted_betas'],'A1');
    if ~S
        disp('Writing Error at extracted_betas');
    end
end
clearvars tmp* temp* OutWorksheet;

%% write another sheet that only contains the pivot table
SummaryWorksheet = cell(size(pivot_table,1)+18,size(pivot_table,2)+1);
% put in a filtered pivot table
if ~isempty(filter_subject)
    S = cellregexp(pivot_table(:,1),filter_subject,[],true,true);
    pivot_table = pivot_table(find(~sum(S,2)),:);
    clear S;
end
[row,col] = size(pivot_table);
SummaryWorksheet(1:row,1) = pivot_table(:,1);
SummaryWorksheet(1:row,3:end) = pivot_table(:,2:end);
%second row will label the subjects
SummaryWorksheet{1,2} = 'Group';
S = cellregexp(pivot_table(:,1),{'MP(\d*)_'},'tokens');
S = cell2mat(cellfun(@(x) str2double(char(x{1})),S(2:end),'un',0));
G = cell(1,row-1);
G(S<100) = {'C'};
G(S>=100) = {'SZ'};
SummaryWorksheet(2:row,2) = G;
pivot_table = pivot_table(2:end,:);%take out the column header for easier indexing

% Do summaries
SummaryWorksheet{row+4,1} = 'Summary Statistics';
SummaryWorksheet{row+5,1} = 'Mean';
SummaryWorksheet(row+5,2:end) = SummaryWorksheet(1,2:end);
SummaryWorksheet{row+6,2} = 'C';
SummaryWorksheet{row+7,2} = 'SZ';
R.MEAN.C = nanmean(cell2mat(pivot_table(find(S<100),2:end)),1);
R.MEAN.SZ = nanmean(cell2mat(pivot_table(find(S>=100),2:end)),1);
SummaryWorksheet(row+6,3:end) = num2cell(R.MEAN.C);
SummaryWorksheet(row+7,3:end) = num2cell(R.MEAN.SZ);
SummaryWorksheet{row+10,1} = 'STD';
SummaryWorksheet(row+10,2:end) = SummaryWorksheet(1,2:end);
SummaryWorksheet{row+11,2} = 'C';
SummaryWorksheet{row+12,2} = 'SZ';
R.STD.C = nanstd(cell2mat(pivot_table(find(S<100),2:end)),0,1);
R.STD.SZ = nanstd(cell2mat(pivot_table(find(S>=100),2:end)),0,1);
SummaryWorksheet(row+11,3:end) = num2cell(R.STD.C);
SummaryWorksheet(row+12,3:end) = num2cell(R.STD.SZ);
SummaryWorksheet{row+15,1} = 'SE';
SummaryWorksheet(row+15,2:end) = SummaryWorksheet(1,2:end);
SummaryWorksheet{row+16,2} = 'C';
SummaryWorksheet{row+17,2} = 'SZ';
R.SE.C = nanstd(cell2mat(pivot_table(find(S<100),2:end)),0,1)/sqrt(sum(S<100));
R.SE.SZ = nanstd(cell2mat(pivot_table(find(S>=100),2:end)),0,1)/sqrt(sum(S>=100));
SummaryWorksheet(row+16,3:end) = num2cell(R.SE.C);
SummaryWorksheet(row+17,3:end) = num2cell(R.SE.SZ);
clear S;

%write the worksheet to the Excel/ODF workbook
% [S,M] = myxlswrite(fullfile(save_dir,'compiled_worksheet'),...
%     SummaryWorksheet,[file_suffix{f}(2:end-4),'_summary'],'A1');
% if ~S
%     disp(M);
% end
try
S=xlwrite(fullfile(save_dir,['compiled_worksheet_part',num2str(counter),'.xlsx']),...
     SummaryWorksheet,[file_suffix{f}(2:end-4),'_summary'],'A1');
 if ~S
     disp('Writing Error at extracted_betas');
 end
catch ERR
    % in case memory excceeds, write to a new sheet
    counter = counter+1;
    S=xlwrite(fullfile(save_dir,['compiled_worksheet_part',num2str(counter),'.xlsx']),...
        SummaryWorksheet,[file_suffix{f}(2:end-4),'_summary'],'A1');
    if ~S
        disp('Writing Error at extracted_betas');
    end
end
%% Insert a chart in the Summary Worksheet
%[S,M] = ODF_insert_chart();

%write table to csv file
%cell2csv(fullfile(save_dir,['compiled_worksheet',file_suffix{f}]),OutWorksheet,',');
end