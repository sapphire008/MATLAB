% One way ANOVA of unequal sample size
% formula used are from Wikipedia F-test: en.wikipedia.org/wiki/F-test
clear all;
sheet_name = 'scan67_15vox';
[NUMERIC,TXT,RAW]=xlsread([sheet_name,'.xls']);
group_num = cell2mat(RAW(3:end,5));
group_vect = {find(group_num == 1)'+2,find(group_num == 2)'+2 ,find(group_num == 3)'+2};
variables = [6:17];
clear worksheet;
worksheet = cell(3,13);
worksheet(1,:) = [{'F-test-scan67-81percent'},RAW(2,variables)];
worksheet{2,1} = 'F-values';
worksheet{3,1} = 'p-values';
sample_cell = {};
for v = 6:17
    clear grand_mean sample_cell sample_mean sample_length S_B ...
        df_b MS_B S_w df_w MS_W;
    %get samples of each group
    for m = 1:length(group_vect)
        sample_cell{m} = cell2mat(RAW(group_vect{m},v));
    end
    % Step 1: calculate mean within each group
    sample_mean = cellfun(@nanmean,sample_cell);
    % Step 2: calcualte overall mean
    grand_mean = nanmean(sample_mean);
    % Step 3: Calcualte Between-group mean square value
    sample_length = cellfun(@length,sample_cell);
    S_B = nansum((sample_mean-grand_mean).^2.*sample_length);
    df_b = length(sample_cell)-1;%between group degree of freedom
    MS_B = S_B/df_b;
    % Step 4: Caluclate Within-group mean square value
    S_w = cellfun(@(x) nansum((x-nanmean(x)).^2),sample_cell,'un',0);
    S_w = nansum(cell2mat(S_w));
    df_w = nansum(sample_length)-length(sample_cell);%within-group degree of freedom
    MS_W = S_w/df_w;
    % Step 5: Calcualte F ratio
    worksheet{2,v-4}= MS_B/MS_W;
    % Step 6: Caluclate p value
    worksheet{3,v-4} = fcdf(worksheet{2,v-4},df_b,df_w);
end

postproc_cell2csv([sheet_name,'-F-test.csv'],worksheet,',');