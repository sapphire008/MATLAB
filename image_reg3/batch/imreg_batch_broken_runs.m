% Initialization
restoredefaultpath;addpath(matlabroot);clc;clear all;
addpath(genpath('/nfs/r21_gaba/image_reg3'));
base_dir = '/nfs/r21_gaba/subjects/';
save_dir = '/nfs/r21_gaba/reprocessing/subjects/';%preprocessing save dir
results_dir = '/nfs/r21_gaba/reprocessing/results/';%post processing save dir
workspace_dir = '/nfs/r21_gaba/reprocessing/broken_runs_2/';

files = dir([workspace_dir,'*.mat']);
files = {files.name};

% open a file to save outputs
[FID,MESSAGE] = fopen(fullfile(results_dir,'Processing_Notes Broken Runs.txt'),'a');
fprintf(FID,'================Reprocessing===============');
fprintf(FID,['Processing started on ', datestr(now,'mm-dd-yyyy_HH-MM-SS'),'\n']);
tic;

broken_worksheet = {'Subjects','Runs','Success/Fail'};

%% Processing
for s = 4:length(files)
    clear tmp_name subject_name;
    tmp_name = regexp(files{s},'(\w*)_short_workspace.mat','tokens');
    disp(tmp_name{1}{1});
    fprintf(FID,[tmp_name{1}{1},'\n']);
    subject_name = regexp(tmp_name{1}{1},'VP\d\d\d_\d\d\d\d\d\d','match');
    
    %load short_workspace
    load(fullfile(workspace_dir,files{s}));
    
    % resetting parameters
    if isnumeric(params.bin_thresh)
        params.bin_thresh = num2str(params.bin_thresh);
    end
    params.save_dir = fullfile(save_dir,subject_name{1},'movement');
    params.auto_seg_match_template = false;
    params.post_proc = 0;%Do you want to start post processing after this run?
    params.sample_rate = 5;%sampling rate (Hz)
    params.min_area = 350;%minimum area of the marker, used in primary cleaning
    params.edge_alg = 'Roberts';%edge finding algorithm
    params.pixels_to_mm = 'auto';%automatically use center distance to find the px2mm calibration
    params.save_workspace = 0;%Do you want to save the entire workspace, inlcuding loaded and processed images?
    params.home_dir = pwd;%home directory of the processing, will cd back when processing is done (not so necessary)
    params.interactive = 0;%ask user if view images after the processing
    params.copy_jpegs = 0;% If flagged, raw jpegs are copied into the project dir (for debugging)
    params.display_final = false;%do final check
    params.invert_image = false;%do not invert image
    
    broken_worksheet{end+1,1}=subject_name{1};
    broken_worksheet{s+1,2}= params.project_name;
    
    % Do the processing
    try
        imreg_main_batch(params);
        %broken_worksheet{s+1,3} = 'Success';
    catch
        fprintf('\n');
        disp([tmp_name{1}{1},' imreg failed']);
        fprintf(FID,[tmp_name{1}{1},' imreg failed\n']);
        broken_worksheet{s+1,3}='Fail';
        continue;
    end
end
A= toc;
fprintf(FID,['time taken: ',num2str(A),'s']);
fclose(FID);