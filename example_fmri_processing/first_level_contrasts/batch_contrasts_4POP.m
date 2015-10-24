%addspm8
%addpath('~/example_scripts/contrasts/');
clear all;


subjects = {'M3127_CNI_050214'};

% regular GLM
subj_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/analysis/GLM/';
jobs_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/jobfiles/contrast_2mm/';

positive_cons{1} = {'GreenCue_postTMS*bf(1)'};
positive_cons{2} = {'RedCue_postTMS*bf(1)'};
positive_cons{3} = {'GreenDelay_postTMS*bf(1)'};
positive_cons{4} = {'RedDelay_postTMS*bf(1)'};
positive_cons{5} = {'GreenProbe_postTMS*bf(1)'};
positive_cons{6} = {'RedProbe_postTMS*bf(1)'};
positive_cons{7} = {'GreenCue_postTMS*bf(1)','RedCue_postTMS*bf(1)'};
positive_cons{8} = {'GreenDelay_postTMS*bf(1)','RedDelay_postTMS*bf(1)'};
positive_cons{9} = {'GreenProbe_postTMS*bf(1)','RedProbe_postTMS*bf(1)'};
positive_cons{10}= {'GreenCue_postTMS*bf(1)','GreenDelay_postTMS*bf(1)','GreenProbe_postTMS*bf(1)'};
positive_cons{11}= {'RedCue_postTMS*bf(1)','RedDelay_postTMS*bf(1)','RedProbe_postTMS*bf(1)'};
positive_cons{12}= {'GreenCue_postTMS*bf(1)','GreenDelay_postTMS*bf(1)','GreenProbe_postTMS*bf(1)',...
    'RedCue_postTMS*bf(1)','RedDelay_postTMS*bf(1)','RedProbe_postTMS*bf(1)'};
positive_cons{13}= {'RedCue_postTMS*bf(1)','GreenCue_preTMS*bf(1)'};
positive_cons{14}= {'RedDelay_postTMS*bf(1)','GreenDelay_preTMS*bf(1)'};
positive_cons{15}= {'RedProbe_postTMS*bf(1)','GreenProbe_preTMS*bf(1)'};
positive_cons{16}= {'RedCue_postTMS*bf(1)','GreenCue_preTMS*bf(1)',...
    'RedDelay_postTMS*bf(1)','GreenDelay_preTMS*bf(1)',...
    'RedProbe_postTMS*bf(1)','GreenProbe_preTMS*bf(1)'};


negative_cons{1} = {'GreenCue_preTMS*bf(1)'};
negative_cons{2} = {'RedCue_preTMS*bf(1)'};
negative_cons{3} = {'GreenDelay_preTMS*bf(1)'};
negative_cons{4} = {'RedDelay_preTMS*bf(1)'};
negative_cons{5} = {'GreenProbe_preTMS*bf(1)'};
negative_cons{6} = {'RedProbe_preTMS*bf(1)'};
negative_cons{7} = {'GreenCue_preTMS*bf(1)','RedCue_preTMS*bf(1)'};
negative_cons{8} = {'GreenDelay_preTMS*bf(1)','RedDelay_preTMS*bf(1)'};
negative_cons{9} = {'GreenProbe_preTMS','RedProbe_preTMS*bf(1)'};
negative_cons{10}= {'GreenCue_preTMS*bf(1)','GreenDelay_preTMS*bf(1)','GreenProbe_preTMS*bf(1)'};
negative_cons{11}= {'RedCue_preTMS*bf(1)','RedDelay_preTMS*bf(1)','RedProbe_preTMS*bf(1)'};
negative_cons{12}= {'GreenCue_preTMS*bf(1)','GreenDelay_preTMS*bf(1)','GreenProbe_preTMS*bf(1)',...
    'RedCue_preTMS*bf(1)','RedDelay_preTMS*bf(1)','RedProbe_preTMS*bf(1)'};
negative_cons{13}= {'GreenCue_postTMS*bf(1)','RedCue_preTMS*bf(1)'};
negative_cons{14}= {'GreenDelay_postTMS*bf(1)','RedDelay_preTMS*bf(1)'};
negative_cons{15}= {'GreenProbe_postTMS*bf(1)','RedProbe_preTMS*bf(1)'};
negative_cons{16}= {'GreenCue_postTMS*bf(1)','RedCue_preTMS*bf(1)',...
    'GreenDelay_postTMS*bf(1)','RedDelay_preTMS*bf(1)',...
    'GreenProbe_postTMS*bf(1)','RedProbe_preTMS*bf(1)'};


