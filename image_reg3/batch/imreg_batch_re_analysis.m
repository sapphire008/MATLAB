% Initialization
restoredefaultpath;addpath(matlabroot);clc;clear all;
addpath(genpath('/nfs/r21_gaba/image_reg3'));
base_dir = '/nfs/r21_gaba/subjects/';
save_dir = '/nfs/r21_gaba/reprocessing/subjects/';%preprocessing save dir
results_dir = '/nfs/r21_gaba/reprocessing/results/preprocessing/';%post processing save dir

% Load source worksheet
A={'Subjects','Runs','Status'};
A(2:4,1) = {'VP093_101411'};
A(2:4,2) = {'run6_mprage','run7_mfg','run9_mfg'};
A(2:4,3) = {'Bad'};


% open a file to save outputs
[FID,MESSAGE] = fopen(fullfile(results_dir,'Processing_Notes7.txt'),'a');
fprintf(FID,'================Reprocessing===============');
fprintf(FID,['Processing started on ', datestr(now,'mm-dd-yyyy_HH-MM-SS'),'\n']);
tic;
%% Processing
for s =2%3:size(A,1);
    
    if strcmpi('DNE',A{s,3})
        continue;
    end
    disp([A{s,1},' : ',A{s,2}]);
    fprintf(FID,[A{s,1},' : ',A{s,2},'\n']);
    
    %load short_workspace 
    tmp_dir=dir(fullfile(save_dir,A{s,1},'movement',[A{s,2},'_analysis*']));
    if length(tmp_dir)>1
        disp('There are more than two directories. Skipped');
        fprintf(FID,'There are more than two directories. Skipped\n');
        continue;
    else
        try
        load(fullfile(save_dir,A{s,1},'movement',tmp_dir.name,'short_workspace.mat'),'params');
        catch ERR
            fprintf(FID,'Unable to load\n');
            fprintf(FID,[ERR.message,'\n']);
            disp(ERR.message);
            continue;
        end
        %archive the old older
        warning off;
        mkdir(fullfile(save_dir,A{s,1},'movement','archive'));
        warning on;

        %reset some parameters
        params.pxdist = [];
        if isnumeric(params.bin_thresh)
            params.bin_thresh = num2str(params.bin_thresh);
        end
        
        params.post_proc = 0;%Do you want to start post processing after this run?
        params.sample_rate = 5;%sampling rate (Hz)
        params.min_area = 350;%minimum area of the marker, used in primary cleaning
        params.edge_alg = 'Roberts';%edge finding algorithm
        params.pixels_to_mm = 'auto';%automatically use center distance to find the px2mm calibration
        params.save_workspace = 0;%Do you want to save the entire workspace, inlcuding loaded and processed images?
        params.home_dir = pwd;%home directory of the processing, will cd back when processing is done (not so necessary)
        params.interactive = false;%ask user if view images after the processing
        params.copy_jpegs = 0;% If flagged, raw jpegs are copied into the project dir (for debugging)
        params.display_final = 1;%do final check
        params.invert_image = false;%do not invert image
        params.manual_crop = true;%due manual crop
        params.save_dir = fullfile(save_dir,A{s,1},'movement');
        %params.bin_thresh = 'auto';
        
        %remove the old run file
%         eval(['!mv ',fullfile(save_dir,A{s,1},'movement',tmp_dir.name),...
%             ' ',fullfile(save_dir,A{s,1},'movement','archive',tmp_dir.name)]);
    end
    % Do the processing
    %     %find a window first
    %     params.Window = [];
    %     image_dir = dir([params.dir_name,'/*.jpg']);
    %     images(1).gray = imread([params.dir_name,'/',image_dir(1).name]);
    %     [images,params.Window] = imreg_window_batch(images, params);%crop images
    %     %archive the current workspace
    %     eval(['!mv ',fullfile(save_dir,A{s,1},'movement',tmp_dir.name,'short_workspace.mat'),...
    %         ' ',fullfile(save_dir,A{s,1},'movement',tmp_dir.name,'archived_short_workspace.mat')]);
    %     save(fullfile(save_dir,A{s,1},'movement',tmp_dir.name,'short_workspace.mat'),'params');
    try
        imreg_main_batch(params);
        A{s,3} = 'Good';
        %remove the old run file
        eval(['!mv ',fullfile(save_dir,A{s,1},'movement',tmp_dir.name),...
            ' ',fullfile(save_dir,A{s,1},'movement','archive',tmp_dir.name)]);

    catch
        fprintf('\n');
        warning([A{s,1},',',A{s,2},' imreg failed']);
        fprintf(FID,[A{s,1},',',A{s,2},' imreg failed\n']);
        continue;
    end
    
    

end

fprintf(FID,['time taken: ',num2str(toc),'s']);
fclose(FID);

% 
% params.save_dir = '/nfs/r21_gaba/subjects/VP087_091211/movement_VP087_091211/';
% params.dir_name = '/nfs/r21_gaba/subjects/VP087_091211/movement_VP087_091211/run3_mfg/';
% params.proj_dir = '/nfs/r21_gaba/subjects/VP087_091211/movement_VP087_091211/run3_mfg_analysis_28-Oct-2011/';


