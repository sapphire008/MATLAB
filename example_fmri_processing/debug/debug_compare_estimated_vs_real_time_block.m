clear all; clc;
base_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/';

subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113'};
blocks = {'block1','block2','block3'};
for s = 1:length(subjects)
    for b = 1:length(blocks)
        clear A B;
        A = load(fullfile(base_dir, subjects{s},[blocks{b},'_vectors.mat']));
        B = load(fullfile(base_dir, subjects{s},[blocks{b},'_estimated_vectors']));
        for n = 1:length(A.onsets)
            
            clear tmp;
            
            tmp = A.onsets{n}-B.onsets{n};
            if abs(tmp)>0.3
                disp([subjects{s},'|',blocks{b},'|',A.names{n}]);
            else
                disp([subjects{s}, ' is okay']);
            end
            
            
        end
    end
end

% %
% for n = 1:length(A.onsets)
%    A.onsets{n}-B.onsets{n}
% end