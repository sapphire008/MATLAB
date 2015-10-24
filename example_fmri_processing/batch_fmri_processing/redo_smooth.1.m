% redo smoothing
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613','MP032_071013',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
tasks = {'4POP','mid','frac_back','stop_signal'};
blocks = {'block1','block2','block3','block4','block5','block6','block7','block8'};
func_dir = 'subjects/funcs/';
job_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/jobfiles/smooth/';

addmatlabpkg('fMRI_pipeline');clc;%addspm8;spm_jobman('initcfg');
for s = 1:length(subjects)
    disp(subjects{s});
    % initialize smooth job for current subject
    matlabbatch{1}.spm.spatial.smooth.data = {};
    matlabbatch{1}.spm.spatial.smooth.fwhm = [5,5,5];
    matlabbatch{1}.spm.spatial.smooth.dtype= 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = '5s';
    for t = 1:length(tasks)
        for b = 1:length(blocks)
            current_dir = fullfile(base_dir,tasks{t},func_dir,subjects{s},blocks{b});
            if ~exist(current_dir,'dir')
                continue;
            end
            % check file exist
            P_resample = SearchFiles(current_dir,'resample*.nii');
            P_resample_gz = SearchFiles(current_dir,'resample*.nii.tgz');
            P_sresample = SearchFiles(current_dir,'8sresample*.nii');
            P_sresample_gz = SearchFiles(current_dir,'8sresample*.nii.tgz');
            % if smoothed reample is not archived
            if ~isempty(P_sresample) && isempty(P_sresample_gz)
                %tar(fullfile(current_dir,'2sresample_rra.nii.tgz'),P_sresample);
                cellfun(@delete,P_sresample);
            elseif ~isempty(P_sresample_gz) && ~isempty(P_sresample)
                %if smooth is archived
                cellfun(@delete,P_sresample);
            end
            % if resample is archived but not unarchived
            if isempty(P_resample) && ~isempty(P_resample_gz)
                cwd = pwd;
                cd(current_dir);
                eval(['!tar -zxvf ',char(P_resample_gz)]);
                cd(cwd);
                P_resample = SearchFiles(current_dir,'resample*.nii');
            elseif ~isempty(P_resample) && isempty(P_resample_gz)
                %if resample is not archived
                tar(fullfile(current_dir,'resample_rra.nii.tgz'),P_resample);
            else
                fprintf('%s %s %s do not have ''resampled''\n',subjects{s},tasks{t},blocks{b});
                continue;
            end
            % specify files to be smoothed
            matlabbatch{1}.spm.spatial.smooth.data = [matlabbatch{1}.spm.spatial.smooth.data;P_resample(:)];
        end
    end
    % save smooth job files
    save(fullfile(job_dir,[subjects{s},'_5s.mat']),'matlabbatch');
    % run smooth
    spm_jobman('run',matlabbatch);
    % clean up
    cellfun(@delete,matlabbatch{1}.spm.spatial.smooth.data);
end


