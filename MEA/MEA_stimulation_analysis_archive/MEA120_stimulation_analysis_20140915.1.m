clear 
close all
clc
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\MEA\');
%addpath('X:\Documents\Edward\scripts\MClust-4.2\');
addpath('Z:\Documents\Edward\scripts\generic\');
%% Parameter Specification
base_dir = 'Z:\Data\Edward\RawData\2014 September 12\';
script_dir = 'Z:\Documents\Edward\scripts\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 12\';
preset_params = 'Z:\Data\Edward\Analysis\2014 September 12\datainfo2.mat';
[~, fileName] = SearchFiles(base_dir,'Data_091214_block_NMDA_AMPA*.mcd');
thres = 0.400; %0.200; %0.800;        % event threshold in mV
ord = 100; % order of fir filter
f_band = [0.5, 40]; % filter band [Hz]
sigma = 0.5; %1; % spatial filter width
skip_factor = 50; %10*dt; %skip how many indicies when plotting data
duq = 0.1; %plot grid resolution
uq = 0.5:duq:12.5; %grids
plot_dur = [-0.5,18]; % plot duratio [s]
plot_scale = [1,1,0.5,0.5]; %position_x, position_y, width_scale, height_scale
gif_speed = 0.1; %delay time [s] between each frame.
%% static parameter calculations
load(preset_params);
spkt = event_time_stamp+1;
%reproc_list = {'A7','D2','F2','F3','F6','H10','H11','H12','M9'};
%reproc_ind = cellfun(@(x) find(ismember(stim_channel_list,x)), reproc_list);
[xq,yq] = meshgrid(uq);%mesh grid for data plot
nspkt = size(spkt,2); % number of events

%% Designing spatial filter
% spfilt = exp(-((xq-6.5).^2+(yq-6.5).^2)/(2*sigma^2));
% spfilt = spfilt/sum(spfilt(:));
% clear sigma;
%% Loop in time around events
% f1 = figure('position',get(0,'ScreenSize').*plot_scale); % maximizing figure
% cmap = flipud(colormap(jet));  % defining new colormap
for n = 49:nspkt
    
    fprintf(1,'n = %i of %i events, stim = %s\n',n,nspkt,stim_channel_list{n});
    
    Tinterv = spkt(n);%spkt(1,n):skip_factor:spkt(2,n);
    %Tinterv = round(spkt(n)/dt):round(ds/dt):round((spkt(n)+0.75)/dt);
    
    %% load the data and process data
    [MEA,X] = loadMEA(fullfile(base_dir,include_raws{n}),'stream_channel',spkt(:,n)');
    %[MEA,X] = loadMEA(fullfile(base_dir,include_raws{n}));

    [nT, nch] = size(X); % number of channels, number of samples (time steps)
    fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
    dt = 1/fs;          % time step
    % shortest distance between electrodes in mm
    pitch = min(diff(unique([MEA.Electrode.Channel.Info.LocationY])))*1000;
    xy = MEA.MapInfo.coord(2:-1:1,:);% Electrode coordinates
    % find out which electrode is being stimulated during the trial
    [~,stim_elec_ind] = max(range(X,1));
    stim_elect = stim_channel_list{n};
    % time interval (seconds) to plot against
    Tinterv = (Tinterv-1)*dt;
    
    [~,fname,~] = fileparts(include_raws{n});
    fig_name = fullfile(result_dir,[fname,'_',stim_elect,'.fig']);
    
    % plot
%     MEA_plot(X,Tinterv,'pitch',pitch,'custom_sup_title',...
%         ['Stimulation Channel: ',stim_elect],'fig_name',fig_name);

    [~,V,~,~,xy,uq] = MEA_plot(X,Tinterv,'pitch',pitch,...
        'custom_sup_title',['Stimulation Channel: ', stim_elect]);
    close all;
end
