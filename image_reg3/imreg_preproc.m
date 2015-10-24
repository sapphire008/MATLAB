function imreg_preproc(params)
% PLEASE READ CAREFULLY BEFORE EDITING!
%
% Imreg_main and associated scripts are used to calculate the 2-D
% translational and angular movement of a subject inside of the MRI
% scanner. The function takes in the name of the session aviand puts the
% images through a variety of algorithms to output the translations:
%       0- Parameters are entered via GUI | imreg_gui.m, imreg_gui.fig
%       1- Images are thresholded | imreg_readims.m
%       2- Images are segmented and templated matched to extract the
%          fiducial markers. If segmentation unsuccessful (determined by
%          user), images are windows | imreg_window.m and segmentation is
%          redone
%       3- Image edges are found | imreg_edges.m
%       4- Image centers are found | imreg_center.m
%       5- Translation and rotation are computed | imreg_calculate.m
%
% All program parameters are stored in the params struct:
%   - project_name: will be used in title of project dir and graph
%   - save_dir: directory where the project dir / results will be saved
%   - dir_name: directory where the jpegs (raw data) are stored
%   - post_proc: if flagged, will call the post processing function
%   - sample_rate: what was the sampling rate of the jpegs?
%   - bin_thresh: binary conversion threshold; default: auto
%   - min_area: minimum px area of image features; default: 80
%   - edge_alg: the edge finding algorithm to find feature edges
%   - centerDist_mm: intercentroid distance of the markers in mm
%   - medfilt: median filter to reduce noise in frames, default [3,3]
%   - image_ext: extension of the raw images
%   - ref_voxel: bookkeeping. Which group / voxel does the current run belong to
%   - isref: bookkeeping. Is the current run used as reference scan later?
%   - save_workspace: should we save the entire workspace
%   - home_dir: directory where the analysis was started from
%   - copy_images: [0|1] whether or not copy images to analysis directory
%   - interactive: should we present images after every stage of analysis?
%   - proj_dir: location of the project directory (created in imreg_main)
%   - im_dir: raw image directory
%   - im_names: cell with ordered image names
%   - image_num: number of images, Length of im_names
%   - im_dim: source raw image dimension [num_row, num_col]
%   - Window: image cropping window
%   - pixels_to_mm: pixel to mm conversion factor
%
% Image relevant information is stored in images structure array:
%   - name: name of the source image
%   - time: temporal point of current image
%   - centered: image after segmentation and cropping, for QA
%   - center: center of the image, with respect to the centered image.
%            [row, col]
%   - LRcenter: left and right center of the fiducial markers, with respect
%           to centered image. [row_left,col_left;row_right,col_right];
%   
%
% The imreg_preproc function is used to call all of the other imreg scripts.
% imreg_preproc creates the directory structure and starts the log, then 
% procedurally calls the other functions / handles error handling when the
% user decides to unexpectedly quit. Rest of the code is in ./imreg_code, 
% which should explain our call to addpath.
% 
%
%
% Auth: Meric Ozturk
% Last edit: 6/17/11
% Contact: mrc.ozturk@gmail.com
%
% Modified by: Edward DongBo Cui
% Last edit : 6/30/14

% get installation path
addpath(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'imreg_code')));
% Get parameters from the gui
if nargin<1
    params = imreg_gui;
    % Some other params not set from the GUI
    % All functions return to the home dir, for housekeeping
    params.home_dir = pwd;
    % If flagged, raw images are copied into the project dir (for debugging)
    params.copy_images = 0;
    % The "interactive" flag gives user the option to view images after each
    % step of the program
    params.interactive = 1;
    %distance between the centers of the squares [mm]
    %params.centerDist_mm =4.9;
    % specify image extension
    %params.image_ext = '.jpg';
end
%% Initialization
% Create the project directory, start the runtime log
params.proj_dir = fullfile(params.save_dir,[params.project_name '_' date]);
% Make sure the directory doesn't already exist; option to overwrite
if exist(params.proj_dir, 'dir')
    d = questdlg('This directory exists. Delete?',...
        'Delete Directory?', 'Yes', 'No', 'No');
    if strcmp(d, 'No')
        error('Directory not overwritten.')
    else
        rmdir(params.proj_dir, 's')
    end
end
mkdir(params.proj_dir);
% Copy raw images into the project directory if desired
if params.copy_images
    params.im_dir = fullfile(params.proj_dir,'copied_images');
    mkdir(params.im_dir); 
    copyfile(fullfile(params.dir_name,['*',image_ext]), params.im_dir);
else
    params.im_dir = params.dir_name;
