function job_file_lists = PIPE_contrasts_frac_back(subjects,type)

job_file_lists = {};

switch type
    case {'regular'}
        % regular GLM
        subj_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/GLM/';
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/jobfiles/contrast/';
        
        positive_cons{1} = {'InstructionBlock*bf(1)'};
        positive_cons{2} = {'ZeroBack*bf(1)'};
        positive_cons{3} = {'OneBack*bf(1)'};
        positive_cons{4} = {'TwoBack*bf(1)'};
        positive_cons{5} = {'NULL*bf(1)'};
        positive_cons{6} = {'ZeroBack*bf(1)'};
        positive_cons{7} = {'OneBack*bf(1)'};
        positive_cons{8} = {'TwoBack*bf(1)'};
        positive_cons{9} = {'OneBack*bf(1)'};
        positive_cons{10} = {'TwoBack*bf(1)'};
        positive_cons{11} = {'TwoBack*bf(1)'};
        positive_cons{12} = {'ZeroBack*bf(1)','OneBack*bf(1)','TwoBack*bf(1)'};
        positive_cons{13} = {'ZeroBack*bf(1)','OneBack*bf(1)','TwoBack*bf(1)'};
        
        
        negative_cons{1} = {'null'};
        negative_cons{2} = {'null'};
        negative_cons{3} = {'null'};
        negative_cons{4} = {'null'};
        negative_cons{5} = {'null'};
        negative_cons{6} = {'NULL*bf(1)'};
        negative_cons{7} = {'NULL*bf(1)'};
        negative_cons{8} = {'NULL*bf(1)'};
        negative_cons{9} = {'ZeroBack*bf(1)'};
        negative_cons{10} = {'ZeroBack*bf(1)'};
        negative_cons{11} = {'OneBack*bf(1)'};
        negative_cons{12} = {'null'};
        negative_cons{13} = {'NULL*bf(1)'};
        
        
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
        
    case {'combined'}
        %GLM combined
        subj_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/GLM_combined/';
        jobs_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/jobfiles/contrast_combined/';
        
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
    spm_loc = [subj_dir,subjects{n},'/SPM.mat'];
    contrasts = make_contrasts(spm_loc,positive_cons,negative_cons,name,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    job_file_lists{end+1} = [jobs_dir,subjects{n},'_contrast.mat'];
    save([jobs_dir,subjects{n},'_contrast.mat'],'matlabbatch');
end
