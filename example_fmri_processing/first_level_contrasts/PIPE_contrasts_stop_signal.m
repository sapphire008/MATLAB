function job_file_lists = PIPE_contrasts_stop_signal(subjects,varargin)
%addspm8
%addpath('~/example_scripts/contrasts/');
% clear all;
% 
% prefix = '*';
% model = 'HRF';
% type = 2;%include how many runs
% subjects = {'MP031_071813','MP034_072213','MP035_072613','MP125_072413'};
% 
type = varargin{1};
model = varargin{2};

switch model
    case {'FIR'}
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/jobfiles/FIR_contrast_2mm/';
        %load contrast type file
        load(['/nfs/jong_exp/midbrain_pilots/stop_signal/jobfiles/FIR_contrast_2mm/FIR_contrast_conditions_',...
            num2str(type),'_runs.mat']);
        switch type
            case {2}
                subj_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/FIR_GLM/';
            case {3}
                subj_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/FIR_GLM_with_GO_ONLY/';
        end
          
    case {'HRF'}
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/jobfiles/contrast_2mm/';
        switch type
            case {2}  
                % GLM 2 runs, excluding 3rd GO_ONLY run
                subj_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM/';
                load('/nfs/jong_exp/midbrain_pilots/stop_signal/jobfiles/contrast_2mm/GLM_contrasts_conditions_2runs.mat');
            case {3}
                % GLM 3 runs, including 3rd GO_ONLY run
                subj_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM_with_GO_ONLY/';
                load('/nfs/jong_exp/midbrain_pilots/stop_signal/jobfiles/contrast_2mm/GLM_contrasts_conditions_3runs.mat');
        end
end
        
%get subject list

% if strcmp(subjects(1).name,'.'),
%     subjects = subjects(3:end);
% end

job_file_lists = {};
for n = 1:length(subjects),
    spm_loc = [subj_dir,subjects{n},'/SPM.mat'];
    switch model
        case {'FIR'}
            for m = 1:length(positive_cons)
                name{m} = construct_beta_names(positive_cons{m},negative_cons{m},0);
            end
    end
    contrasts = make_contrasts(spm_loc,positive_cons,negative_cons,name,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    job_file_lists{end+1} = [jobs_dir,subjects{n},'_contrast_',num2str(type),'runs.mat'];
    save([jobs_dir,subjects{n},'_contrast_',num2str(type),'runs.mat'],'matlabbatch');
end
