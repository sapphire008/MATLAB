% Auth: Meric Ozturk
% Last edit: 6/17/11
% Contact: mrc.ozturk@gmail.com

% Editor: Edward DongBo Cui
% Last edit : 8/17/12
%
% Imreg_main and associated scripts are used to calculate the 2-D
% translational and angular movement of a subject inside of the MRI
% scanner. The function takes in the name of the session aviand puts the
% images through a variety of algorithms to output the translations:
%       0- Parameters are entered via GUI | imreg_gui.m, imreg_gui.fig
%       1- Images are thresholded | imreg_readims.m
%       2- Images are windowed | imreg_window.m
%       3- Image boundries are cleaned | imreg_clean.m
%       4- Noise within images are cleaned | imreg_clean.m
%       5- Image edges are found | imreg_edges.m
%       6- Image centers are found | imreg.center.m
%       7- Translation and rotation are computed | imreg.calculate.m

% All program parameters are stored in the params struct:
%   - project_name: will be used in title of project dir and graph
%   - save_dir: directory where the project dir / results will be saved
%   - dir_name: directory where the jpegs (raw data) are stored
%   - post_proc: if flagged, will call the post processing function
%   - sample_rate: what was the sampling rate of the jpegs?
%   - bin_thresh: binary conversion threshold; default: auto
%   - min_area: minimum px area of image features; default: 80
%   - edge_alg: the edge finding algorithm to find feature edges
%   - pixels_to_mm: Number of pixels in 1 mm (base truth)
%   - save_workspace: should we save the entire workspace
%   - home_dir: directory where the analysis was started from
%   - wait_time: when presenting images, how fast do we cycle?
%   - interactive: should we present images after every stage of analysis?
%   - proj_dir: location of theimreg_butterfilter.m project directory (created in imreg_main)
%   - im_names: cell with ordered image names
%   - image_num: Length of im_names

function [params,images] = imreg_main_batch(params)
% The imreg_main function is used to call all of the other imreg scripts.
% imreg_main creates the directory structure and starts the log, then 
% procedurally calls the other functions / handles error handling when the
% user decides to unexpectedly quit. Rest of the code is in ./code, which
% should explain our call to addpath.
[PATH,~,~] = fileparts(mfilename('fullpath'));
addpath(genpath(PATH));clear PATH;
% Get parameters from the gui if not specified
if nargin<1
    params = imreg_gui;
    % Some other params not set from the GUI
    % All functions return to the home dir, for housekeeping
    params.home_dir = pwd;
    % The "interactive" flag gives user the option to view images after each
    % step of the program
    params.interactive = 1;
    % If flagged, raw jpegs are copied into the project dir (for debugging)
    params.copy_jpegs = 0;
end

%distance between the centers of the squares [mm]
persistent centerDist_mm;
centerDist_mm =4.9; 


%%
% Create the project directory, start the runtime log
cd(params.save_dir);
proj_dir= [params.project_name '_' date];
% Make sure the directory doesn't already exist; option to overwrite
if exist(proj_dir, 'dir')
%     d = questdlg('This directory exists. Delete?',...
%         'Delete Directory?', 'Yes', 'No', 'No');
%     if strcmp(d, 'No'); error('Directory not overwritten.')
%     else
        rmdir(proj_dir, 's'); 
%     end
end
mkdir(proj_dir); cd (proj_dir);
params.proj_dir = pwd; diary log.txt;
% Copy jpegs into the project directory if desired
if params.copy_jpegs
    mkdir('jpegs'); cd('jpegs'); params.im_dir = pwd;
    copyfile([params.dir_name filesep '*'], params.im_dir);
else
    params.im_dir = params.dir_name;
end
%cd(params.home_dir);

% Read in file names in image dir
% NOTE: We assume that anything with a .jpg extension is yours
% They better be in ASCII order, or else
cd(params.im_dir);
imagedir = dir([params.im_dir filesep '*.jpg']);
params.im_names = {imagedir.name};
% Base image is used for thresholding, etc.
base_im = rgb2gray(imread(params.im_names{1}));
cd(params.home_dir);

% How many images are we talking about here?
params.image_num = length(params.im_names);

% For the sake of our log:
disp(' '); disp(['Date of Analysis : ' date]); disp(' ')
disp(['We are analyzing ' num2str(params.image_num) ' images this run.']);
disp(' '); disp('Parameters for this run: ');
disp(['Project Name : ' params.project_name]);
disp(['Save Directory : ' params.save_dir]);
disp(['Image Directory : ' params.dir_name]);
disp(['Sampling Rate (Hz) : ' num2str(params.sample_rate)]);
disp(['Binary Conversion Thresh : ' params.bin_thresh]);
disp(['Minimum Feature Area : ' num2str(params.min_area)]);
disp(['Edge Finding Algorithm : ' params.edge_alg]);
disp(['Base Truth (px) : ' num2str(params.pixels_to_mm)]);
disp( ' ');

%%
% Procedural bit starts here. If function called exits unsuccessfully, it
% does not return the images var as a struct.

% Find the binary threshold if not given
if strcmp(params.bin_thresh, 'auto');
    [params.bin_thresh, params.invert_image] = imreg_findthresh(base_im);
else
    params.bin_thresh = str2num(params.bin_thresh);
end
if params.bin_thresh == -1
    disp('Terminated while finding threshold.'); disp(' ');
    diary off; return;
end
disp(['Chosen binary threshold: ' num2str(params.bin_thresh)]);

% Read in the sampled images and grayscale
images = imreg_readims(params);
if ~isstruct(images)
    disp('Terminated while reading in images.'); disp(' ');
    diary off; return;
