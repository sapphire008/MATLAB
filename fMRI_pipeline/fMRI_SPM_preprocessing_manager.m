%run my job
%addspm8;
addpath('/nfs/midbrain_highres_7t/scripts/');
% setting up job directories
job_dir = '/nfs/midbrain_highres_7t/jobfiles/';
template_subj = 'MP027_062713';%whose job file should be used as template?
subjects =  {'MP037_080613'};
%for replacing nifti names
func_dir ='/nfs/jong_exp/midbrain_pilots/';
tasks = {'mid','stop_signal','RestingState','frac_back'};%,'4POP'};
blocks = {'block1','block2','block3'};%,'block4','block5','block6','block7','block8'};
file_interest.func = 'f*.nii';%name of the nii files after dicom import
num_len = 4;%pad zeros in front of the number so that the numbering has this length
no_block  = {'RestingState'};%which task does not have block structure
%move movement file to a directory
movement_dir = '/nfs/jong_exp/midbrain_pilots/movement/';
file_interest.move = 'rp_a0001.txt';%target movement files
%reslice and resample
average_func_directory = '/nfs/jong_exp/midbrain_pilots/ROIs/';
average_type = {'TR2','TR3'};
file_interest.reslice_resample = 'ra*.nii';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% PART I: initialize processing structures and SPM job files
% % make folders for each subject
% % batch_make_folders(func_dir,[tasks,'fullhead'],...
% %     [cellstr(repmat('subjects/funcs',length(tasks),1));'subject/funcs'],...
% %     subjects,{'block',[2,3,0,3,0]});
% % copy job files for each subject
% %FOR: dicom import-->Needs to be inspected
% create_SPM_jobs(fullfile(job_dir,'dicom_import'),1,'.mat',template_subj,subjects);
% %FOR: 4D concatenation
% create_SPM_jobs(fullfile(job_dir,'4D'),1,'.mat',template_subj,subjects);
% %FOR: preprocessing
% create_SPM_jobs(fullfile(job_dir,'preproc'),1,'.mat',template_subj,subjects);
% %FOR: concatenated spatial realignment-->Need to be inspected
% create_SPM_jobs(fullfile(job_dir,'preproc'),1,'_concatenated_spatial_realignment.mat',template_subj,subjects);
% %FOR: average images
% create_SPM_jobs(fullfile(job_dir,'average_img_TR2'),1,'_TR2.mat',template_subj,subjects);
% create_SPM_jobs(fullfile(job_dir,'average_img_TR3'),1,'_TR3.mat',template_subj,subjects);
% %FOR: smoothing
% create_SPM_jobs(fullfile(job_dir,'smooth'),1,'.mat',template_subj,subjects);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% PART II: initialize SPM processing environment and run jobs
% addspm8;
% spm_jobman('initcfg');
% diary([job_dir,'/diary/spm_jobs_',date,'.txt']);
% %% do dicom import
% job_keyword = 'dicom_import';
% file_ext = '.mat';
% for s = 1:length(subjects)
%     spm_jobman('run',fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
% end
% %% change the name of the nifti files
% batch_rename(func_dir,tasks,subjects,blocks,no_block,file_interest.func,num_len);
% % run 4D concatenation
% job_keyword = '4D';
% file_ext = '.mat';
% for s = 1:length(subjects)
%     spm_jobman('run',fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
% end
% %% run time slicing and spatial relaignment
% job_keyword = 'preproc';
% file_ext = '.mat';
% for s = 1:length(subjects)
%     spm_jobman('run',fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
% end
% %% move movement files to another directory
% batch_relocate_files(func_dir,movement_dir,file_interest.move,tasks,...
%     subjects,blocks,no_block);
% %% run concatenated spatial realignment
% job_keyword = 'preproc';
% file_ext = '_concatenated_spatial_realignment.mat';
% for s = 1:length(subjects)
%     spm_jobman('run',fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
% end
% %% average TR2 and TR3 images
% job_keyword = 'average_img_TR2';
% file_ext = '_TR2.mat';
% for s = 1:length(subjects)
%     spm_jobman('run',fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
%     %make a copy of the average file
%     load(fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
%     outdir = matlabbatch{1,1}.spm.util.imcalc.outdir{1,1};
%     output = matlabbatch{1,1}.spm.util.imcalc.output;
%     eval(['!cp ',fullfile(outdir,output), ' ',fullfile(outdir,['Original_',output])]);
%     clear outdir output matlabbatch;
% end
% job_keyword = 'average_img_TR3';
% file_ext = '_TR3.mat';
% for s = 1:length(subjects)
%     spm_jobman('run',fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
%     %make a copy of the average file
%     load(fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
%     outdir = matlabbatch{1,1}.spm.util.imcalc.outdir{1,1};
%     output = matlabbatch{1,1}.spm.util.imcalc.output;
%     eval(['!cp ',fullfile(outdir,output), ' ',fullfile(outdir,['Original_',output])]);
%     clear outdir output matlabbatch;
% end
% 
% diary off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ACPC Realignment (Do it by hand)
%pause for now;
%% PART III: Reslice and Resample
batch_reslice_and_resample('reslice_averages',average_func_directory,average_type,subjects);
batch_reslice_and_resample('reslice_funcs',func_dir,tasks,subjects,blocks,no_block,file_interest.reslice_resample);
% Smooth
job_keyword = 'smooth';
file_ext = '.mat';
for s = 1:length(subjects)
    %run only 2s smooth
    clear tmp matlabbatch;
    tmp = load(fullfile(job_dir,job_keyword,[subjects{s},file_ext]));
    matlabbatch{1} = tmp.matlabbatch{1,2};
    spm_jobman('run',matlabbatch);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%