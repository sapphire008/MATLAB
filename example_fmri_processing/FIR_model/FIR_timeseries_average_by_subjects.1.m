% summarize FIR time series
addmatlabpkg('ReadNWrite');
addmatlabpkg('fMRI_pipeline');
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/FIR/extracted_time_series/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/FIR/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
ROI_suffix = {'_TR2_SNleft','_TR2_STNleft','_TR2_RNleft',...
    '_TR2_SNright','_TR2_STNright','_TR2_RNright',...
    '_TR2_VTAleft','_TR2_VTAright','_TR2_VTAbilateral',...
    '_TR2_VTAleft_extended','_TR2_VTAright_extended','_TR2_VTAbilateral_extended',...
    '_TR2_SNVTAleft','_TR2_SNVTAright','_TR2_SNVTAbilateral',...
    '_TR2_VTA_blob','_TR2_SNVTA_blob'};
%event names, number of columns of the loaded worksheet
events = {'Cue_lose5','Cue_lose1','Cue_lose0','Cue_gain0','Cue_gain1','Cue_gain5'};
%number of time points, numer of rows of the loaded worksheet
numTRs = 5;

for r = 1:length(ROI_suffix)
    % place holding data matrix
    DATA = NaN(numTRs,numel(events),numel(subjects));
    for s = 1:length(subjects)
        P = char(SearchFiles(source_dir,[subjects{s},'*',ROI_suffix{r},'.csv']));
        if isempty(P)
            fprintf('%s:%s is empty,skipped\n',ROI_suffix{r},subjects{s});
            continue;
        end
        % read in the table
        P = ReadTable(P,'delimiter',',');
        % sort columns to the desired order
        IND = cellfun(@(x) find(ismember(P(1,:),x)),events,'un',0);
        K = cell(numTRs+1,numel(events));
        for m = 1:length(IND)
            if ~isempty(IND{m})
                K(:,m) = P(:,IND{m});
            else
                K{1,m} = events{m};
                K(2:end,m) = num2cell(NaN(numTRs,1));
            end
        end
        DATA(:,:,s) = cell2mat(K(2:end,:));
        clear K P IND;
    end
    % calculating stats of the data
    AVERAGE = [events;num2cell(squeeze(nanmean(DATA,3)))]';
    STDEV = [events;num2cell(squeeze(nanstd(DATA,[],3)))]';
    SERR = [events;num2cell(squeeze(nanstd(DATA,[],3))/sqrt(numel(subjects)))]';
    % combine into the same sheet
    worksheet = [AVERAGE;cell(2,size(AVERAGE,2));STDEV;cell(2,size(AVERAGE,2));SERR];
    % supply header
    worksheet = [{'Conditions'},cellfun(@(x) sprintf('TR%d',x),...
        num2cell(1:size(AVERAGE,2)-1),'un',0);worksheet];
    % save the stats to .csv file
    cell2csv(fullfile(save_dir,['summary',ROI_suffix{r},'.csv']),worksheet);
    clear worksheet DATA AVERAGE STDEV SERR
end