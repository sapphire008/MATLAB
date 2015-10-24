%batch behav analysis
%directory that contains the raw txt eprime files
source_behav_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/edat/';
%place where the analysis results and outputs will be stored
output_analysis_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/behav_analysis/extracted_behav/';
%subjects to process
% subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313',...
%     'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
%     'MP124_062113'};

subjects = {'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP125_072413'};

addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
column_headers = 'Image.ACC,condition,Image.RT,CorrectAns,Image.RESP';
ACC_name = 'ImageACC';
RT_name = 'ImageRT';
Condition_name = 'condition';
Stimulus_name = 'CorrectAns';
Response_name = 'ImageRESP';
ignore_case = {'NULL',''};%will replace occurence of ignore_case with NaN
%initialize worksheet headers
worksheet_header = {'Subjects',...
    'RT_ZeroBack','RT_OneBack','RT_TwoBack','RT_All',...
    'ACC_ZeroBack','ACC_OneBack','ACC_TwoBack','ACC_All',...
    'D_prime_ZeroBack','D_prime_OneBack','D_prime_TwoBack','D_prime_All',...
    'Bias_ZeroBack','Bias_OneBack','Bias_TwoBack','Bias_All',...
    'ResponseRate'};

%loop by conditions (optional,otherwise, specify in the custom block below)
%place holding
RT = struct();
ACC = struct();
%separate column names into cellstr
col_names = textscan(column_headers,'%s','delimiter',',');
col_names = col_names{1};
%initialize worksheet
worksheet = cell(length(subjects),length(worksheet_header));
worksheet(1,:) = worksheet_header;

for s = 1:length(subjects)
    %copy .txt file to output directory
    if ~exist(fullfile(output_analysis_dir,[subjects{s},'.csv']))
        eval(['!cp ',fullfile(source_behav_dir,[subjects{s},'.txt']), ...
            ' ',fullfile(output_analysis_dir,[subjects{s},'.txt'])]);
        %convert to csv file using perl script
        perl('edat2csv.pl',...
            fullfile(output_analysis_dir,[subjects{s},'.txt']),...
            column_headers);
    end
    %load behav worksheet
    behav_worksheet = ReadTable(fullfile(output_analysis_dir,...
        [subjects{s},'.csv']),'delimiter',',');
    %remove undesired values specified in the ignore_case cell array
    for kk = 1:length(ignore_case)
        behav_worksheet(strcmp(behav_worksheet,ignore_case{kk})) = ...
            cellfun(@(x) NaN('double'),behav_worksheet(strcmp(...
            behav_worksheet,ignore_case{kk})),'un',0);
    end
    % Analyze RT and ACC
    clear Condition_vect RT_vect ACC_vect Stimulus_vect Response_vect;
    %parse worksheet to each vectors
    RT_col = find(ismember(behav_worksheet(1,:),RT_name));
    RT_vect = cell2mat(behav_worksheet(2:end,RT_col));
    ACC_col = find(ismember(behav_worksheet(1,:),ACC_name));
    ACC_vect = cell2mat(behav_worksheet(2:end,ACC_col));
    Condition_col = find(ismember(behav_worksheet(1,:),Condition_name));
    Condition_vect = cell2mat(behav_worksheet(2:end,Condition_col));
    Stimulus_col =  find(ismember(behav_worksheet(1,:),Stimulus_name));
    Stimulus_vect = cell2mat(behav_worksheet(2:end,Stimulus_col));
    Response_col =  find(ismember(behav_worksheet(1,:),Response_name));
    Response_vect = cell2mat(behav_worksheet(2:end,Response_col));
    %analyze by conditions
    [RT,ACC] = analyze_RT_ACC(RT_vect,ACC_vect,'conditions',Condition_vect);
    %analyze without conditions
    [RT.Global,ACC.Global] = analyze_RT_ACC(RT_vect,ACC_vect);
    %find D' and Response Bias value for each conditions
    [D_prime,Bias] = analyze_SignalDetection(Stimulus_vect, Response_vect,6,'conditions',Condition_vect);
     %find D', Response Bias, and response rate without conditions
    [D_prime.Global,Bias.Global,~,~,RESP.Global] = analyze_SignalDetection(Stimulus_vect, Response_vect,6);
    
    % Write results to a worksheet (frac-back only)
    worksheet{s+1,1} = subjects{s};%subjects
    worksheet{s+1,2} = RT.cond_0;%RT_ZeroBack
    worksheet{s+1,3} = RT.cond_1;%RT_OneBack
    worksheet{s+1,4} = RT.cond_2;%RT_TwoBack
    worksheet{s+1,5} = RT.Global;%RT_All
    
    worksheet{s+1,6} = ACC.cond_0{find(ismember(ACC.cond_0(:,1),'1')),2};%ACC_ZeroBack
    worksheet{s+1,7} = ACC.cond_1{find(ismember(ACC.cond_1(:,1),'1')),2};%ACC_OneBack
    worksheet{s+1,8} = ACC.cond_2{find(ismember(ACC.cond_2(:,1),'1')),2};%ACC_TwoBack
    worksheet{s+1,9} = ACC.Global{find(ismember(ACC.Global(:,1),'1')),2};%ACC_All
    
    worksheet{s+1,10}=D_prime.cond_0;%D' ZeroBack
    worksheet{s+1,11}=D_prime.cond_1;%D' OneBack
    worksheet{s+1,12}=D_prime.cond_2;%D' TwoBack
    worksheet{s+1,13}=D_prime.Global;%D' value all
    
    worksheet{s+1,14}=Bias.cond_0;%Response Bias ZeroBack
    worksheet{s+1,15}=Bias.cond_1;%Response Bias OneBack
    worksheet{s+1,16}=Bias.cond_2;%Response Bias TwoBack
    worksheet{s+1,17}=Bias.Global;%Response Bias value all
    
    worksheet{s+1,18}=RESP.Global;%Response Rate all
end

cell2csv(fullfile(output_analysis_dir,'behav_analysis.csv'),worksheet,',','a+');