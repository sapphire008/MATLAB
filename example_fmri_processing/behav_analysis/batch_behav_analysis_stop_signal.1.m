%batch behav analysis
clear all;
%directory that contains the raw txt eprime files
source_behav_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/behav/';
%place where the analysis results and outputs will be stored
output_analysis_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/behav_analysis/';
%subjects to process
% subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
%     'MP024_052913','MP025_061013','MP120_060513','MP121_060713',...
%     'MP122_061213','MP123_061713','MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
%     'MP030_070313','MP124_062113'};
subjects = {'MP031_071813','MP032_071013','MP033_071213','MP034_072213',...
    'MP035_072613','MP036_072913','MP037_080613','MP125_072413'};
ACC_name = 'Accuracy';
RT_name = 'ReactionTime';
Condition_name = 'trial_type';
SSD_name = 'actualSSD';
ignore_case = {''};%will replace occurence of ignore_case with NaN
replace_with = 'null';
%initialize worksheet headers
worksheet_header = {'Subjects',...
    'RT_Go','RT_Go_Error','RT_StopResponse',...
    'RT_Go_ONLY','RT_Go_ONLY_Error','RT_All',...
    'ACC_Go','ACC_Stop','ACC_Go_ONLY','ACC_All',...
    'SSD_Mean','SSD_Std','SSRT'};


%loop by conditions (optional,otherwise, specify in the custom block below)
%place holding


addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
%initialize worksheet
worksheet = cell(length(subjects),length(worksheet_header));
worksheet(1,:) = worksheet_header;

for s = 1:length(subjects)
    %load behav worksheet
    behav_worksheet = ReadTable(fullfile(source_behav_dir,subjects{s},...
        [subjects{s},'.csv']),'delimiter',',');
    %remove undesired values specified in the ignore_case cell array
    for kk = 1:length(ignore_case)
        behav_worksheet(strcmp(behav_worksheet,ignore_case{kk})) = ...
            cellfun(@(x) replace_with,behav_worksheet(strcmp(...
            behav_worksheet,ignore_case{kk})),'un',0);
    end
    % Analyze RT and ACC
    clear Condition_vect RT_vect ACC_vect RT ACC;
    %parse worksheet to each vectors
    RT_col = find(ismember(behav_worksheet(1,:),RT_name));
    RT_vect = cell2mat(behav_worksheet(2:end,RT_col));
    ACC_col = find(ismember(behav_worksheet(1,:),ACC_name));
    ACC_vect = cell2mat(behav_worksheet(2:end,ACC_col));
    Condition_col = find(ismember(behav_worksheet(1,:),Condition_name));
    Condition_vect =cell2mat(behav_worksheet(2:end,Condition_col));
    %analyze by conditions
    [~,ACC] = analyze_RT_ACC(RT_vect,ACC_vect,'conditions',Condition_vect);
    %analyze without conditions
    [RT.Global,ACC.Global] = analyze_RT_ACC(RT_vect,ACC_vect);
    %analyze by both conditions and accuracy
    [RT.Correct,~] = analyze_RT_ACC(RT_vect(logical(ACC_vect)),...
        ACC_vect,'conditions',Condition_vect(logical(ACC_vect)));
    [RT.Incorrect,~]=analyze_RT_ACC(RT_vect(~ACC_vect),ACC_vect,...
        'conditions',Condition_vect(~ACC_vect));
    
    % Write results to a worksheet (stop-signal only)
    worksheet{s+1,1} = subjects{s};%subjects
    worksheet{s+1,2} = RT.Correct.cond_0;%RT_Go
    try
    worksheet{s+1,3} = RT.Incorrect.cond_0;%RT_Go_Error
    catch
    end
    try
    worksheet{s+1,4} = RT.Incorrect.cond_1;%RT_StopResponse
    catch
    end
    worksheet{s+1,5} = RT.Correct.cond_2;%RT_Go_ONLY
    try
    worksheet{s+1,6} = RT.Incorrect.cond_2;%RT_Go_ONLY_Error
    catch
    end
    worksheet{s+1,7} = RT.Global;%RT_All
    
    worksheet{s+1,8} = ACC.cond_0{find(ismember(ACC.cond_0(:,1),'1')),2};%ACC_Go
    worksheet{s+1,9} = ACC.cond_1{find(ismember(ACC.cond_1(:,1),'1')),2};%ACC_Stop
    worksheet{s+1,10} = ACC.cond_2{find(ismember(ACC.cond_2(:,1),'1')),2};%ACC_Go_ONLY
    worksheet{s+1,11} = ACC.Global{find(ismember(ACC.Global(:,1),'1')),2};%ACC_All
    
    % Analyze SSD and SSRT
    clear behav_worksheet;
    behav_worksheet = ReadTable(fullfile(source_behav_dir,subjects{s},...
        [subjects{s},'_raw_data.csv']),'delimiter',',');
    SSD_col = find(ismember(behav_worksheet(1,:),SSD_name));
    SSD_vect = cell2mat(behav_worksheet(2:end,SSD_col));
    SSD_vect(SSD_vect == 0) = nan('double');
    SSD.mean = nanmean(SSD_vect(:));
    SSD.std = nanstd(SSD_vect(:));
    SSRT = RT.Correct.cond_0 - SSD.mean;%GO RT - SSD.mean
    % save SSD info to worksheet
    worksheet{s+1,12} = SSD.mean;
    worksheet{s+1,13} = SSD.std;
    worksheet{s+1,14} = SSRT;
    
    
end
%fill in empty with null
empty_IND = cellfun(@isempty,worksheet);
worksheet(empty_IND) = cellfun(@(x) 'null',worksheet(empty_IND),'un',0);
cell2csv(fullfile(output_analysis_dir,'behav_analysis.csv'),worksheet,',','a+');