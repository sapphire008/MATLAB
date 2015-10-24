function job_file_lists = PIPE_contrasts_mid(subjects,type)
%% conditions
switch type
    case {'regular'}
        subj_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/GLM/';
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/mid/jobfiles/contrasts_2mm/';
        %load contrast conditions
        load(fullfile(jobs_dir,'GLM_regular_contrast_conditions.mat'));
    case {'visual'}
        subj_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/GLM_visual/';
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/mid/jobfiles/contrasts_visual_2mm/';
    
        %set up contrast conditions
        positive_cons{1} = {'visual*bf(1)'};
        negative_cons{1} = {'null'};
    case {'alternative'}
        subj_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/GLM_alternative/';
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/mid/jobfiles/contrasts_alternative_2mm/';
        %load contrast conditions
        load(fullfile(jobs_dir,'GLM_alternative_contrast_conditions.mat'));
end

%% make contrasts
job_file_lists = {};
for s = 1:length(subjects)
    clear spm_loc contrasts matlabbatch;
    spm_loc = [subj_dir,subjects{s},'/SPM.mat'];
    contrasts = make_contrasts_mid(spm_loc,positive_cons,negative_cons,[],[],1,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    job_file_lists{end+1} = [jobs_dir,subjects{s},'_contrast.mat'];
    save([jobs_dir,subjects{s},'_contrast.mat'],'matlabbatch');
end
end