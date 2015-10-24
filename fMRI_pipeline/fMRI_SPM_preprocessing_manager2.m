subjects = {'MP031_071813'};
average_func_directory = '/nfs/jong_exp/midbrain_pilots/ROIs/';
average_type = {'TR2','TR3'};
file_interest.reslice_resample = 'ra*.nii';


func_dir ='/nfs/jong_exp/midbrain_pilots/';
tasks = {'mid','stop_signal'};%,'4POP'};
blocks = {'block1','block2','block3'};%,'block4','block5','block6','block7','block8'};
no_block  = {'RestingState'};%which task does not have block structure

batch_reslice_and_resample('reslice_averages',average_func_directory,average_type,subjects);
batch_reslice_and_resample('reslice_funcs',func_dir,tasks,subjects,blocks,no_block,file_interest.reslice_resample);


%smoothing
spm_jobman('run','/nfs/jong_exp/midbrain_pilots/jobfiles/smooth/MP031_071813_TR2_only.mat');