end

% auto crop if window already exists
if isfield(params,'Window') && ~isempty(params.Window)
    disp('Auto Cropping Images ...');
    tic;
    for n = 1:length(images)
        images(n).gray = images(n).gray(...
            params.Window(1):params.Window(2),params.Window(3):params.Window(4));
    end
    toc;
end
% Auto-Segment the markers
[images,params] = imreg_segment2(images,params);

% % Find the image edges using the specified alg.
% images = imreg_edges(images, params);
% if ~isstruct(images)
%     disp('Terminated while finding edges.'); disp(' ');
%     diary off; return; 
% end
% 
% % Calculate the image centers
% images = imreg_center(images, params);
% if ~isstruct(images)
%     disp('Terminated while finding centers.'); disp(' ');
%     diary off; return; 
% end

if strcmp(params.pixels_to_mm, 'auto');
    [params.pixels_to_mm,params.pxdist] = imreg_px2mm(images,params,centerDist_mm);
else
    params.pixels_to_mm = str2double(params.pixels_to_mm);
end
if params.pixels_to_mm == -1
    disp('Terminated while finding threshold.'); disp(' ');
    diary off; return;
end

% Calculate the translation from the found centers
[images, translational] = imreg_calculate(images, params);
if ~isstruct(images)
    disp('Terminated while calculating translation.'); disp(' ');
    diary off; return; 
end

% Before saving and plotting anything, filter the signal to get rid of some
% noise
translational.displacement(1,:)=...
    imreg_butterfilter(translational.displacement(1,:));
translational.displacement(2,:)=...
    imreg_butterfilter(translational.displacement(2,:));
translational.velocity(1,:)=...
    imreg_butterfilter(translational.velocity(1,:));
translational.velocity(2,:)=...
    imreg_butterfilter(translational.velocity(2,:));
%% Plot the translational motion
% If you want to make the graph prettier, do it here

% time vector we will plot against
total_time = (0:(1/params.sample_rate):...
    (1/params.sample_rate)*(params.image_num - 1));
% Time series displacement and velocity plot
f1 = figure('Name', ['Movement Analysis: ' ...
    params.project_name],'NumberTitle', 'off','Visible','off');
subplot(4,1,1);
plot(total_time, translational.displacement(1,:), 'b');
hold on;
plot(total_time, zeros(1,length(total_time)),'b-.');%draw a reference line
title([params.project_name ' - Displacement and Velocity']);
xlabel('Time (s)');
ylabel('Horizontal Displacement (mm)');
y_range=max(abs(get(gca,'YLim')));
set(gca,'YLim',[-y_range y_range]);%set Y axis symmstrical
subplot(4,1,2);
plot(total_time, translational.displacement(2,:), 'r');
hold on;
plot(total_time, zeros(1,length(total_time)),'r-.');%draw a reference line
xlabel('Time (s)');
ylabel('Vertical Displacement (mm)');
y_range=max(abs(get(gca,'YLim')));
set(gca,'YLim',[-y_range y_range]);%set Y axis symmstrical
subplot(4,1,3);
plot(total_time,translational.velocity(1,:),'b');
hold on;
plot(total_time, zeros(1,length(total_time)),'b-.');%draw a reference line
xlabel('Time (s)');
ylabel('Horizontal Velocity (mm/s)');
y_range=max(abs(get(gca,'YLim')));
set(gca,'YLim',[-y_range y_range]);%set Y axis symmstrical
subplot(4,1,4);
plot(total_time,translational.velocity(2,:),'r');
hold on;
plot(total_time, zeros(1,length(total_time)),'r-.');%draw a reference line
xlabel('Time (s)');
ylabel('Vertical Velocity (mm/s)');
y_range=max(abs(get(gca,'YLim')));
set(gca,'YLim',[-y_range y_range]);%set Y axis symmetrical
hold off;
% Movement 2D Map Plot
f2 = figure('Name', ['Movement Map: ' ...
    params.project_name],'NumberTitle', 'off','Visible','off');
% plot a 2D map of movement of the center of the figure
plot(translational.displacement(1,:),translational.displacement(2,:), '.');
hold on;
plot(translational.displacement(1,1),translational.displacement(2,1),...
    'go','MarkerSize', 15);%circle the starting point
plot(translational.displacement(1,end),translational.displacement(2,end),...
    'ro','MarkerSize', 15);%circle the end point
legend('Map', 'Start','Stop');%label the plot
set(gca, 'PlotBoxAspectRatio', [1 1 1]);%set to a square aspect ratio
% Save the figure and the workspace
cd(params.proj_dir);
% We could save as jpeg now, but better to let user edit, then save
saveas(f1, 'movement_graph.fig');%save movement figures
saveas(f2, 'movement_map.fig');%save movement map
% Save the csv file and the relevant bits from the workspace
csvwrite('movement_values.csv', [total_time' ...
    translational.displacement' ...
    translational.velocity']);
if params.save_workspace
    save workspace
else
    save('short_workspace.mat', 'params', 'translational', 'total_time','images');
end
% Some final comments for the log, then close
disp(' '); 
disp('The movement values have been saved in "movement_values.csv".');
disp(['Columns in csv: Time, Horizontal Displacement, ' ...
    'Vertical Displacement, Horizontal Velocity, Vertical Velocity']);
diary off;

% Finish off where we started
cd(params.home_dir);
% Make sure to free the large amount of memory we're using
clear global;
clear functions;
clearvars -except params images;

% If this is the last run and we want post-processing
if params.post_proc
    postproc_main(params.save_dir);
end

end


