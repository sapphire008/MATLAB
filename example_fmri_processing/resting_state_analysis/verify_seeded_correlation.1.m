% verify seeded correlation by extracting correlation value from the seed
% region
clear all;clc;
addmatlabpkg('fMRI_pipeline');
addspm8('NoConflicts');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/resting_state_analysis/
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/sources/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP022_051713',...
    'MP023_052013','MP024_052913','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP123_061713','MP124_062113','MP125_072413','TMS100','TMS200'};
ROIs = {'x*_TR3_SNleft.nii','x*_TR3_STNleft.nii'};

for s = 1:length(subjects)
    fprintf('%s\n',subjects{s});
    P = SearchFiles(fullfile(base_dir,subjects{s},['conn_',subjects{s}],...
        'results/firstlevel/ANALYSIS_01'),'corr*.nii');
    % Assuming the first file is the first ROI
    for r = 1:length(P)
        fprintf('ROI:%s\n',ROIs{r});
        % load image
        V = spm_vol(P{r});
        % get ROI index
        R = spm_vol(char(SearchFiles(ROI_dir,regexprep(ROIs{r},'\*',['*',subjects{s},'*']))));
        R = double(R.private.dat);
        [X,Y,Z] = ind2sub(size(R),find(R));
        XYZ = [X(:)';Y(:)';Z(:)'];
        clear X Y Z R;
        % get averaged ROI value
        Y = spm_get_data(V,XYZ);
        fprintf('ROI average:%.3f\n',mean(Y(:)));
        fprintf('ROI max:%.3f\n',max(Y(:)));
        clear XYZ Y;
        % get the global maximum value
        V = double(V.private.dat);
        fprintf('global max: %.3f\n',max(V(:)));
        clear V;
    end
    fprintf('\n');
end