%batch behav analysis
clear all;
%directory that contains the raw txt eprime files
source_behav_dir = '/nfs/jong_exp/midbrain_pilots/mid/behav/';
%place where the analysis results and outputs will be stored
output_analysis_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/behav_analysis/';
%subjects to process
% subjects = {'JY_052413_haldol','MP021_051713','MP022_051713','MP023_052013',...
%     'MP024_052913','MP025_061013','MP120_060513','MP121_060713',...
%     'MP122_061213','MP123_061713'};%
% subjects = {'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
%     'MP030_070313','MP124_062113'};
%subjects = {'MM_051013_haldol','MP020_050613'};
% subjects = {'MP031_071813','MP032_071013','MP033_071213','MP034_072213',...
%     'MP035_072613','MP036_072913','MP037_080613','MP125_072413'};
subjects = {'MP125_072413'};

ACC_name = 'hit';
RT_name = 'Drew_RT_all';
Condition_name = 'trialtype';
Trial_name = 'trial';
Total_Gain_name = 'total';
RT_trial_name = 'target_ms';
ignore_file = {'RUN0','practice'};%will ignore loading files with these characters in the name
ignore_case = {'NaN'};
replace_with = NaN('double');

%initialize worksheet headers
worksheet_header = {'Subjects',...
    'RT_Gain0','RT_Gain1','RT_Gain5',...
    'RT_Lose0','RT_Lose1','RT_Lose5',...
    'RT_Gain_All','RT_Neutral','RT_Lose_All','RT_All',...
    'ACC_Gain0','ACC_Gain1','ACC_Gain5',...
    'ACC_Lose0','ACC_Lose1','ACC_Lose5',...
    'ACC_Gain_All','ACC_Neutral','ACC_Lose_All','ACC_All',...
    'Money_Gain_Total','Average_Start_RT','Average_End_RT'};

%initialize worksheet
worksheet = cell(length(subjects),length(worksheet_header));
worksheet(1,:) = worksheet_header;

