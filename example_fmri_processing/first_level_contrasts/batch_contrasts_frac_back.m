%addspm8
%addpath('~/example_scripts/contrasts/');
clear all;
%prefix = 'M*';
type = 'regular';

% subjects = {'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP121_060713','MP122_061213','MP123_061713','MP124_062113'};
%subjects = {'MP029_070213','MP030_070313'};
% subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
%     'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
%     'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
%     'MP029_070213','MP030_070313','MP032_071013','MP120_060513',...
%     'MP121_060713','MP122_061213','MP123_061713','MP124_062113'};
subjects = {'M3039_CNI_052714','M3126_CNI_042514','M3126_CNI_052314',...
    'M3127_CNI_050214','M3128_CNI_060314','M3129_CNI_060814'};
% 
% if strcmp(subjects(1).name,'.'),
%     subjects = subjects(3:end);
% end

switch type
    case {'regular'}
        % regular GLM
        subj_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/GLM/';
        jobs_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/jobfiles/contrast/';
        
        positive_cons{1} = {'Instruction*bf(1)'};
        positive_cons{2} = {'ZeroBack*bf(1)'};
        positive_cons{3} = {'OneBack*bf(1)'};
        positive_cons{4} = {'TwoBack*bf(1)'};
        positive_cons{5} = {'Fixation*bf(1)'};
        positive_cons{6} = {'ZeroBack*bf(1)'};
        positive_cons{7} = {'OneBack*bf(1)'};
        positive_cons{8} = {'TwoBack*bf(1)'};
        positive_cons{9} = {'OneBack*bf(1)'};
        positive_cons{10} = {'TwoBack*bf(1)'};
        positive_cons{11} = {'TwoBack*bf(1)'};
        positive_cons{12} = {'ZeroBack*bf(1)','OneBack*bf(1)','TwoBack*bf(1)'};
        positive_cons{13} = {'ZeroBack*bf(1)','OneBack*bf(1)','TwoBack*bf(1)'};
        positive_cons{14} = {'OneBack*bf(1)','TwoBack*bf(1)'};
        
        
        negative_cons{1} = {'null'};
        negative_cons{2} = {'null'};
        negative_cons{3} = {'null'};
        negative_cons{4} = {'null'};
        negative_cons{5} = {'null'};
        negative_cons{6} = {'Fixation*bf(1)'};
        negative_cons{7} = {'Fixation*bf(1)'};
        negative_cons{8} = {'Fixation*bf(1)'};
        negative_cons{9} = {'ZeroBack*bf(1)'};
        negative_cons{10} = {'ZeroBack*bf(1)'};
        negative_cons{11} = {'OneBack*bf(1)'};
        negative_cons{12} = {'null'};
        negative_cons{13} = {'Fixation*bf(1)'};
        negative_cons{14} = {'ZeroBack*bf(1)'};
        
        
        name{1}='InstructionBlock-null';
        name{2}='ZeroBack-null';
        name{3}='OneBack-null';
        name{4}='TwoBack-null';
        name{5}='Fixation-null';
        name{6}='ZeroBack-Fixation';
        name{7}='OneBack-Fixation';
        name{8}='TwoBack-Fixation';
        name{9}='OneBack-ZeroBack';
        name{10}='TwoBack-ZeroBack';
        name{11}='TwoBack-OneBack';
        name{12}='ZeroBack+OneBack+TwoBack-null';
        name{13}='ZeroBack+OneBack+TwoBack-Fixation';
        name{14}='OneBack+TwoBack -ZeroBack';
        
    case {'combined'}
        %GLM combined
        subj_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/GLM_combined/';
        jobs_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/jobfiles/contrast_combined/';
        
        positive_cons{1} = {'InstructionBlock*bf(1)'};
        positive_cons{2} = {'ZeroBack+OneBack+TwoBack*bf(1)'};
        positive_cons{3} = {'NULL*bf(1)'};
        positive_cons{4} = {'ZeroBack+OneBack+TwoBack*bf(1)'};
        
        
        negative_cons{1} = {'null'};
        negative_cons{2} = {'null'};
        negative_cons{3} = {'null'};
        negative_cons{4} = {'NULL*bf(1)'};
        
        
        name{1}='InstructionBlock-null';
        name{2}='ZeroBack_OneBack_TwoBack-null';
        name{3}='Fixation-null';
        name{4}='ZeroBack_oneBack_TwoBack-Fixation';
end
for n = 1:length(subjects),
    clear spm_loc  contrasts matlabbatch;
    spm_loc = [subj_dir,subjects{n},'/SPM.mat'];
    contrasts = make_contrasts(spm_loc,positive_cons,negative_cons,name,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    save([jobs_dir,subjects{n},'_contrast.mat'],'matlabbatch');
end