names{1} ='GreenCue_postTMS_vs_preTMS';
names{2} ='RedCue_postTMS_vs_preTMS';
names{3} ='GreenDelay_postTMS_vs_preTMS';
names{4} ='RedDelay_postTMS_vs_preTMS';
names{5} ='GreenProbe_postTMS_vs_preTMS';
names{6} ='RedProbe_postTMS_vs_preTMS';
names{7} ='GreenCue+RedCue_postTMS_vs_preTMS';
names{8} ='GreenDelay+RedDelay_postTMS_vs_preTMS';
names{9} ='GreenProbe+RedProbe_postTMS_vs_preTMS';
names{10}='Green_all_postTMS_vs_preTMS';
names{11}='Red_all_postTMS_vs_preTMS';
names{12}='Green_all+Red_all_postTMS_vs_preTMS';
names{13}='RedCue-GreenCue_postTMS_vs_preTMS';
names{14}='RedDelay-GreenDelay_postTMS_vs_preTMS';
names{15}='RedProbe-GreenRedProbe_postTMS_vs_preTMS';
names{16}='Red_all-Green_all_postTMS_vs_preTMS';


for n = 1:length(subjects),
    clear spm_loc  contrasts matlabbatch;
    spm_loc = [subj_dir,subjects{n},'/SPM.mat'];
    contrasts = make_contrasts(spm_loc,positive_cons,negative_cons,names,1);
    matlabbatch = make_contrasts_jobs(spm_loc, contrasts);
    save([jobs_dir,subjects{n},'_contrast.mat'],'matlabbatch');
end


% 
% positive_cons{1} = {'GreenCue*bf(1)'};
% positive_cons{2} = {'RedCue*bf(1)'};
% positive_cons{3} = {'GreenDelay*bf(1)'};
% positive_cons{4} = {'RedDelay*bf(1)'};
% positive_cons{5} = {'GreenProbe*bf(1)'};
% positive_cons{6} = {'RedProbe*bf(1)'};
% positive_cons{7} = {'GreenCue*bf(1)'};
% positive_cons{8} = {'RedCue*bf(1)'};
% positive_cons{9} = {'GreenDelay*bf(1)'};
% positive_cons{10} = {'RedDelay*bf(1)'};
% positive_cons{11} = {'GreenProbe*bf(1)'};
% positive_cons{12} = {'RedProbe*bf(1)'};
% positive_cons{13} = {'GreenCue*bf(1)','RedCue*bf(1)'};
% positive_cons{14} = {'GreenDelay*bf(1)','RedDelay*bf(1)'};
% positive_cons{15} = {'GreenProbe*bf(1)','RedProbe*bf(1)'};
% positive_cons{16} = {'GreenCue*bf(1)','GreenDelay*bf(1)','GreenProbe*bf(1)'};
% positive_cons{17} = {'RedCue*bf(1)','RedDelay*bf(1)','RedProbe*bf(1)'};
% positive_cons{18} = {'GreenCue*bf(1)','GreenDelay*bf(1)','GreenProbe*bf(1)',...
%     'RedCue*bf(1)','RedDelay*bf(1)','RedProbe*bf(1)'};
% positive_cons{19} = {'GreenCue*bf(1)','GreenDelay*bf(1)','GreenProbe*bf(1)'};
% positive_cons{20} = {'RedCue*bf(1)','RedDelay*bf(1)','RedProbe*bf(1)'};
% 
% negative_cons{1} = {'null'};
% negative_cons{2} = {'null'};
% negative_cons{3} = {'null'};
% negative_cons{4} = {'null'};
% negative_cons{5} = {'null'};
% negative_cons{6} = {'null'};
% negative_cons{7} = {'RedCue*bf(1)'};
% negative_cons{8} = {'GreenCue*bf(1)'};
% negative_cons{9} = {'RedPDelay*bf(1)'};
% negative_cons{10} = {'GreenDelay*bf(1)'};
% negative_cons{11} = {'RedProbe*bf(1)'};
% negative_cons{12} = {'GreenProbe*bf(1)'};
% negative_cons{13} = {'null'};
% negative_cons{14} = {'null'};
% negative_cons{15} = {'null'};
% negative_cons{16} = {'null'};
% negative_cons{17} = {'null'};
% negative_cons{18} = {'null'};
% negative_cons{19} = {'RedCue*bf(1)','RedDelay*bf(1)','RedProbe*bf(1)'};
% negative_cons{20} = {'GreenCue*bf(1)','GreenDelay*bf(1)','GreenProbe*bf(1)'};
% 
% names{1}='GreenCue-null';
% names{2}='RedCue-null';
% names{3}='GreenDelay-null';
% names{4}='RedDelay-null';
% names{5}='GreenProbe-null';
% names{6}='RedProbe-null';
% names{7}='GreenCue-RedCue';
% names{8}='RedCue-GreenCue';
% names{9}='GreenDelay-RedDelay';
% names{10}='RedDelay-GreenDelay';
% names{11}='GreenProbe-RedProbe';
% names{12}='RedProbe-GreenProbe';
% names{13}='GreenCue+RedCue';
% names{14}='GreenDelay+RedDelay';
% names{15}='GreenProbe+RedProbe';
% names{16}='GreenCue+GreenDelay+GreenProbe';
% names{17}='RedCue+RedDelay+RedProbe';
% names{18}='GreenCue+GreenDelay+GreenProbe+RedCue+RedDelay+RedProbe';
% names{19}='(GreenCue+GreenDelay+GreenProbe)-(RedCue+RedDelay+RedProbe)';
% names{20}='(RedCue+RedDelay+RedProbe)-(GreenCue+GreenDelay+GreenProbe)';