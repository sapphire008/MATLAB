%addspm8
%addpath('~/example_scripts/contrasts/');
clear all;

model = 'GLM';% 'FIR' | 'GLM'
subj_dir = ['/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/analysis/',model,'/'];
jobs_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/jobfiles/contrasts/';
subjects = {'M3039_CNI_052714','M3126_CNI_052314','M3128_CNI_060314','M3129_CNI_060814'};
module_dir = [jobs_dir,model,'_contrasts_conditions_2runs.mat'];


%load contrast type file
load(module_dir);


for n = 1:length(subjects),
    spm_loc = [subj_dir,subjects{n},'/SPM.mat'];
    switch model
        case {'FIR'}
            % make names for FIR
            for m = 1:length(positive_cons)
                name{m} = construct_beta_names(positive_cons{m},negative_cons{m},0);
            end
    end
    contrasts = make_contrasts(spm_loc,positive_cons,negative_cons,name,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    save([jobs_dir,subjects{n},'_',model,'_contrast.mat'],'matlabbatch');
end
