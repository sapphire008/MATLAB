%function IEX_rawDataSummary(dir,file_ext,code_name, length_mean,length_std)
%specifically designed for the workspace of postprocessed mprage corrected
%movement data
clear all;
%addmatlabpkg('info_extraction');
% Default Parameters
% length_mean=1691;%mean data length of almost all runs (exluding new runs)
% length_std=277;%std of data length (excludin new runs)
base_dir='/nfs/r21_gaba/reprocessing/results/';
%Constructing a subject profile
%when process only one set of data
subPro={'VP544_060811_mprage_movement_postproc'};
%when processing group of data in a folder
%list_file=dir(fullfile(base_dir,'*.mat'));
%subPro = {list_file.name};
num_file=length(subPro);

data_table(1,:)={'Subject_ID', 'Runs', 'Time_Length', ...
    'X-displacement(mm)','Y-displacement(mm)',...
    'Magnitude of Displacement(mm)','X-speed(mm)',...
    'Y-speed(mm)','Magnitude of speed(mm)',...
    'Rotational Displacement(deg)'};%column titles
row_num=2;%tracking the row number to store data, starting row 2
%if the run name contains the following word, ignore the entry
frbd_words={'mprage','across','strong','weak','ws'};

%% Writing RAW Data Table (DO NOT MODIFY)
for j = 1:num_file
    clear load_file num_runs
    load_file=load([base_dir,subPro{j}]);%load .mat workspace
    num_runs=length(load_file.runs);%number of runs in a subject
    for k = 1:num_runs
        clear X_vect Y_vect data_leng tmp_run_name;
        %check if containing forbidden words
        if sum(~cellfun(@isempty,regexpi(...
                load_file.runs(1,k).im_dir,frbd_words)))==0
            X_vect=load_file.runs(1,k).displacement.x;%x displ
            Y_vect=load_file.runs(1,k).displacement.y;%y displ
            %R_vect=load_file.runs(1,k).displacement.rotational;%r displ
