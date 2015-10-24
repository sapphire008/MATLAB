function imreg_postproc(varargin)
% The imreg_postproc function runs postprocessing on movement covariates
% extracted using imreg_preproc. It takes in an optional argument, the path 
% to the movement folder of the chosen subject. If called by imreg_main, 
% this path is passed automatically. The function saves two outputs to the
% movement folder, a .csv file named <subject-id>_movement.csv and 
% the variables runs struct and workspace cell in movement_postproc.mat.
%
% Valid run folders are decided on by whether immediate subdirs of the
% movement path contain short_workspace.mat. This is done within the GUI.
%
% Auth: Meric Ozturk
% Last edit: 2/29/12
% Contact: mrc.ozturk@gmail.com

% Modified by: Edward DongBo Cui
% Last edit: 06/30/2014

% Add dependencies to path
addpath(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'imreg_code')));
%addpath(genpath([pwd filesep 'imreg_code']));

% Call the gui depending on whether or not we have an input
if ~isempty(varargin)
    output = varargin;
else
    output = postproc_gui;
end

% Extract outputs from the GUI
subj_id = output{1}; % identifies subject
run_folders = output{2}; % valid run folders found
movement_dir = output{3}; % the given movement directory
rereference_flag = output{4}; % 1 if we are doing an mprage analysis

% start post-processing diary
diary(fullfile(movement_dir,'post_proc_log.txt'));

% Initiate variables before main for block
num_runs = length(run_folders); % number of valid run folders
runs(num_runs) = struct; % the runs struct will store all of the calculated info
% For each run, load the short workspace, calculate values for the
% worksheet and populate the worksheet
clc;
for n  = 1:num_runs
    % Populate runs struct with run namesruns and directories
    % The run name is based on the first substring of the run directory
    runs(n).dir = run_folders{n};
    runs(n).name = strtok(runs(n).dir,'_');
    
    % Load relevant variables from the short workspace for this run and
    % assign them into the struct
    load(fullfile(movement_dir,runs(n).dir,'short_workspace.mat'),...
        'translational','total_time','params','images');
    runs(n).displacement.x = translational.displacement(1,:);
    runs(n).displacement.y = translational.displacement(2,:);
    runs(n).velocity.x = translational.velocity(1,:);
    runs(n).velocity.y = translational.velocity(2,:);
    runs(n).params = params;
    runs(n).time = total_time;
    runs(n).base_image_center = images(1).center;
    sub = regexp(runs(n).params.im_dir,filesep,'split');
    runs(n).im_dir = sub{end};
    % if processing using a reference scan, examine which group each run
    % belongs to
    if rereference_flag && isempty(runs(n).params.ref_voxel)
        disp(runs(n).dir);
        runs(n).params.ref_voxel = input('Which group/voxel does this run belong to? ','s');
        runs(n).params.isref = input('Is this run used as a reference scan? [0|1]');
    end
    clear translational total_time rotational params images sub;
end

% calcualte grouping and reference differences
if rereference_flag
    runs = postproc_correct_reference_disp(runs);
    % plot new figures
    mkdir(fullfile(movement_dir,'reference_corrected_figures'));
    for m = 1:length(runs)
        figure('Name',runs(m).name,'NumberTitle','off');
        subplot(2,1,1);
        plot(runs(m).time,runs(m).displacement.x);
        hold on;
        plot(runs(m).time,runs(m).displacement.y,'r.-');
        hold off;
        ylabel('Displacement (mm)');
        subplot(2,1,2);
        plot(runs(m).time,runs(m).velocity.x);
        hold on;
        plot(runs(m).time,runs(m).velocity.y,'r.-');
        hold off;
        ylabel('Speed (mm/s)');
        xlabel('Time (s)');
        suptitle(regexprep(runs(m).dir,'_','\\_'));
        legend('X','Y');
        saveas(gcf,fullfile(movement_dir,'reference_corrected_figures',...
            [runs(m).im_dir,'_',datestr(now,'mm-dd-yyyy_HH-MM-SS'),'.png']));
        close(gcf);
    end
end

% characterize each run
% Column headings for the csv worksheet
worksheet = {'Subject', 'Run', ...
    'Displacement X',...
    'Displacement Y',...
    'Displacement X Positive',...
    'Displacement X Negative',...
    'Displacement Y Positive',...
    'Displacement Y Negatvie',...
    'Average Displacement Magnitude',...
    'Worse Displacement btx X&Y'...
    'RMS X Disp',...
    'RMS Y Disp', ...
    'RMS X Disp Positive',...
    'RMS X Disp Negative', ...
    'RMS Y Disp Positive',...
    'RMS Y Disp Negative',...'Size Rotation',%to be deleted
    'RMS Disp Magnitude',...
    'Worse RMS Disp btx X&Y', ...
    'Jaggedness X',...
    'Jaggedness Y', ...
    'Jaggedness X Positive',...
    'Jaggedness X Negative',...
    'Jaggedness Y Positive',...
    'Jaggedness Y Negative',...%'Jaggedness Rotation', ...%to be deleted'
    'Magnitude Jaggedness',...
    'Worse Jaggedness btx X&Y',...
    'Velocity X',...
    'Velocity Y',...
    'Velocity X Positive',...
    'Velocity X Negative',...
    'Velocity Y Positive',...
    'Velocity Y Negative',...
    'Average Velocity Magnitude',...
    'Worse Velocity btx X&Y',...
    'RMS X Speed',...
    'RMS Y Speed', ...
    'RMS X Positive Speed',...
    'RMS X Negative Speed', ...
    'RMS Y Positive Speed',...
    'RMS Y Negative Speed',...
    'RMS Speed Magnitude',...
    'Worse RMS Speed btx X&Y'...
    }; %42 items
for n = 1:num_runs  
    % Poplulate the workspace with values from this run
    % Displacement
    runs(n).disp = postproc_char_signal(runs(n).time,runs(n).displacement);
    % Velocity
    runs(n).velo = postproc_char_signal(runs(n).time,runs(n).velocity);
    worksheet{n+1, 1} = subj_id;
    worksheet{n+1, 2} = runs(n).im_dir;%use source image as run name, in case wrong images specified
    worksheet(n+1, 3:10)  = struct2cell(runs(n).disp.RAW)';
    worksheet(n+1, 11:18) = struct2cell(runs(n).disp.RMS)';
    worksheet(n+1, 19:26) = struct2cell(runs(n).disp.JAG)';
    worksheet(n+1, 27:34) = struct2cell(runs(n).velo.RAW)';
    worksheet(n+1, 35:42) = struct2cell(runs(n).velo.RMS)';
end
%replace all the NaN entries in the cell array with 0
worksheet=postproc_replaceNaN(worksheet,{0});
% Save the worksheet as a csv file
% Save the runs struct
if rereference_flag
    save(fullfile(movement_dir,[subj_id,'_rereferenced_movement_postproc.mat']), 'worksheet', 'runs');
    postproc_cell2csv(fullfile(movement_dir,[subj_id '_rereferenced_movement.csv']), worksheet);
else
    save(fullfile(movement_dir,[subj_id,'_movement_postproc.mat']), 'worksheet', 'runs');
    postproc_cell2csv(fullfile(movement_dir,[subj_id '_movement.csv']), worksheet);
end
rmpath(fileparts(mfilename('fullpath')));
rmpath(genpath(fullfile(fileparts(mfilename('fullpath')),'imreg_code')));
diary off;

end