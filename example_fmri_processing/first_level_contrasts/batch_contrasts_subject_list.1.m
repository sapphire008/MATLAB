addspm8
addpath('~/example_behav_scripts/contrasts/');
subj_dir = '/nfs/atom/TMS/pilot/model/';
jobs_dir = '/tmp/';

subjects = {'mm'};

for n = 1:length(subjects),
    spm_loc = [subj_dir,subjects{n},'/SPM.mat'];
    contrasts = make_contrasts(spm_loc,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    eval(['save ',jobs_dir,'contrast_job_', subjects{n},' matlabbatch'])
end
