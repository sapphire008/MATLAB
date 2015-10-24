%quantify movement

%% set up subjects
clear all;
base_dir='/nfs/jong_exp/midbrain_pilots/movement/';
tasks = {'4POP','frac_back','mid','RestingState','stop_signal'};

% subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
%     'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
%     'MP124_062113'};
% subjects = {'MP031_071813'};
subjects = {'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP125_072413'};

run_index_name = 'block';%the name should be like block1, block2, ...
datafile_ext = '*.txt';
baseline_run={};
save_dir='/nfs/jong_exp/midbrain_pilots/movement/analysis/';
column_titles={'X','Y','Z','roll','pitch','yaw'};
addpath(genpath('/nfs/jong_exp/midbrain_pilots/scripts/movement_analysis/'));

%% set-up worksheet
worksheet_col_titles={'Subjects','run','tasks','GeoDist','GeoRot',...
    'RMS_X','RMS_Y','RMS_Z','RMS_roll','RMS_pitch','RMS_yaw',...
    'RMS_disp_mag','RMS_rot_mag',...
    'JAG_X','JAG_Y','JAG_Z','JAG_roll','JAG_pitch','JAG_yaw',...
    'JAG_disp_mag','JAG_rot_mag','disp_mag_speed','GeoRot_speed',...
    'RMS_speed_X','RMS_speed_Y','RMS_speed_Z','RMS_omega_roll',...
    'RMS_omega_pitch','RMS_omega_yaw','RMS_speed_mag','RMS_omega_mag'};
worksheet={};
worksheet(end+1,:)=worksheet_col_titles;
ws_row=2;


%% run movement analysis
for s = 1:length(subjects)
% make a directory for each subject
mkdir([save_dir,subjects{s}]);

%calculating baseline value
baseline_averages = {};
if ~isempty(baseline_run)
    for b = 1:length(baseline_run)%for each baseline task
        clear baseline_files baseline_data;
        baseline_data = {};
        baseline_files = dir(fullfile(base_dir,baseline_run{b},...
            [subjects{s},datafile_ext]));
        baseline_files = {baseline_files.name};
        if isempty(baseline_files)
            continue;%continue with the loop if no files found
        end
        %for each file found in the current baseline task
        for k = 1:length(baseline_files)
            baseline_data{end+1} = importdata(fullfile(base_dir,...
                baseline_run{b},baseline_files{k}));
        end
        %take average for each column of each baseline file
        baseline_averages{end+1,1} = cell2mat(...
            cellfun(@(x) mean(x,1),baseline_data,...
            'UniformOutput',false));
    end
end
if ~isempty(baseline_averages)
    baseline_values = mean(cell2mat(baseline_averages),1);
else
    baseline_values = zeros(1,length(column_titles));
end
    
    
 
