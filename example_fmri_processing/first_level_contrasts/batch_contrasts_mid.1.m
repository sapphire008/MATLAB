%addspm8
%addpath('~/example_scripts/contrasts/');
clear all;

prefix = '*';
type = 'regular';%visual, regular, alternative
    
% subjects = dir([subj_dir prefix]);
% 
% if strcmp(subjects(1).name,'.'),
%     subjects = subjects(3:end);
% end
% subjects = {subjects.name};

% subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
%     'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
%     'MP037_080613',...
%     'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
%     'MP124_062113','MP125_072413'};
subjects = {'M3039_CNI_052714','M3126_CNI_052314','M3128_CNI_060314','M3129_CNI_060814','M3129_CNI_060814_mux'};
%% conditions
switch type
    case {'regular'}
        subj_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/analysis/GLM_Cue_Feedback/';
        jobs_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/jobfiles/contrasts_Cue_Feedback_2mm/';
        %load contrast conditions
        load(fullfile(jobs_dir,'GLM_regular_contrast_conditions.mat'));
    case {'visual'}
        subj_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/analysis/GLM_visual/';
        jobs_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/jobfiles/contrasts_visual_2mm/';
    
        %set up contrast conditions
        positive_cons{1} = {'visual*bf(1)'};
        negative_cons{1} = {'null'};
    case {'alternative'}
        subj_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/analysis/GLM_Cue_Target/';
        jobs_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/jobfiles/contrasts_Cue_Target_2mm/';
        %load contrast conditions
        load(fullfile(jobs_dir,'GLM_alternative_contrast_conditions.mat'));
end

%% make contrasts
for s = 1:length(subjects)
    clear spm_loc contrasts matlabbatch;
    spm_loc = [subj_dir,subjects{s},'/SPM.mat'];
    contrasts = make_contrasts_mid(spm_loc,positive_cons,negative_cons,[],[],1,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    save([jobs_dir,subjects{s},'_',type,'_contrast.mat'],'matlabbatch');
end
