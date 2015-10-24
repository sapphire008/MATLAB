%summarize TCI
base_dir = '/nfs/jong_exp/midbrain_pilots/TCI/';
file_list = dir([base_dir,'*-scores-report.csv']);
file_list = {file_list.name};
addpath('/nfs/jong_exp/midbrain_pilots/scripts/');

worksheet = {};

for f = 1:length(file_list)
    clear tmp;
    tmp = ReadTable(fullfile(base_dir,file_list{f}));
    if f <2
        worksheet = tmp;
    else
        worksheet(end+1,:) = tmp(2,:);
    end 
end

cell2csv(fullfile(base_dir,'midbrain_TCI_summary.csv'),worksheet,',');