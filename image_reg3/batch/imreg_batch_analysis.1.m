% Initialization
restoredefaultpath;addpath(matlabroot);clc;clear all;
addpath(genpath('/nfs/r21_gaba/image_reg3'));
base_dir = '/nfs/r21_gaba/subjects/';
save_dir = '/nfs/r21_gaba/reprocessing/subjects/';%preprocessing save dir
results_dir = '/nfs/r21_gaba/reprocessing/results/';%post processing save dir
subjects = {'DD_102010',...
    'VP014_12512','VP020_061212','VP080_020411','VP081_021111',...
    'VP085_032111','VP086_042511','VP087_052011','VP087_091211',...
    'VP088_061011','VP089_061711','VP090_081011','VP091_090611',...
    'VP092_100511','VP092_100711','VP093_101411','VP094_102811',...
    'VP095_112811','VP097_121611','VP098_122111','VP099_021214',...
    'VP100_021512','VP101_041312','VP102_042312','VP103_061112',...
    'VP104_082412','VP105_090712','VP106_100512','VP107_110112',...
    'VP108_111912','VP109_011013','VP110_020513',...
    'VP508_022112','VP541_030411','VP541_113010','VP543_041111',...
    'VP544_052011','VP544_060811','VP545_052711','VP546_010912',...
    'VP546_062411','VP547_070111','VP548_071511','VP549_090911',...
    'VP550_092311','VP551_120811','VP552_031212','VP553_031312',...
    'VP553_031912','VP554_050212','VP554_2_050912','VP555_072312',...
    'VP556_072712','VP557_051613','VP557_080712','VP558_081012',...
    'VP559_091812','VP560_092812','VP561_100812','VP562_120612',...
    'VP562_121812','VP563_121112','VP564_012513','VP565_043013',...
    'VP700_092011','VP700_122311','VP701_121911'};
TARGET.movement_folders = {'move*','*movement','Motion'};
TARGET.run_folders = 'analysis';
TARGET.run_file = 'short_workspace.mat';
TARGET.preproc_var = 'params';
TARGET.postproc_file = 'mprage_movement_postproc.mat';
TARGET.postproc_var = 'runs';

%defaults
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

[FID,MESSAGE] = fopen(fullfile(results_dir,'Processing_Notes.txt'),'a');
fprintf(FID,['Processing started on ', datestr(now,'mm-dd-yyyy_HH-MM-SS'),'\n']);
tic;
%% Processing
for s = 33:67%:length(subjects)
    disp(subjects{s});
    fprintf(FID,[subjects{s},'\n']);
    clearvars tmp* K;
    for t = 1:length(TARGET.movement_folders)
        tmp = dir(fullfile(base_dir,subjects{s},TARGET.movement_folders{t}));
        if ~isempty(tmp)
            break;            
        end
    end
    %if none of the folder names are correct, display a message and skip it
    if isempty(tmp)
        disp([subjects{s},' is empty. Skipped']);
        continue;
    end
    %continue with the following script if not empty
    
    %current directory
    tmp_dir = fullfile(base_dir,subjects{s},tmp.name);
    %list all the files and folders
    tmp_files = dir(tmp_dir);
    %get all directories
    tmp_files = tmp_files(cell2mat({tmp_files.isdir}));
    %find which directory contains keywords
    K = arrayfun(@(x) regexp(x.name,TARGET.run_folders),tmp_files,'un',0);
    %get directories with keywords
    tmp_files = tmp_files(~cellfun(@isempty,K));
    
    % set a flag to see if postprocessing can be done
    flag = true;
    
    %% Pre-processing
    % transverse through all the analyzed folders
    for w = 1:length(tmp_files)
        clear tmp_source_dir tmp_params;
        %try to load the parameters
        try
            tmp_params = load(fullfile(tmp_dir,tmp_files(w).name,TARGET.run_file),TARGET.preproc_var);
        catch ERR
            fprintf(FID,[fullfile(tmp_dir,tmp_files(w).name,TARGET.run_file),' does not exist']);
            continue;
        end
        
        %parse parameters, use the parameters used before
        params.project_name = tmp_params.(TARGET.preproc_var).project_name;
        params.save_dir = fullfile(save_dir,subjects{s},'movement/');%result save directory
        mkdir(params.save_dir);%make directory to save the results
        tmp_source_dir = regexp(tmp_params.(TARGET.preproc_var).dir_name,'/','split');
        params.dir_name = fullfile(tmp_dir,tmp_source_dir{end});%source directory
        %used the same threshold that has been used before
        params.bin_thresh = num2str(tmp_params.(TARGET.preproc_var).bin_thresh);
        
        clear tmp_params;
        
        % Try the processing       
        try
           imreg_main_batch(params);
        catch ERR
            %there may be cases that the image cannot be processed for some
            %reason. Come back later for it
            disp([params.dir_name,' encountered an error.']);
            disp(ERR.message);
            fprintf(FID,[params.dir_name,' encountered an error.']);
            fprintf(FID,'\n');
            fprintf(FID,ERR.message);
            fprintf(FID,'\n');
            flag = false;
            continue;
        end
        clear images;
        close all;%close all potentially opened figures, come back later
    end
    
    %% Post-processing
    % only when there is no error in preprocessing
%     if flag
%         analyzed_dir = dir(fullfile(save_dir,subjects{s},'movement/','*analysis*'));
%         postproc_main(subjects{s},{analyzed_dir.name},fullfile(save_dir,subjects{s},'movement/'),1);
%         eval(['!cp ',save_dir, '/',subjects{s},'/movement/mprage_movement_postproc.mat ',...
%             results_dir]);
%         eval(['!mv ',results_dir,'/mprage_movement_postproc.mat ',...
%             results_dir, '/',subjects{s},'.mat']);
%     end
    close all;

end
A= toc;
fprintf(FID,['time taken: ',num2str(A),'s']);
fclose(FID);
%% Post-processing
%output variable structure:
%output{1} = subject ID
%output{2} = list of directories with the name analysis
%output{3} = base directory of movement processing
%output{4} = Use mprage analysis?