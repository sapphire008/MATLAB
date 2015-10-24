base_dir = '/nfs/jong_exp/midbrain_Stanford_3T/funcs/M3020_Lucas_111513/stop_signal_run1';
% get a list of file
file_list = dir(fullfile(base_dir,'ra*.nii'));
file_list = cellfun(@(x) fullfile(base_dir,x),{file_list.name},'un',0);
% apply reslice_nii to each file, prepending 'r' in front of the new file,
% save to the same directory
FileFun(@reslice_nii,file_list,[],{'r','front'});

% get a list of file
file_list = dir(fullfile(base_dir,'rra*.nii'));
file_list = cellfun(@(x) fullfile(base_dir,x),{file_list.name},'un',0);
% apply reslice_nii to each file, prepending 'resample' in front of the 
% new file, save to the same directory
FileFun(@resample_nii,file_list,[],{'reample_','front'},[1,1,1]);