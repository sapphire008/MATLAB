function load_raw_stop_signal(subject_name,behav_dir,target_file,LeftKeyNum,RightKeyNum)
% specifically designed for stop_signal_behave vector creation
% convert Seeker information to two csv files to be used in vector
% generation and behave analysis.
%
% Requires cell2csv function
%   
% Inputs:
%   subject_name: subject ID. It should be a folder name as well, that
%                 contains the .mat behave file from stop_signal
%   behav_dir: directory that contains the subject folders of behave .mat
%   target_file: format of the behave file. Put as an option here so that
%                it can accomodate future changes in the task script.
%                Default is '*stop_f*.mat', looking for fMRI session behave
%                .mat file
%   LeftKeyNum: left key mapping. Default 94. This is what key number has 
%               been recorded upon subject response
%   RightKeyNum: right key mapping. Default 95


%addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
%behav_dir ='/nfs/jong_exp/midbrain_pilots/stop_signal/behav/';
%subject_name = 'MP123_061713';
%target_file = '1stop_fmri*.mat';
%{col, row_num}: exclude which rows according to which column
if nargin<3 || isempty(target_file)
    target_file = '*stop_f*.mat';
end
if nargin<4 || isempty(LeftKeyNum)
    LeftKeyNum = 94;
end
if nargin<5 || isempty(RightKeyNum)
    RightKeyNum = 95;
end

exclude_rows = {'Trial',2};%{'col_name',exclude_row_with_value}
sort_by_which_col = {'NumChunksNum','absoluteTime'};
%input column header
colHead= {'TrialNumber','NumChunksNum','Trial','ArrowDirection',...
    'LadderNumber','LadderNum_SSD','SubjectResponse','LadderMovement',...
    'RT','actualSSD_old','actualSSD_plusCMDtime','absoluteTime',...
    'TimeStartBlock','actualSSD','TrialDuration_trialcode',...
    'TimeCourse_trialcode'};
%output column header
colHead2 = {'Block','Cue_Onset','Cue_Onset_Zeroed','ReactionTime',...
    'trial_type_name','trial_type','Arrow_presented','User_response',...
    'subject_translated_arrow_response','Accuracy'};

%no need to modify below-----------------------------------------------

% get a list of behave files
files = dir(fullfile(behav_dir,subject_name,target_file));
if isempty(files)
    error('File cannot be found:%s',fullfile(behav_dir,subject_name,target_file));
end
tmp_mat = [];
%concatenate all the Seekers
for n = 1:length(files)
    clear Seeker;
    load(fullfile(behav_dir,subject_name,files(n).name),'Seeker');
    tmp_mat = [tmp_mat;Seeker];
end

%exclude unwanted trials by column name
for m = 1:size(exclude_rows, 1)
    clear tmp_col;
    tmp_col = find(ismember(colHead,exclude_rows{m,1}));
    tmp_mat = sortrows(tmp_mat, tmp_col);
    tmp_mat = tmp_mat(tmp_mat(:,tmp_col)~=exclude_rows{m,2},:);
end

%sort by desired orders
if ~isempty(sort_by_which_col)
    tmp_mat = sortrows(tmp_mat, cell2mat(cellfun(@(x) find(...
        ismember(colHead,x)), sort_by_which_col,'un',0)));
end

%write to a worksheet
worksheet = cell(size(tmp_mat,1)+1,size(tmp_mat,2));
worksheet(1,:) = colHead;
worksheet(2:end,:) = num2cell(tmp_mat);

%convert worksheet so that it is usable by writemat
converted_worksheet = cell(size(worksheet,1),length(colHead2));%initiate output
converted_worksheet(1,:) = colHead2;%put in header
converted_worksheet(2:end,1) = worksheet(2:end,2);%block
converted_worksheet(2:end,2) = worksheet(2:end,12);%absolute onset
converted_worksheet(2:end,3) = cellfun(@(x) x-worksheet{2,12},worksheet(2:end,12),'un',0);%zeroed onset
converted_worksheet(2:end,4) = worksheet(2:end,9);%RT
trial_IND = cell2mat((cellfun(@(x) x==1,worksheet(2:end,3),'un',0)));%trial type, 0 go, 1 no_go
converted_worksheet(1+find(trial_IND),5) = cellfun(@(x) 'no_go',worksheet(1+find(trial_IND),3),'un',0);%verbalize trial type
converted_worksheet(1+find(~trial_IND),5) = cellfun(@(x) 'go',worksheet(1+find(~trial_IND),3),'un',0);%verbalize trial type

