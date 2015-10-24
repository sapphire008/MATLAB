% Auth: Meric Ozturk
% Last edit: 2/29/12
% Contact: mrc.ozturk@gmail.com

%Editor: Edward DongBo Cui
%Last edit: 8/27/12
function postproc_main_batch(varargin)
% The postproc_main function runs postprocessing on movement covariates
% extracted using imreg_main. It takes in an optional argument, the path to
% the movement folder of the chosen subject. If called by imreg_main, this
% path is passed automatically. The function saves two outputs to the
% movement folder, a .csv file named <subject-id>_movement.csv and 
% the variables runs struct and workspace cell in movement_postproc.mat.
%
% Valid run folders are decided on by whether immediate subdirs of the
% movement path contain short_workspace.mat. This is done within the GUI.


diary post_proc_log.txt

% Add dependencies to path
addpath(genpath([pwd filesep 'postproc_code']));
addpath(genpath([pwd filesep 'imreg_code']));

% Call the gui depending on whether or not we have an input
if ~isempty(varargin)
    output = varargin;
else
    output = postproc_gui;
end

% Extract outputs from the GUI
subj_id = output{1}; % identifies subject
mprage_folders = output{2};%mprage folders
run_folders = output{3}; % valid run folders found
working_dir = output{4}; % the given movement directory
if length(output)==5
    run_mprage_index = output{5};
end
if exist(fullfile(working_dir,'mprage_corrected_figures'),'dir')
    Query = input('Previous analysis exists. Overwrite?');
    if Query
        eval(['!rm -rf ',fullfile(working_dir,'mprage_corrected_figures')]);
    end
end
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
    'RMS X',...
    'RMS Y', ...
    'RMS X Positive',...
    'RMS X Negative', ...
    'RMS Y Positive',...
    'RMS Y Negative',...'Size Rotation',%to be deleted
    'Magnitude RMS',...
    'Worse RMS btx X&y', ...
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
    'Magnitude RMS Speed',...
    'Worse RMS btx X&y'...
    }; %42 items

% Initialization
num_mprages = length(mprage_folders);% number of mprage folders, should correspond to how many groups of runs
num_runs = length(run_folders);%number of runs for each mprage
runs(num_runs)=struct;% the runs struct will store all of the calculated info
mprages(num_mprages) = struct;%the mprage struct will store all the mprage reference info

% for each mprage, parse information
for k = 1:num_mprages
    mprages(k).dir = mprage_folders{k};
    mprages(k).runs = {};
    %load relevant information from short_workspace
    clear translational total_time rotational params
    load(fullfile(working_dir,mprage_folders{k},'short_workspace.mat'),...
        'translational','total_time','params');
    %pass down some information
    mprages(k).name = regexprep(params.project_name,'_analysis','');
    mprages(k).name = regexprep(mprages(k).name,'-analysis','');
    mprages(k).displacement.x = translational.displacement(1,:);
    mprages(k).displacement.y = translational.displacement(2,:);
    mprages(k).velocity.x = translational.velocity(1,:);
    mprages(k).velocity.y = translational.velocity(2,:);
    mprages(k).params = params;
    mprages(k).time = total_time;
end
eval(['!mkdir -p ',(fullfile(working_dir,'mprage_corrected_figures'))]);
% for each run, parse information
ind = 0;

