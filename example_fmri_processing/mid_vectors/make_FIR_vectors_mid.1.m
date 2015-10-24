base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/behav/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};

for s = 1:length(subjects)
    P = SearchFiles(fullfile(base_dir,subjects{s}),'*.csv');
    P = P(cellfun(@isempty,regexpi(P,'practice')));
    fprintf('%s:%d\n',subjects{s},length(P));
%     P = SearchFiles(fullfile(base_dir,subjects{s}),'vectors_run*.mat');
%     P = P(~cellfun(@isempty,regexp(P,'vectors_run(\d).mat')));
%     for m = 1:length(P)
%         load(P{m});
%         names = names(1:6);
%         durations = durations(1:6);
%         onsets = onsets(1:6);
%         save(fullfile(regexprep(P{m},'.mat','_FIR_Cue.mat')),'block','names','durations','onsets');
%         clear block names durations onsets;
%     end
%     clear P;
end


base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/subjects/funcs/';
for s = 1:length(subjects)
    P = SearchFiles(fullfile(base_dir,subjects{s}),'block*/2sresample*.nii');
    fprintf('%s:%d\n',subjects{s},length(P));
end