for s = 1:length(subjects)
    %find behav worksheet in .csv format
    file_list = dir(fullfile(source_behav_dir,subjects{s},'*b*.csv'));
    files = {};
    if isempty(file_list)
        disp(['skipped: ', subjects{s}]);
        continue;
    end
    %select correct files and do block-wise analysis
    behav_worksheet = {};%store behav for RT and ACC analysis
    current_file_count = 0;
    StartRT = [];%start RT of each block
    EndRT = [];%end RT of each block
    Money_Gain = {};%money gain at the end of each block
    for f = 1:length(file_list)
        if any(cell2mat(cellfun(@(x) ~isempty(strfind(...
                lower(file_list(f).name),x)),...
                lower(ignore_file),'un',0)))
            continue;
        else
            current_file_count = current_file_count+1;
            %load behav worksheet
            clear tmp_sheet;
            tmp_sheet = ReadTable(fullfile(...
                source_behav_dir,subjects{s},...
                file_list(f).name),'delimiter',',');
            %find index of unique rows
            [~,unique_IND] = unique(cell2mat((tmp_sheet(...
                2:end,find(ismember(tmp_sheet(1,:),Trial_name))))));
            
            if current_file_count <2
                behav_worksheet(1,:) = tmp_sheet(1,:);
            end
            %import behav_worksheet
            tmp_sheet = tmp_sheet(unique_IND+1,:);
            behav_worksheet = vertcat(behav_worksheet,tmp_sheet);
            %record data of current block
            %Start-End RT conditions
            StartRT(current_file_count) = tmp_sheet{1,find(...
                ismember(behav_worksheet(1,:),RT_trial_name))};
            EndRT(current_file_count) = tmp_sheet{end,find(...
                ismember(behav_worksheet(1,:),RT_trial_name))};
            Money_Gain{end+1} = tmp_sheet{end,find(...
                ismember(behav_worksheet(1,:),Total_Gain_name))};
        end
    end
    % Clean up behav worksheet, replace invalid character indicated by ignore_case
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
    [RT,ACC] = analyze_RT_ACC(RT_vect,ACC_vect,'conditions',Condition_vect);
    %analyze without conditions
    [RT.Global,ACC.Global] = analyze_RT_ACC(RT_vect,ACC_vect);
    %analyze combined conditions
    combined_conditions = zeros(length(Condition_vect),1);
    combined_conditions(Condition_vect == 1 | Condition_vect==4) = 2;%neutral
    combined_conditions(Condition_vect == 2 | Condition_vect==3) = 1;%lose
    combined_conditions(Condition_vect == 5 | Condition_vect==6) = 3;%win
    [RT.All,ACC.All] = analyze_RT_ACC(RT_vect,ACC_vect,...
        'conditions',combined_conditions);
    
    %storing Start and End in the RT structure
    RT.Start = nanmean(StartRT(:));
    RT.End = nanmean(EndRT(:));
    %Calculate average money gain
    Money_Gain = nansum(cell2mat(cellfun(@(x) str2double(strrep(x,'$','')),Money_Gain,'un',0)));
    
    % Write results to a worksheet (stop-signal only)
    eval_str{1}='worksheet{s+1,1} = subjects{s};%subjects';
    eval_str{2}='worksheet{s+1,2} = RT.cond_4;%RT_Gain0';
    eval_str{3}='worksheet{s+1,3} = RT.cond_5;%RT_Gain1';
    eval_str{4}='worksheet{s+1,4} = RT.cond_6;%RT_Gain5';
    eval_str{5}='worksheet{s+1,5} = RT.cond_1;%RT_Lose0';
    eval_str{6}='worksheet{s+1,6} = RT.cond_2;%RT_Lose1';
    eval_str{7}='worksheet{s+1,7} = RT.cond_3;%RT_Lose5';
    eval_str{8}='worksheet{s+1,8} = RT.All.cond_3;%RT_Gain_All';
    eval_str{9}='worksheet{s+1,9} = RT.All.cond_2;%RT_Neutral_All';
    eval_str{10}='worksheet{s+1,10} = RT.All.cond_1;%RT_Lose_All';
    eval_str{11}='worksheet{s+1,11} = RT.Global;%RT_All';
    
    eval_str{12}='worksheet{s+1,12} = ACC.cond_4{find(ismember(ACC.cond_4(:,1),''1'')),2};%ACC_Gain0';
    eval_str{13}='worksheet{s+1,13} = ACC.cond_5{find(ismember(ACC.cond_5(:,1),''1'')),2};%ACC_Gain1';
    eval_str{14}='worksheet{s+1,14} = ACC.cond_6{find(ismember(ACC.cond_6(:,1),''1'')),2};%ACC_Gain5';
    eval_str{15}='worksheet{s+1,15} = ACC.cond_1{find(ismember(ACC.cond_1(:,1),''1'')),2};%ACC_Lose0';
    eval_str{16}='worksheet{s+1,16} = ACC.cond_2{find(ismember(ACC.cond_2(:,1),''1'')),2};%ACC_Lose1';
    eval_str{17}='worksheet{s+1,17} = ACC.cond_3{find(ismember(ACC.cond_3(:,1),''1'')),2};%ACC_Lose5';
    eval_str{18}='worksheet{s+1,18} = ACC.All.cond_3{find(ismember(ACC.All.cond_3(:,1),''1'')),2};%ACC_Gain_All';
    eval_str{19}='worksheet{s+1,19} = ACC.All.cond_2{find(ismember(ACC.All.cond_2(:,1),''1'')),2};%ACC_Neutral_All';
    eval_str{20}='worksheet{s+1,20} = ACC.All.cond_1{find(ismember(ACC.All.cond_1(:,1),''1'')),2};%ACC_Lose_All';
    eval_str{21}='worksheet{s+1,21} = ACC.Global{find(ismember(ACC.Global(:,1),''1'')),2};%ACC_All';
    
    eval_str{22}='worksheet{s+1,22} = Money_Gain;%Money_Gain_Total';
    eval_str{23}='worksheet{s+1,23} = RT.Start;%Average_Start_RT';
    eval_str{24}='worksheet{s+1,24} = RT.End;%Average_End_RT';
    for eee = 1:length(eval_str)
        try
            eval(eval_str{eee});
        catch
        end
    end
    clear eval_str;
end
%fill in empty with null
empty_IND = cellfun(@isempty,worksheet);
worksheet(empty_IND) = cellfun(@(x) 'null',worksheet(empty_IND),'un',0);
cell2csv(fullfile(output_analysis_dir,'behav_analysis.csv'),worksheet,',','a+');