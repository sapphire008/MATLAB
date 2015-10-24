%quick normalize
disp('pausing before running ...');
pause(3600);
fprintf('start processing at %s...\n',datestr(now,'mm-dd-yyyy_HH:MM:SS'));
addmatlabpkg('fMRI_pipeline');
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/timeseries_Connectivity_conn/';
sub_dir = 'conn_%s/results/firstlevel/ANALYSIS_01/';
subjects={'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
    'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
    'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
    'MP030_070313','MP032_071013','MP033_071213','MP034_072213',...
    'MP035_072613','MP036_072913','MP037_080613','MP120_060513',...
    'MP121_060713','MP122_061213','MP123_061713','MP124_062113',...
    'MP125_072413'};
fullhead_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/fullhead/subjects/coreg_TR3_normalized/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/jobfiles/normalization/';

% initialize job file
matlabbatch{1}.spm.spatial.normalise.write.subj(length(subjects)).def = [];
matlabbatch{1}.spm.spatial.normalise.write.subj(length(subjects)).resample = [];
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78,-112,-70;78,76,85];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2,2,2];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;


for s = 1:length(subjects)
    % grab the files to be normalized
    P = SearchFiles(fullfile(base_dir,subjects{s},sprintf(sub_dir,subjects{s})),...
        'corr*.nii');
    % get the fullhead
    F = SearchFiles(fullhead_dir,sprintf('y_*%s*_fullhead_average_brain.nii',subjects{s}));
    if isempty(P) || isempty(F)
        continue;
    end
    % specify subject
    matlabbatch{1}.spm.spatial.normalise.write.subj(s).def = F;
    matlabbatch{1}.spm.spatial.normalise.write.subj(s).resample = P;
end

save(fullfile(save_dir,'frac_back_conn_task_connectivity_normalization.mat'),'matlabbatch');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);