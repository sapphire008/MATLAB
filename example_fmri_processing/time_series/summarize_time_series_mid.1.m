%summarize timeseries 4POP
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/time_series/extracted_time_series_first_3_img/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/time_series/extracted_time_series_first_3_img/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
file_ext = {'_TR2_SNleft','_TR2_STNleft'};
names = {'SNleft','STNleft'};
conditions =  {'Cue_lose5','Cue_lose1','Cue_lose0','Cue_gain0','Cue_gain1','Cue_gain5'};


for n = 1:length(file_ext)
    worksheet = cell(1,6);
    tmp = regexp(sprintf('scan%02.f;',[1:3]),';','split');
    worksheet(1,:) = [{'Subjects','ROI','Conditions'},tmp(1:end-1)];clear tmp;
    count = 1;
    
    for m = 1:length(conditions)
        for s = 1:length(subjects)
            tmp = csvread(fullfile(source_dir,conditions{m},...
                [subjects{s},'_',conditions{m},'_',file_ext{n},'.csv']));
            tmp = (tmp/mean(tmp(:)))*100-100;% convert to percent signal
            tmp = mean(tmp,1);% take the average
            count = count +1;
            worksheet{end+1,1} = subjects{s};
            worksheet{count,2} = names{n};
            worksheet{count,3} = conditions{m};
            worksheet(count,4:end) = num2cell(tmp);
            
        end
    end
    cell2csv(fullfile(save_dir,[names{n},'.csv']),worksheet,',');
end