for r = 1:num_runs
    ind=ind+1;
    % load short_workspace for current run
    clear translational total_time rotational params
    load(fullfile(working_dir,run_folders{r},'short_workspace.mat'),...
        'translational','total_time','params');
    % pass down some information
    runs(ind).dir = run_folders{r};
    runs(ind).name = regexprep(params.project_name,'_analysis','');
    runs(ind).name = regexprep(runs(ind).name,'-analysis','');
    runs(ind).displacement.x = translational.displacement(1,:);
    runs(ind).displacement.y = translational.displacement(2,:);
    runs(ind).velocity.x = translational.velocity(1,:);
    runs(ind).velocity.y = translational.velocity(2,:);
    runs(ind).params = params;
    runs(ind).time = total_time;
    runs(ind).im_dir = params.im_dir;
    % If there are more than 1 mprages, ask the user to identify
    % correspondence
    if ~exist('run_mprage_index','var') || isempty(run_mprage_index)
        [runs(ind).mprage_name,mprage_ind,mprages] = identify_mprages(mprage_folders,mprages,runs(ind).name);
    else
        mprage_ind = run_mprage_index(r);
        runs(ind).mprage_name = mprage_folders{mprage_ind};
        % record it on mprage directory
        mprages(mprage_ind).runs{end+1} = runs(ind).name;
    end
    
    % calculate corrected displacement for run using mprage as reference
    [corrected_disp,runs(ind).Window] = mprage_corrected_disp(runs(ind),mprages(mprage_ind),...
        fullfile(working_dir,'mprage_corrected_figures'));
    % calculate new displacement using corrected displacement numbers
    old_disp = runs(ind).displacement;
    runs(ind).displacement.x(1:end) = old_disp.x(1:end) + corrected_disp.x;
    runs(ind).displacement.y(1:end) = old_disp.y(1:end) + corrected_disp.y;
    % plot corrected displacement and save
    f = figure('Name', ['MPRAGE Corrected Displacement: ' runs(ind).im_dir],...
        'NumberTitle', 'off');
    subplot(211);
    plot(runs(ind).time, runs(ind).displacement.x, 'b');
    title([runs(ind).im_dir ...
        ' - MPRAGE Corrected Displacement From Origin'], 'Interpreter', 'None');
    xlabel('Time (s)');
    ylabel('Displacement (mm)');
    legend('X Axis');
    subplot(212);
    plot(runs(ind).time, runs(ind).displacement.y, 'r');
    xlabel('Time (s)');
    ylabel('Displacement (mm)');
    legend('Y Axis');
    % save figure
    saveas(f, fullfile(working_dir,'mprage_corrected_figures',...
        [runs(ind).name,'_mprage_corrected.fig']));
end
% characterize each run
for i = 1:sum(num_runs(:))
    % Displacement
    runs(i).disp = postproc_char_signal(runs(i).time,runs(i).displacement);
    % Velocity
    runs(i).velo = postproc_char_signal(runs(i).time,runs(i).velocity);
    worksheet{i+1, 1} = subj_id;
    worksheet{i+1, 2} = runs(i).im_dir;
    worksheet(i+1, 3:10)  = struct2cell(runs(i).disp.RAW)';
    worksheet(i+1, 11:18) = struct2cell(runs(i).disp.RMS)';
    worksheet(i+1, 19:26) = struct2cell(runs(i).disp.JAG)';
    worksheet(i+1, 27:34) = struct2cell(runs(i).velo.RAW)';
    worksheet(i+1, 35:42) = struct2cell(runs(i).velo.RMS)';
end
%replace all the NaN entries in the cell array with 0
worksheet=postproc_replaceNaN(worksheet,{0});
% Save the worksheet as a csv file
% Save the runs struct

save(fullfile(working_dir,[subj_id,'_mprage_movement_postproc.mat']), 'worksheet', 'runs','mprages');
postproc_cell2csv(fullfile(working_dir,[subj_id '_mprage_movement.csv']), worksheet,',');


diary off;
end


function [mprage_name, mprage_ind,mprages]=identify_mprages(mprage_folders,mprages,current_run_name)
%[runs(rind).mprage_name,mprages] = identify_mprages(mprage_folders,mprages);
if length(mprage_folders)>1
    disp(current_run_name);
    disp(' ');
    %display all the mprages
    for n = 1:length(mprage_folders)
        disp(['   ',num2str(n),':',mprage_folders{n}]);
    end
    % ask the user to identify: Index
    mprage_ind = input('Which mprage is used to reference this run?');
else
    mprage_ind = 1;
end
%get the mprage
mprage_name = mprage_folders{mprage_ind};
% record it on mprage directory
mprages(mprage_ind).runs{end+1} = current_run_name;
end