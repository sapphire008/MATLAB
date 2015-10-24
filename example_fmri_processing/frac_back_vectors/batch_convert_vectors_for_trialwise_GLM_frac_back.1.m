% converting existing vectors for regular GLM (combined all trials of the
% same condition) to trial-wise GLM (trials are separated)
addmatlabpkg('fMRI_pipeline');
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/behav/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
target_file = 'block(\d)_vectors.mat';

for s = 1:length(subjects)
    % list all the files to load
    files = dir(fullfile(base_dir,subjects{s}));
    files = {files(3:end).name};
    files = files(~cellfun(@isempty,regexp(files,target_file)));
    files = cellfun(@(x) fullfile(base_dir,subjects{s},x),files,'un',0);
    % transverse through all teh files
    for n = 1:length(files),
        load(files{n});
        old_names = names;
        old_onsets = onsets;
        old_durations = durations;
        names = {};
        onsets = {};
        durations = {};
        for k = 1:length(old_names)
            for j = 1:length(old_onsets{k})
                names{end+1} = [old_names{k},'_',num2str(n),'_',num2str(j)];
                onsets{end+1} = old_onsets{k}(j);
                durations{end+1} = old_durations{k};
            end
        end
        [PATHSTR,NAME,EXT] = fileparts(files{n});
        
        % append block number
        if ~exist('block','var')
            block = n;
        end
        % save the paramters
        save(fullfile(PATHSTR,[NAME,'_trialwise',EXT]),'names','onsets','durations');
    end
end