for kk = 2:size(worksheet,1)
    %trial_type
    if worksheet{kk,2} == 3
        % for go only block == 3
        converted_worksheet{kk,6} = 2;
    else
        converted_worksheet{kk,6} = worksheet{kk,3};
    end
    %arrow presented
    if worksheet{kk,4} == 0
        converted_worksheet{kk,7} = 'Left';%recorded as 0
    else
        converted_worksheet{kk,7} = 'Right';%recorded as 1
    end
    %subject response
    if worksheet{kk,7} == LeftKeyNum
        converted_worksheet{kk,8} ='Left';
        converted_worksheet{kk,9} = 0;
    elseif worksheet{kk,7} == RightKeyNum
        converted_worksheet{kk,8} = 'Right';
        converted_worksheet{kk,9} = 1;
    else
        converted_worksheet{kk,8} = 'No_Response';
        converted_worksheet{kk,9} = -1;
    end
    %accuracy
    if worksheet{kk,3}==0%go
        % responded && arrow matches
        if worksheet{kk,9}>0 && worksheet{kk,4}==converted_worksheet{kk,9}
            converted_worksheet{kk,10} = 1;
        else
            converted_worksheet{kk,10} = 0;
        end
    else%no go
        if worksheet{kk,9}==0
            converted_worksheet{kk,10} = 1;
        else
            converted_worksheet{kk,10} = 0;
        end
    end     
end

%no need to modify above------------------------------------------------

cell2csv(fullfile(behav_dir,subject_name,[subject_name,'_raw_data.csv']),worksheet,',');
cell2csv(fullfile(behav_dir,subject_name,[subject_name,'.csv']),converted_worksheet,',');
end

%% subroutine
function cell2csv(fileName, cellArray, separator, permission, excelYear, decimal)
% Writes cell array content into a *.csv file.
% 
% CELL2CSV(fileName, cellArray, separator, permission, excelYear, decimal)
%
% fileName     = Name of the file to save. [ i.e. 'text.csv' ]
% cellArray    = Name of the Cell Array where the data is in
% separator    = sign separating the values (default = ';')
% permission   = file permission, follows fopen's convention. This
%                potentially allows the user to append data to the written
%                csv file (default:'w')
% Other file permission strings can be:
%         'r'     open file for reading
%         'w'     open file for writing; discard existing contents
%         'a'     open or create file for writing; append data to end of file
%         'r+'    open (do not create) file for reading and writing
%         'w+'    open or create file for reading and writing; discard 
%                 existing contents
%         'a+'    open or create file for reading and writing; append data 
%                 to end of file
%         'W'     open file for writing without automatic flushing
%         'A'     open file for appending without automatic flushing
%
%
% excelYear    = depending on the Excel version, the cells are put into
%                quotes before they are written to the file. The separator
%                is set to semicolon (;)
% decimal      = defines the decimal separator (default = '.')
%
%         by Sylvain Fiedler, KA, 2004
% updated by Sylvain Fiedler, Metz, 06
% fixed the logical-bug, Kaiserslautern, 06/2008, S.Fiedler
% added the choice of decimal separator, 11/2010, S.Fiedler
% allowed file permission specification, 05/2013, E.Cui

%% Checking for optional Variables
if ~exist('separator', 'var')
    separator = ',';
end

if ~exist('excelYear', 'var')
    excelYear = 1997;
end

if ~exist('decimal', 'var')
    decimal = '.';
end

if ~exist('permission','var')
    permission = 'w';
end

%% Setting separator for newer excelYears
if excelYear > 2000
    separator = ';';
end

%% Write file
datei = fopen(fileName, permission);

for z=1:size(cellArray, 1)
    for s=1:size(cellArray, 2)
        
        var = cellArray{z,s};
        % If zero, then empty cell
        if size(var, 1) == 0
            var = '';
        end
        % If numeric -> String
        if isnumeric(var)
            var = num2str(var);
            % Conversion of decimal separator (4 Europe & South America)
            % http://commons.wikimedia.org/wiki/File:DecimalSeparator.svg
            if decimal ~= '.'
                var = strrep(var, '.', decimal);
            end
        end
        % If logical -> 'true' or 'false'
        if islogical(var)
            if var == 1
                var = 'TRUE';
            else
                var = 'FALSE';
            end
        end
        % If newer version of Excel -> Quotes 4 Strings
        if excelYear > 2000
            var = ['"' var '"'];
        end
        
        % OUTPUT value
        fprintf(datei, '%s', var);
        
        % OUTPUT separator
        if s ~= size(cellArray, 2)
            fprintf(datei, separator);
        end
    end
    if z ~= size(cellArray, 1) % prevent a empty line at EOF
        % OUTPUT newline
        fprintf(datei, '\n');
    end
end
% Closing file
fclose(datei);
% END
end