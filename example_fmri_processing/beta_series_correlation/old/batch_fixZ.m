clc;
addspm5;
%addpath(genpath('/nfs/uhr08/code/connectivitycode/'))
addpath('~/beta_series_revised/')
pathstr = '/nfs/uhr08/conn_analysis_01_2009/subjects/';
roiFiles = '/nfs/uhr08/group/ROIs/LDLPFCROI.nii';
subIDs = dir([pathstr,'epc*']);
cues1 = {'CueA' 'bf(1)'};
cues2 = {'CueB' 'bf(1)'};
%cues3 = {'' 'bf(1)'};
%cues4 = {'DrugRedCue' 'bf(2)'};
trim = 0;

for s = 1:length(subIDs);
    SPM_loc = [pathstr,subIDs(s).name,'/SPM.mat'];
    %ROI_loc = [pathstr,'ROIs/',roiFiles.name];
    fixZmaps(SPM_loc,roiFiles,cues1,trim);
    fixZmaps(SPM_loc,roiFiles,cues2,trim);
end


    
    
    