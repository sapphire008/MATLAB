clear all

addpath('/nfs/jong_exp/midbrain_pilots/scripts/');
behav_dir ='/nfs/jong_exp/midbrain_pilots/stop_signal/behav/';
subject_name = 'MP023_052013';
file_type = '1stop*.mat';
files = dir(fullfile(behav_dir,subject_name,file_type));


colHead= {'TrialNumber','NumChunksNum','Trial','ArrowDirection',...
    'LadderNumber','LadderNum_SSD','SubjectResponse','LadderMovement',...
    'RT','actualSSD','actualSSD_plusCMDtime','absoluteTime',...
    'TimeStartBlock','actualSSD','TrialDuration_trialcode',...
    'TimeCourse_trialcode'};

tmp_mat = [];
for n = 1:length(files)
    clear Seeker;
    load(fullfile(behav_dir,subject_name,files(n).name),'Seeker');
    tmp_mat = [tmp_mat;Seeker];
end
worksheet = cell(size(tmp_mat,1)+1,size(tmp_mat,2));
worksheet(1,:) = colHead;
worksheet(2:end,:) = num2cell(tmp_mat);

cell2csv([behav_dir,subject_name,'/',subject_name,'_raw_data.csv'],worksheet);