for t = 1:length(tasks)
    %check if current task is the baseline task
    if ismember(tasks{t},baseline_run)
        %do not remove baseline's own mean
        baseline_vect = zeros(1,length(column_titles));
    else
        baseline_vect = baseline_values;
    end
    
    %figure out runs based on file name: must be changed to follow file
    %naming convention
    clear runs;
    runs = dir(fullfile(base_dir,tasks{t},[subjects{s},'*',run_index_name,datafile_ext]));
    runs = {runs.name};
    empty_run_flag =0;%flagging empty runs
    
    if isempty(runs)
        runs = dir(fullfile(base_dir,tasks{t},[subjects{s},'*',datafile_ext]));
        runs = {runs.name};
        empty_run_flag = 1;
    end
   
    for ru = 1:length(runs)
        clear current_run R;
        if ~empty_run_flag
            current_run = char(regexp(runs{ru},...
                [run_index_name,'(\d*)'],'match'));
        else
            current_run = 'no_blocks';
        end
        %check if file exists
        if ~exist(fullfile(base_dir,tasks{t},runs{ru}))
            disp(['Skipped: ',subjects{s},'|',tasks{t},'|',current_run]);
            continue;
        end
        %load([base_dir,subjects{s},'/',runs{ru},'/','rp_a001_corrected.mat']);%=R
        R = importdata(fullfile(base_dir,tasks{t},runs{ru}));
        %if having baseline, subtract it from the time series
        if any(abs(baseline_values)>0)
            R = bsxfun(@minus,R,baseline_vect);
        end
        [RMS,GeoDist,~,JAG]=movement_params(R,column_titles);
        R_diff=[zeros(1,size(R,2));diff(R,1,1)];
        [RMS_speed,GeoDist_speed,~,~]=movement_params(R_diff,column_titles);
        %         save([save_dir,subjects{s},'/',subjects{s},...
        %             '-movement_summary.mat'],'RMS','GeoDist','JAG',...
        %             'RMS_speed','GeoDist_speed');
        
        
        %adding parameter summary to the worksheet
        worksheet(ws_row,1:3)={subjects{s},current_run,tasks{t}};
        worksheet(ws_row,4:5)={GeoDist.translational.Mean,GeoDist.rotational.Mean};
        worksheet(ws_row,6:13)=struct2cell(RMS)';
        worksheet(ws_row,14:21)=struct2cell(JAG)';
        worksheet(ws_row,22:23)={GeoDist_speed.translational.Mean,GeoDist_speed.rotational.Mean};
        worksheet(ws_row,24:31)=struct2cell(RMS_speed)';
        ws_row=ws_row+1;
        
        
        %collect the time series to be plotted
        F= cell(4,2);
        F{1,1} = [R(:,1:3),GeoDist.translational.Vect];%data
        F{1,2} = 'Movement(mm)';%y label
        F{1,3} = [-2,2];%ylim
        F{2,1} = [R(:,4:6),GeoDist.rotational.Vect];
        F{2,3} = [-0.1 0.1];
        F{2,2} = 'Rotation (rad)';
        F{3,1} = [R_diff(:,1:3),GeoDist_speed.translational.Vect];
        F{3,2} = 'Speed (mm/scan)';
        F{3,3} = [-2, 2];
        F{4,1} = [R_diff(:,4:6),GeoDist_speed.rotational.Vect];
        F{4,2} = 'Angular Speed (rad/scan)';
        F{4,3} = [-0.1 0.1];
        
        figure;
        for f = 1:size(F,1)
            subplot(2,2,f);
            plot_time_series(F{f,1},...
                'legend',[column_titles(1:3),{'Magnitude'}],...
                'ylim',F{f,3},'axis_label',[{'Scans'},F{f,2}],...
                'plot_titles',[subjects{s},'_',tasks{t},'_',current_run]); 
        end
        
        set(gcf,'Position',[200 200 1600 1000]);
        saveas(gcf,[save_dir,subjects{s},'/',subjects{s},'-',tasks{t},...
            '-',current_run,'.tiff'],'tiff');
        close all;
        
    end
end
end
save(fullfile(save_dir,['worksheet-',datestr(now,'mm-dd-yyyy-HH-MM-SS'),'.mat']),'worksheet');
cell2csv([save_dir,'midbrain_pilots_movement_summary.csv'],worksheet,',','a+');

%% Do ratings
source_dir = '/nfs/jong_exp/midbrain_pilots/movement/rating_sheet.csv';
rating_data_sheet = importdata(source_dir);
[RMS_disp_ratings,RMS_speed_ratings] = rate_movement(...
    rating_data_sheet.data(:,1),rating_data_sheet.data(:,2));

output_sheet = rating_data_sheet.textdata;
output_sheet(2:end,4:5) = num2cell(rating_data_sheet.data);
output_sheet(1,6:7) = {'disp_ratings','speed_ratings'};
output_sheet(2:end,6:7) = horzcat(RMS_disp_ratings,RMS_speed_ratings);

%save results
[outdir,~,~] = fileparts(source_dir);
cell2csv(fullfile(outdir,'out_ratings_sheet.csv'),output_sheet,',');

