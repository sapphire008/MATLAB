clear 
close all
clc
addpath('X:\Documents\Edward\scripts\NeuroShare\');
addpath('X:\Documents\Edward\scripts\generic\');
%% Parameter Specification
base_dir = 'X:\Data\Edward\RawData\2014 September 4\';
script_dir = 'X:\Documents\Edward\scripts\';
result_dir = 'C:\Users\Edward\Documents\MATLAB\';
preset_params = 'X:\Data\Edward\Analysis\2014 September 4\include.mat';
[~, fileName] = SearchFiles(base_dir,'Data_090414_block_Na_and_Synapse_slice1_stim_*.mcd');
thres = 0.400; %0.200; %0.800;        % event threshold in mV
ord = 100; % order of fir filter
f_band = [0.5, 40]; % filter band [Hz]
sigma = 0.5; %1; % spatial filter width
skip_factor = 5; %10*dt; %skip how many indicies when plotting data
duq = 0.1; %plot grid resolution
uq = 0.5:duq:12.5; %grids
plot_dur = [-0.1,1]; % plot duratio [s]
plot_scale = [1,1,0.5,0.5]; %position_x, position_y, width_scale, height_scale
gif_speed = 0.1; %delay time [s] between each frame.
%% static parameter calculations
load(preset_params);
[xq,yq] = meshgrid(uq);%mesh grid for data plot
nspkt = length(include_raws); % number of events
%% Designing spatial filter
spfilt = exp(-((xq-6.5).^2+(yq-6.5).^2)/(2*sigma^2));
spfilt = spfilt/sum(spfilt(:));
clear sigma;
%% Loop in time around events
f1 = figure('position',get(0,'ScreenSize').*plot_scale); % maximizing figure
cmap = flipud(colormap(jet));  % defining new colormap
figcol = get(gcf,'color');
for n = 20:nspkt
    
    fprintf(1,'n = %i of %i events, stim = %s\n',n,nspkt,stim_channel_list{n});
    
    %% load the data and process data
    MEA = loadMEA(fullfile(base_dir,include_raws{n}),'select',{'Digital'});
    Tinterv = find(MEA.Digital.Channel.Data,1,'last')+2;
    [MEA,X] = loadMEA(fullfile(base_dir,include_raws{n}),'stream_channel',Tinterv);
    [nT, nch] = size(X); % number of channels, number of samples (time steps)
    fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
    dt = 1/fs;          % time step
    time = (0:nT-1)/fs; % time vector
    % shortest distance between electrodes in mm
    pitch = min(diff(unique([MEA.Electrode.Channel.Info.LocationY])))*1000;
    xy = MEA.MapInfo.coord(2:-1:1,:);% Electrode coordinates
    
    % converting data
    % X = -X;
    
    % Defining image mask
    tri = delaunayTriangulation(xy(1,:)',xy(2,:)');
    temp = convexHull(tri);
    temp1 = [0 0; 0 13; 13 13; 13 0];
    temp2 = flipud(tri.Points(temp,:));
    Inpol = inpolygon(xq,yq,tri.Points(temp,1),tri.Points(temp,2));
    [xmask, ymask] = polybool('minus', temp1(:,1), temp1(:,2), temp2(:,1),temp2(:,2));
    [fmask,vmask] = poly2fv(xmask,ymask);
    clear temp temp1 temp2 tri;
    
    % gif file name
    [~,fname,~] = fileparts(fileName{1});
    fname = fullfile(result_dir,[fname,sprintf('_elec_%s.fig',stim_channel_list{n})]);
    
    % interpolate spatial map
    F = scatteredInterpolant(xy',X','natural','linear');
    Vq = F(xq,yq);
    
    % spatial filtering of LFP
    %Vq = conv2(Vq,spfilt,'same');
    Vq = filter2(spfilt, Vq); % faster
    
    % computing CSD
    L = -del2(Vq,duq*pitch);
    
    % Applying mask to LFP and CSD
    Vq = Vq.*Inpol;
    L = L.*Inpol;
    
    [Vqmax,ind] = max(abs(Vq(:)));
    temp = xq(:);
    xmax = temp(ind);
    temp = yq(:);
    ymax = temp(ind);
    
    fprintf('\n');
    save(fullfile(result_dir,[stim_channel_list{n},'.mat']),'Vq','L');
    
    % calculate color bars
    climV = [-1,1]*max(abs(Vq(:)));
    
    % plot time series
    
    figure(f1)
    % LFP
    imagesc(uq,uq',Vq,climV)
    title([stim_channel_list{n},' field potential right after stimulation(mV)'],'fontsize',14)
    colormap(cmap)
    hc = colorbar;
    set(hc,'fontsize',14)
    hold on
    plot(xy(1,:),xy(2,:),'k.');
    % put a white dot on the stimulating electrode
    coord = MEA.MapInfo.coord(:,find(ismember(MEA.MapInfo.channelnames,stim_channel_list{n})));
    plot(coord(2),coord(1),'w.');
    patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
    %plot(Vmax(1,t),Vmax(2,t),'wo','markerfacecolor','w'); % big white dot
    axis equal
    axis([0 1 0 1]*13)
    axis off
    hold off
    
    saveas(gcf,fname);
    
    close all;
%% 

end