end
diary(fullfile(params.proj_dir,'log.txt'));

% Read in file names in image dir
% NOTE: We assume that anything with a .jpg extension is yours
% They better be in ASCII order, or else
imagedir = dir(fullfile(params.im_dir,['*',params.image_ext]));
params.im_names = {imagedir.name}; clear imagedir;
% Base image is used for thresholding, etc.
base_im = rgb2gray(imread(fullfile(params.im_dir,params.im_names{1})));

% How many images are we talking about here?
params.image_num = length(params.im_names);

% For the sake of our log:
disp(' '); disp(['Date of Analysis : ' date]); disp(' ')
disp(['We are analyzing ' num2str(params.image_num) ' images this run.']);
disp(' '); disp('Parameters for this run: ');
disp(['Project Name : ' params.project_name]);
disp(['Image Directory : ' params.dir_name]);
disp(['Project Directory : ' params.proj_dir]);
disp(['Sampling Rate (Hz) : ' num2str(params.sample_rate)]);
disp(['Binary Conversion Thresh : ' params.bin_thresh]);
disp(['Minimum Feature Area : ' num2str(params.min_area)]);
disp(['Edge Finding Algorithm : ' params.edge_alg]);
disp(['Intercentroid Distance (mm) : ' num2str(params.centerDist_mm)]);
disp( ' ');

%% Image processing
% Procedural bit starts here. If function called exits unsuccessfully, it
% does not return the images var as a struct.

% Find the binary threshold if not given
if ~isfield(params,'bin_thresh') || (ischar(params.bin_thresh) && ...
        isnan(str2double(params.bin_thresh)))
    [params.bin_thresh, params.invert_image] = imreg_findthresh(base_im);
elseif ischar(params.bin_thresh)
    params.bin_thresh = str2double(params.bin_thresh);
end
%if bin_thresh not specified correctly
if params.bin_thresh == -1
    disp('Terminated while finding threshold.'); disp(' ');
    diary off; return;
end
disp(['Chosen binary threshold: ' num2str(params.bin_thresh)]);

% Read in the sampled images and grayscale
[images,params] = imreg_readims(params);
if ~isstruct(images)
    disp('Terminated while reading in images.'); disp(' ');
    diary off; return;
end

% Use Hausdorff distance to segment images to extract the fiducial markers
Query = '';
while true
    switch lower(Query)
        case 'yes'
            break;% continue
        case 'no'
            % let the user crop the image manually, then reprocess
            [images,params] = imreg_window(images,params);
            if ~isstruct(images)
                disp('Terminated while cropping.'); disp(' ');
                diary off; return; 
            end
            % redo segmentation
            [images,params,Query] = imreg_segment(images,params);
        case 'cancel'
            disp('Terminated while segmenting.'); disp(' ');
            diary off; return;
        otherwise
            [images,params,Query] = imreg_segment(images,params);
    end
end

% Find the image edges using the specified alg.
images = imreg_edges(images, params);
if ~isstruct(images)
    disp('Terminated while finding edges.'); disp(' ');
    diary off; return;
end

% Calculate the image centers
images = imreg_center(images, params);
if ~isstruct(images)
    disp('Terminated while finding centers.'); disp(' ');
    diary off; return; 
end
%% generate movement time series
% get pixel to mm
params.pixels_to_mm = imreg_px2mm(images,params);

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
    params.project_name],'NumberTitle', 'off');
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
    params.project_name],'NumberTitle', 'off');
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
% We could save as jpeg now, but better to let user edit, then save
saveas(f1, fullfile(params.proj_dir,'movement_graph.fig'));%save movement figures
saveas(f2, fullfile(params.proj_dir,'movement_map.fig'));%save movement map
% Save the csv file and the relevant bits from the workspace
csvwrite(fullfile(params.proj_dir,'movement_values.csv'), [total_time' ...
    translational.displacement' ...
    translational.velocity']);
if params.save_workspace
    save(fullfile(params.proj_dir,'workspace.mat'));
else
    save(fullfile(params.proj_dir,'short_workspace.mat'), 'params', ...
        'translational','images','total_time');
end
% Some final comments for the log, then close
disp(' '); 
disp('The movement values have been saved in "movement_values.csv".');
disp(['Columns in csv: Time, Horizontal Displacement, ' ...
    'Vertical Displacement, Horizontal Velocity, Vertical Velocity']);
diary off;

% Make sure to free the large amount of memory we're using

% If this is the last run and we want post-processing
if params.post_proc
    imreg_postproc(params.save_dir);
end
clear all;
end


