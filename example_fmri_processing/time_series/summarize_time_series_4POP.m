%summarize timeseries 4POP
source_dir = '/hsgs/projects/jhyoon1/sn_loc/analysis/time_series/MNI_space_reverse_normalized_pickatlas/extracted_time_series/';
save_dir = '/hsgs/projects/jhyoon1/sn_loc/analysis/time_series/MNI_space_reverse_normalized_pickatlas/extracted_time_series/';
subjects = {'AT10','AT11','AT13','AT14','AT15','AT17','AT22','AT23',...
    'AT24','AT26','AT29','AT30','AT31','AT32','AT33','AT36'};
file_ext = {'_wpickatlas_SNleft','_wpickatlas_SNright',...
    '_wpickatlas_STNleft','_wpickatlas_STNright'};
names = {'SNleft','SNright','STNleft','STNright'};
conditions = {'GreenCue','RedCue'};


for n = 1:length(file_ext)
    worksheet = cell(1,13);
    tmp = regexp(sprintf('scan%02.f;',[1:10]),';','split');
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