% %% list param value
% alphabets_list={'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
% col_list={'c','u','e','f','g','k','w','x','y','','m','n','o','s'};
% row_list=[58,97,13,14];
% for n = 1:length(col_list)
%     try
%         A(1,n)=find(strcmp(col_list{n},alphabets_list));
%     catch
%         A(1,n)=29;
%     end
% end
% 
% for m = 1:length(row_list)
%     disp(worksheet(row_list(m),[1,2,A]));
% 
% 
% end
% 
% %% get raw data and create database
% col_title={'Subjects','run',...
%     'X','Y','Z','GeoDist',...
%     'roll','pitch','yaw','GeoRot',...
%     'X_sp','Y_sp','Z_sp','GeoDist_sp',...
%     'roll_sp','pitch_sp','yaw_sp','GeoRot_sp'};
% raw_database=cell(length(subjects)*length(runs)+1,length(col_title));
% raw_database(1,:)=col_title;
% raw_ws=2;
% for s = 1:length(subjects)
%     for ru = 1:length(runs)
%         load([base_dir,subjects{s},'/',runs{ru},'/','rp_a001_corrected.mat']);%=R
%         R_diff=[zeros(1,size(R,2));diff(R,1,1)];
%         
%         raw_database(raw_ws,1:2)={subjects{s},runs{ru}};
%         raw_database(raw_ws,[3:5,7:9])=num2cell(R,1);
%         raw_database(raw_ws,[6,10])={sqrt(sum(R(:,1:3).^2,2)),sqrt(sum(R(:,4:6).^2,2))};
%         raw_database(raw_ws,[11:13,15:17])=num2cell(R_diff,1);
%         raw_database(raw_ws,[14,18])={sqrt(sum(R_diff(:,1:3).^2,2)),sqrt(sum(R_diff(:,4:6).^2,2))};
%         raw_ws=raw_ws+1;
%     end
% end
% 
%   save([save_dir,'popyoon_movement_database.mat'],'raw_database');
%   
%   %create a version that is indexed by trial and scans within trial (24x10)
%   raw_database_trial_by_scan=cell(size(raw_database));
%   raw_database_trial_by_scan(1,:)=raw_database(1,:);
%   raw_database_trial_by_scan(2:end,1:2)=raw_database(2:end,1:2);
%   
%   raw_database_trial_by_scan(2:end,3:end)=cellfun(@(x) reshape(x,10,24)',raw_database(2:end,3:end),'un',0);
%   save([save_dir,'popyoon_movement_database.mat'],'raw_database_trial_by_scan','-append');
%   
%   %% average movement parameter by accuracy and condition
%   database_separated_TS.GREEN=cell(size(raw_database_trial_by_scan));
%   database_separated_TS.GREEN(:,1:2)=raw_database_trial_by_scan(:,1:2);
%   database_separated_TS.GREEN(1,:)=raw_database_trial_by_scan(1,:);
%   database_separated_TS.RED=database_separated_TS.GREEN;
%   ws=2;
%   vect_dir='/nfs/popyoon/behav/';
%   for s = 1:length(subjects)
%       %make vectors
%       for ru = 1:length(runs)
%           clear CUEGREENTC CUEREDTC Y I ONSET;
%           vectors = load([vect_dir,subjects{s},'/vectors_',runs{ru},'.mat']);
%           ONSET=[];
%           for n = 1:length(vectors.onsets)
%               ONSET=[ONSET,vectors.onsets{n}];
%           end
%           [Y,I]=sort(ONSET,2,'ascend');
%       
%           CUEGREENTC=ceil(find(I<=length(vectors.onsets{1}))./2);
%           CUEREDTC=ceil(find(I>length(vectors.onsets{1}) & I<=(length(vectors.onsets{1})+length(vectors.onsets{2})))./2);
% %           database_separated_TS(ws,3:end)=cellfun(@(x) ...
% %               [sum(x(CUEGREENTC,:),1);sum(x(CUEREDTC,:),1)],...
% %               raw_database_trial_by_scan(ws,3:end),'un',0);
% database_separated_TS.GREEN(ws,3:end)=cellfun(@(x) ...
%     x(CUEGREENTC,:),raw_database_trial_by_scan(ws,3:end),'un',0);
% database_separated_TS.RED(ws,3:end)=cellfun(@(x) ...
%     x(CUEREDTC,:),raw_database_trial_by_scan(ws,3:end),'un',0);
% 
%           ws=ws+1;
%       end   
%   end
%   save('/nfs/popyoon/analysis/movement_analysis/popyoon_movement_database.mat','database_separated_TS','-append');
%   
%   %% make movement worksheet
%   cond={'GREEN','RED'};
%   movement_TS=struct();
%   for n = 1:2
%       clear movement_worksheet ws;
%       numbering={'01','02','03','04','05','06','07','08','09','10'};
%       movement_worksheet=cell(size(database_separated_TS,1),22);
%       movement_worksheet(:,1:2)=database_separated_TS(:,1:2);
%       movement_worksheet(1,3:12)=cellfun(@(x) ['GeoDist','_',x],numbering,'un',0);
%       movement_worksheet(1,13:22)=cellfun(@(x) ['GeoDistSP','_',x],numbering,'un',0);
%       for m = 2:size(movement_worksheet,1)
%         movement_worksheet(m,3:12)=num2cell(database_separated_TS{m,6}(n,:));
%         movement_worksheet(m,13:22)=num2cell(database_separated_TS{m,14}(n,:));
%       end
%       movement_TS.(cond{n})=movement_worksheet;
%   end
% 
%   %save('/nfs/popyoon/analysis/movement_analysis/popyoon_movement_database.mat','movement_TS','-append');
%   postproc_cell2csv('GREEN_CUE_movement_timeseries.csv',movement_TS.GREEN,',');
%   postproc_cell2csv('RED_CUE_movement_timeseries.csv',movement_TS.RED,',');
%   
%   %% average over runs
%    cond={'GREEN','RED'};
%   final_TS=struct();
%   [~,I,J]=unique(movement_TS.GREEN(2:end,1),'last');
%   I= [0;I];
% 
%   final_worksheet=struct();
%   for n = 1:2
%       clear worksheet data_mat;
%       worksheet=cell(length(subjects)+1,size(movement_TS.(cond{n}),2)-1);
%       worksheet(2:end,1)=subjects;
%       worksheet(1,:)=movement_TS.(cond{n})(1,2:end);
%         worksheet(1,1)={'Subjects'};
%       data_mat=cell2mat(movement_TS.(cond{n})(2:end,3:end));
%       for m = 2:(length(I))
%           %take average across all the runs
%           worksheet(m,2:end)=num2cell(mean(data_mat((I(m-1)+1):I(m),:),1));
%       end
%       final_worksheet.(cond{n})=worksheet;
%   end
%    save('/nfs/popyoon/analysis/movement_analysis/popyoon_movement_database.mat','final_worksheet','-append');
%   postproc_cell2csv('GREEN_CUE_movement_timeseries_avg.csv',final_worksheet.GREEN,',');
%   postproc_cell2csv('RED_CUE_movement_timeseries_avg.csv',final_worksheet.RED,',');
%   
%   
%   %% create raw time series
%   A=database_separated_TS_by_cond;
%   cond={'GREEN','RED'};
%   [~,I,J]=unique(A.GREEN(2:end,1));
%   I=[0;I]+1;
% 
%   for n = 1:length(cond)
%       clear worksheet data_mat;
%       worksheet=cell(length(subjects)+1,3);
%       worksheet(2:end,1)=subjects;
%       worksheet(1,:)={'Subjects','Mag_disp','Mag_speed'};
%       for m = 1:length(subjects)
%           clear X Y;
%           X=A.(cond{n})((I(m)+1):I(m+1),6);
%           Y=A.(cond{n})((I(m)+1):I(m+1),14);
%         worksheet{m+1,2}=cell2mat(X);
%         worksheet{m+1,3}=cell2mat(Y);
%       end
%       concat_database.(cond{n})=worksheet;
%   end
%   save('/nfs/popyoon/analysis/movement_analysis/popyoon_movement_database.mat',...
%       'concat_database','-append');
%   %% time series correlations
% 
% cond={'CueGreenTC','CueRedTC'};
% cond2={'GREEN','RED'};
% corrl_worksheet=cell(size(concat_database.GREEN));
% corrl_worksheet(:,1)=concat_database.GREEN(:,1);
% corrl_worksheet(1,:)=concat_database.GREEN(1,:);
% p_worksheet=corrl_worksheet;
% CORRELATION=struct('CueGreenTC',[],'CueRedTC',[]);
% for n = 1:length(cond)
%     base_dir2=['/nfs/popyoon/analysis/timeseries_15vox/',cond{n},'/'];
%   for s = 1:length(subjects)
%       try 
%       clear temp_ts temp_disp temp_speed;
%       temp_ts = csvread([base_dir2,subjects{s},'_',cond{n},'.csv']);
%       temp_ts=temp_ts(:,6:7)';
%       temp_disp=concat_database.(cond2{n}){s+1,2}(:,6:7)';
%       temp_speed=concat_database.(cond2{n}){s+1,3}(:,6:7)';
%       clear R P;
%       [R,P]=corrcoef(temp_ts(:),temp_disp(:));
%       R=R(1,2);
%       P=P(1,2);
%       corrl_worksheet{s+1,2}=R;
%       p_worksheet{s+1,2}=P;
%       clear R P;
%       [R,P]=corrcoef(temp_ts(:),temp_speed(:));
%       R=R(1,2);
%       P=P(1,2);
%       corrl_worksheet{s+1,3}=R;
%       p_worksheet{s+1,3}=P;
% 
%       CORRELATION.(cond{n}).corrl_worksheet=corrl_worksheet;
%         CORRELATION.(cond{n}).p_worksheet=p_worksheet;
%       catch 
%           continue;
%       end
%   end
%   
%   
% end
% %save(['/nfs/popyoon/analysis/timeseries_unsmoothed_81_percent_overlap_SNROI/CORRELATION_worksheet.mat'],'CORRELATION');
% 
% postproc_cell2csv('CueGreen_corrl_scan6_7.csv',CORRELATION.CueGreenTC.corrl_worksheet,',');
% postproc_cell2csv('CueGreen_p_scan6_7.csv',CORRELATION.CueGreenTC.p_worksheet,',');
% postproc_cell2csv('CueRed_corrl_scan6_7.csv',CORRELATION.CueRedTC.corrl_worksheet,',');
% postproc_cell2csv('CueRed_p_scan6_7.csv',CORRELATION.CueRedTC.p_worksheet,',');
% 
% 
% %% plot worksheet histogram
% subjects = worksheet(2:end,1);
% subjects = unique(subjects);
% runs = worksheet(2:end,2);
% RMS.disp.magTS = cell2mat(worksheet(2:end,11));%A
% RMS.speed.magTS = cell2mat(worksheet(2:end,29));
% for xx = 1:length(unique(subjects))
%     temp_vect_disp(xx) = mean(RMS.disp.magTS((1+4*(xx-1)):(4*xx)));
%     temp_vect_speed(xx) = mean(RMS.speed.magTS((1+4*(xx-1)):(4*xx)));
% end
% RMS.disp.magTS = temp_vect_disp';
% RMS.speed.magTS = temp_vect_speed';
% clearvars temp*;
% PN = {'disp','speed'};%parameter names
% 
% for p = 2%1:length(PN)
%     bin_size = 10;
%     RMS.(PN{p}).hist= hist(RMS.(PN{p}).magTS,bin_size);%B
%     RMS.(PN{p}).hist_vect= zeros(1,length(RMS.(PN{p}).magTS));
%     clear intervals bins;
%     intervals = linspace(min(RMS.(PN{p}).magTS),max(RMS.(PN{p}).magTS),bin_size+1);
%     intervals = num2cell(intervals);
%     bins = cellfun(@(x,y) [x,y],intervals(1:end-1),intervals(2:end),'UniformOutput',false);
%     
%     %get a vector that indicates which bin each subject x run belongs to
%     for n = 1:length(RMS.(PN{p}).magTS)
%         %for the rest, if there is a value that is at the edge of the bin,
%         %use the left (smaller) bin
%         tmp = find(cell2mat(cellfun(@(x) min(x)<=RMS.(PN{p}).magTS(n) & ...
%             max(x)>RMS.(PN{p}).magTS(n),bins,'UniformOutput',false)));
%         if ~isempty(tmp)
%             RMS.(PN{p}).hist_vect(1,n) = tmp;
%         end
%         clear tmp;
%     end
%     
%     [~,min_IND]=min(RMS.(PN{p}).magTS);
%     [~,max_IND]=max(RMS.(PN{p}).magTS);
%     RMS.(PN{p}).hist_vect(min_IND) = 1;%minimum belongs to first bin
%     RMS.(PN{p}).hist_vect(max_IND) = bin_size;%maxmum belongs to last bin
%     
%     temp_cell = cell(1,length(bins));
%     for m = 1:length(bins)
%         temp_cell{m}(1,:)= subjects(RMS.(PN{p}).hist_vect==m);
%         %temp_cell{m}(2,:)= runs(RMS.(PN{p}).hist_vect==m);
%     end
%     
%     %temp_cell = cellfun(@(x) strrep(x,'run','-run'),temp_cell,'Un',0);
%     %temp_cell = cellfun(@(x) strcat(x(1,:),x(2,:)),temp_cell,'Un',0);
%     %max_len = max(cellfun(@(x) length(x),temp_cell));
%     RMS.(PN{p}).subject_bin = temp_cell;
%     %clear temp_cell;
% end
% 
%  
%   
% % hist(RMS.disp.magTS,bin_size);
% % xlabel('RMS of magnitude of displacement (mm)');
% % ylabel('Number of subjects x runs');
% % title('Adolescent POP: RMS Displacement Histogram');
% % set(gcf,'Position',[100,100 2000 400]);
% % 
% % hist(RMS.speed.magTS,bin_size);
% % xlabel('RMS of magnitude of speed (mm/scan)');
% % ylabel('Number of subjects x runs');
% % title('Adolescent POP: RMS Speed Histogram');
% % set(gcf,'Position',[100,100 2000 400]);
% pnn ='disp';
% clear worksheet;
% for i = 1:length(RMS.(pnn).subject_bin)
%     for j = 1:length(RMS.(pnn).subject_bin{i})
%         worksheet2{i,j} = RMS.(pnn).subject_bin{i}{j};
%     end
% end
% 
% addpath(genpath('/nfs/r21_gaba/image_reg2'));
% postproc_cell2csv([pnn,'_subject.csv'],worksheet2,',');
% 
%   
% %% summarize by conditions
% conds = {'GREEN','RED'};
% worksheet.GREEN = cell(34,3);
% worksheet.GREEN(1,:) = {'Subjects','RMS_mag_disp','RMS_mag_speed'};
% worksheet.GREEN(:,1) = concat_database.GREEN(:,1);
% worksheet.RED = cell(34,3);
% worksheet.RED=  worksheet.GREEN;
% concat_database.GREEN(2:end,2:3) = cellfun(@(x) x(:,6:7),concat_database.GREEN(2:end,2:3),'un',0);
% concat_database.RED(2:end,2:3) = cellfun(@(x) x(:,6:7),concat_database.RED(2:end,2:3),'un',0);
% RMS_func = @(x) sqrt(mean((x(:)').^2));
% for c = 1:length(conds)
%         worksheet.(conds{c})(2:end,2:3) = cellfun(RMS_func,concat_database.(conds{c})(2:end,2:3),'un',0);
% end
% postproc_cell2csv('Green_mov_sum.csv',worksheet.GREEN,',');
% postproc_cell2csv('Red_mov_sum.csv',worksheet.RED,',');
% 
% %% summarize by both runs and conditions
% new_data.GREEN = database_separated_TS_by_cond.GREEN(:,[1:2,6,14]);
% new_data.GREEN(2:end,3:4) = cellfun(@(x) x(:,6:7),new_data.GREEN(2:end,3:4),'un',0);
% new_data.RED = database_separated_TS_by_cond.RED(:,[1:2,6,14]);
% new_data.RED(2:end,3:4) = cellfun(@(x) x(:,6:7),new_data.RED(2:end,3:4),'un',0);
% conds = {'GREEN','RED'};
% worksheet.GREEN = cell(133,4);
% worksheet.GREEN(1,:) = {'Subjects','run','RMS_mag_disp','RMS_mag_speed'};
% worksheet.GREEN(:,1:2) = new_data.GREEN(:,1:2);
% worksheet.RED = cell(133,4);
% worksheet.RED=  worksheet.GREEN;
% RMS_func = @(x) sqrt(mean((x(:)').^2));
% for c = 1:length(conds)
%         worksheet.(conds{c})(2:end,3:4) = cellfun(RMS_func,new_data.(conds{c})(2:end,3:4),'un',0);
% end
% postproc_cell2csv('Green_mov_sum.csv',worksheet.GREEN,',');
% postproc_cell2csv('Red_mov_sum.csv',worksheet.RED,','); 
%   
% %% average over runs for each condition
% data_mat.GREEN = cell2mat(worksheet.GREEN(2:end,3:4));
% data_mat.RED = cell2mat(worksheet.RED(2:end,3:4));
% 
% data_avg.GREEN = blockproc(data_mat.GREEN,[4,2],@(block_struct) mean(block_struct.data,1));
% data_avg.RED = blockproc(data_mat.RED,[4,2],@(block_struct)mean(block_struct.data,1));
% 
% avg_worksheet.GREEN = cell(34,3);
% avg_worksheet.GREEN(:,1) = unique(worksheet.GREEN(:,1));
% avg_worksheet.GREEN(1,:) = worksheet.GREEN(1,[1,3:4]);
% avg_worksheet.RED= avg_worksheet.GREEN;
% 
% avg_worksheet.GREEN(2:end,2:3) = num2cell(data_avg.GREEN);
% avg_worksheet.RED(2:end,2:3) = num2cell(data_avg.RED);
% 
% postproc_cell2csv('Green_mov_sum_avg_run.csv',avg_worksheet.GREEN,',');
% postproc_cell2csv('Red_mov_sum_avg_run.csv',avg_worksheet.RED,','); 
% 
% 
% %% scan 6 and scan 7 
% worksheet.GREEN = cell(133,4);
% worksheet.GREEN(:,1:2) = database_separated_TS.GREEN(:,1:2);
% worksheet.GREEN(1,:) = database_separated_TS.GREEN(1,[1:2,6,14]);
% worksheet.RED = worksheet.GREEN;
% worksheet.ALL = worksheet.RED;
% 
% worksheet.GREEN(2:end,3:4) = cellfun(@(x) mean2(x(:,6:7)),...
%     database_separated_TS.GREEN(2:end,[6,14]),'un',0);
% worksheet.RED(2:end,3:4) = cellfun(@(x) mean2(x(:,6:7)),...
%     database_separated_TS.RED(2:end,[6,14]),'un',0);
% 
% worksheet.ALL(2:end,3:4) = cellfun(@(x,y) mean2([x(:,6:7);y(:,6:7)]),...
%     database_separated_TS.GREEN(2:end,[6,14]),...
%     database_separated_TS.RED(2:end,[6,14]),'un',0);
% 
% postproc_cell2csv('Green_run.csv',worksheet.GREEN,',');
% postproc_cell2csv('Red_run.csv',worksheet.RED,','); 
% postproc_cell2csv('All_run.csv',worksheet.ALL,','); 
% 
% 
% 
% %% average BOLD by runs
% base_dir = '/nfs/popyoon/analysis/';
% vect_dir = '/nfs/popyoon/behav/';
% ROI_name = 'timeseries_unsmoothed_81_percent_overlap_SNROI';
% cue_cond = {'CueGreenTC','CueRedTC'};
% 
% subjects = {'popc004', 'popc010', ...
%     'popc011', 'popc012', ...
%     'popc013', 'popc014', 'popc016', 'popc018',...
%     'popc019','popc020','popc021','popc022','popc023','popc024',...
%     'popc025','popc026','popc027',...
%     'popc028',...'popc029',...
%     'popc030',...
%     'popc031','popc032','popc033','popc035','popc036','popc041',...
%     'popc042','popc043','popc044','popgc001','popgc002'...
%     'popgc003','popgc004','popgc005'};
% 
% runs={'run1','run2','run3','run4'};
% % 
% % worksheet = cell(133,12);
% % worksheet(:,1:2) = database_separated_TS.GREEN(:,1:2);
% % worksheet(1,1:2) = database_separated_TS.GREEN(1,1:2);
% % worksheet(1,3:12) = {'Scan1','Scan2','Scan3','Scan4','Scan5','Scan6','Scan7','Scan8','Scan9','Scan10'};
% % %{'GREEN','RED','ALL','GREEN67','RED67','ALL67'};
% 
% counter = 2;
% for s = 1:length(subjects)
%     clear TS;
%     TS.GREEN = csvread([base_dir,ROI_name,'/CueGreenTC/',subjects{s},'_CueGreenTC.csv']);
%     TS.GREEN = (TS.GREEN / mean2(TS.GREEN))*100-100;
%     TS.RED = csvread([base_dir,ROI_name,'/CueRedTC/',subjects{s},'_CueRedTC.csv']);
%     TS.RED = (TS.RED / mean2(TS.RED))*100-100;
%     len.GREEN = zeros(1,4);
%     len.RED = zeros(1,4);
%     %get vector position
%     
%     for r = 1:length(runs)
%         clear onsets;
%         load([vect_dir,subjects{s},'/vectors_',runs{r},'.mat'],'onsets');
%         len.GREEN(r) = length(onsets{1});
%         len.RED(r) = length(onsets{2});
%     end
% 
%     
%     len2 = structfun(@(x) [0,cumsum(x)] ,len,'un',0);
%  
%     for r = 1:length(runs)
%         %try
%         tmp1=mean(TS.GREEN((len2.GREEN(r)+1):len2.GREEN(r+1),:),1);
%         tmp1 = tmp1 - tmp1(1);
%         worksheet{counter,3} = mean2(tmp1);
%         tmp2 = mean(TS.RED((len2.RED(r)+1):len2.RED(r+1),:),1);
%         tmp2 = tmp2 -tmp2(1);
%         worksheet{counter,4} = mean2(tmp2);
%         tmp3 = (tmp1*len.GREEN(r) + tmp2*len.RED(r))/(len.GREEN(r) + len.RED(r));
%         tmp3 = tmp3 - tmp3(1);
%         worksheet{counter,5} = mean2(tmp3);
%         clearvars tmp*;
%         tmp1=mean(TS.GREEN((len2.GREEN(r)+1):len2.GREEN(r+1),6:7),1);
%         tmp1 = tmp1 - tmp1(1);
%         worksheet{counter,6} = mean2(tmp1);
%         tmp2 = mean(TS.RED((len2.RED(r)+1):len2.RED(r+1),6:7),1);
%         tmp2 = tmp2 -tmp2(1);
%         worksheet{counter,7} = mean2(tmp2);
%         tmp3 = (tmp1*len.GREEN(r) + tmp2*len.RED(r))/(len.GREEN(r) + len.RED(r));
%         tmp3 = tmp3 - tmp3(1);
%         worksheet{counter,8} = mean2(tmp3);
%         clearvars tmp*;
%         %catch
%         %end
% 
%         counter = counter+1;
%     end
% end
% 
% 
% postproc_cell2csv([ROI_name,'subj_by_run_worksheet.csv'],worksheet,',');
% 
% 
%   
%   