%             drc_vect(Y_vect>=0)=(atan2(Y_vect(Y_vect>=0),...
%                 X_vect(Y_vect>=0)))/pi*180;%direction of displacement
%             drc_vect(Y_vect<0)=360+(atan2(Y_vect(Y_vect<0),...
%                 X_vect(Y_vect<0)))/pi*180;%direction of displacement
            data_leng=length(X_vect);%lenth of the data
            %store everything to data table
            data_table{row_num,1}=strrep(subPro{j},'.mat','');%Subj ID
            tmp_run_name = regexp(load_file.runs(1,k).im_dir,'/','split');
            tmp_run_name = tmp_run_name(~cellfun(@isempty,tmp_run_name));
            data_table{row_num,2}=...IEX_runNumMod(...
                tmp_run_name{end};% run numbers
            data_table{row_num,3}=length(load_file.runs(1,k).time);%time
            data_table{row_num,4}=X_vect;%X disp
            data_table{row_num,5}=Y_vect;%Y disp
            data_table{row_num,6}=sqrt(X_vect.^2+Y_vect.^2);%mag displ
            data_table{row_num,7}=diff(X_vect);%X change
            data_table{row_num,8}=diff(Y_vect);%Y change
            data_table{row_num,9}=sqrt((diff(X_vect)).^2+...
                (diff(Y_vect)).^2);%mag disp change
            %data_table{row_num,10}=R_vect;%rotational disp
            
            row_num=row_num+1;%go to next row
        end
    end
    
end

%% Calculate average
[nRows,~]=size(data_table);
data_write=cell(nRows,33);%place holding to write avg data
data_write(1,:)={'Subject_ID', 'Runs', 'Time_Length', 'Truncated',...
    'Too_Short','X-displacement(mm)', 'Y-displacement(mm)', ...
    'Magnitude of Displacement(mm)', 'X-speed(mm)', ...
    'Y-speed(mm)', 'Magnitude of Speed(mm)',...
    'Size_X','Size_Y','Size_X_Pos','Size_X_Neg','Size_Y_Pos',...
    'Size_Y_Neg','Size_Rotation','Worst_Size','Sum_Size','Average_Size',...
    'Jaggedness_X','Jaggedness_Y','Jaggedness_Rotation',...
    'Worst_Jaggedness','Sum_Jaggedness','Average_Jaggedness',...
    'RMS_X_disp','RMS_Y_disp','RMS_Mag_disp','RMS_X_speed',...
    'RMS_Y_speed','RMS_Mag_speed'};%column title
data_write(2:end,1:3)=data_table(2:end,1:3);%copy the subject heading

%truncating length of the time series to average
if ~exist('length_mean','var')
    %mean data length
    length_mean=round(mean(cell2mat(data_table(2:end,3))));
end
if ~exist('length_std','var')
    length_std=std(cell2mat(data_table(2:end,3)));%std of data length
end
truncated_row=[];%store row of which run is being truncated
tooShort_row=[];%store row which run is too short
%prepare a new table to be store time series after truncationcd 
mod_table(:,:)=data_table(:,:);

%% Write Summary Table
length_mean = 1684;
length_std = 275;
for n=2:nRows
    %check if needs to truncate
    if mod_table{n,3}>(length_mean+length_std) %&& false
        %truncate all time series and store them in new table
        mod_table(n,4:9)=cellfun(@(X) X(1:length_mean),...
            mod_table(n,4:9),'UniformOutPut',false);
        data_write{n,4}=1;%log truncated as 1
        data_write{n,5}=0;%log not too short as 0
        truncated_row=[truncated_row n];%record row number
    %check if data is too short
    elseif mod_table{n,3}<(length_mean-length_std) %&& false
        data_write{n,4}=0;%log not truncated as 0
        data_write{n,5}=1;%log too short as 1
        tooShort_row=[tooShort_row n];%record row number
    else
        data_write{n,4}=0;%log not truncated as 0
        data_write{n,5}=0;%log not too short as 0
    end
    
    %Displacement Parameter Summary
    data_write(n,6:11)=num2cell(cellfun(@mean,mod_table(n,4:9)));
%     if data_write{n,4}>=0
%         data_write{n,6}=atan2(data_write{n,4},data_write{n,3})/pi*180;
%     else
%         data_write{n,6}=360+...
%             atan2(data_write{n,4},data_write{n,3})/pi*180;
%     end

    %Meric's Signal Characterization Summary
    [SIZE,JAGD]=IEX_mericSignalChar(mod_table{n,4},mod_table{n,5},...
        zeros(1,length(mod_table{n,4})));%calculate SIZE and JAGGEDNESS parameters
    data_write(n,12:27)=cat(2,struct2cell(SIZE)',struct2cell(JAGD)');
    data_write(n,28:33)=num2cell(cellfun(@(x) sqrt(sum(x.^2)/length(x)),mod_table(n,4:9)));
end

%% Save and Export Data Tables
%save database as matlab workspace
database.RAW=data_table;
database.MOD=mod_table;
database.SUMMARY=data_write;
save(['database_summary_' datestr(now, 'mm-dd-yyyy-HH-MM-SS'),'.mat'],'database');

%export to .csv file for further organization

%for a group of data
%IEX_cell2csv(['database_summary_' date '.csv'], data_write);
%for single subject
%IEX_cell2csv(['/nfs/r21_gaba/image_reg/mprage_corrl_analysis/Time_Series/output_saves/database_summary_', datestr(now, 'mm-dd-yyyy-HH-MM-SS'),'.csv'],data_write);
IEX_cell2csv(['/nfs/r21_gaba/reprocessing/results/summary/data_summary_',datestr(now, 'mm-dd-yyyy-HH-MM-SS'),'.csv'],data_write);

%end