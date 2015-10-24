clear 
close all
clc
addpath('X:\Documents\Edward\scripts\NeuroShare\');
addpath('X:\Documents\Edward\scripts\generic\');
%% Parameter Specification
base_dir = 'X:\Data\Edward\RawData\2014 September 4\';
script_dir = 'X:\Documents\Edward\scripts\';
result_dir = 'X:\Data\Edward\Analysis\2014 September 4\';
preset_params = 'X:\Data\Edward\Analysis\2014 September 4\include.mat';
[~, fileName] = SearchFiles(base_dir,'Data_090414_block_Na_and_Synapse_slice1_stim_*.mcd');
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
reproc_list = {'A7','D2','F2','F3','F6','H10','H11','H12','M9'};
reproc_ind = cellfun(@(x) find(ismember(stim_channel_list,x)), reproc_list);
[xq,yq] = meshgrid(uq);%mesh grid for data plot
nspkt = size(spkt,2); % number of events

%% Designing spatial filter
spfilt = exp(-((xq-6.5).^2+(yq-6.5).^2)/(2*sigma^2));
spfilt = spfilt/sum(spfilt(:));
clear sigma;
%% Loop in time around events
f1 = figure('position',get(0,'ScreenSize').*plot_scale); % maximizing figure
cmap = flipud(colormap(jet));  % defining new colormap
for n = [96]
    
    fprintf(1,'n = %i of %i events, stim = %s\n',n,nspkt,stim_channel_list{n});
    
    Tinterv = 1:skip_factor:(spkt(2,n)-spkt(1,n)+1);%spkt(1,n):skip_factor:spkt(2,n);
    %Tinterv = round(spkt(n)/dt):round(ds/dt):round((spkt(n)+0.75)/dt);
    I = zeros([size(xq) length(Tinterv)]);%current
    V = zeros([size(xq) length(Tinterv)]);%voltage
    Vmax = zeros(3,length(Tinterv));
   
    
    %% load the data and process data
    [MEA,X] = loadMEA(fullfile(base_dir,include_raws{n}),'stream_channel',spkt(:,n)');
    [nT, nch] = size(X); % number of channels, number of samples (time steps)
    fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
    dt = 1/fs;          % time step
    time = (0:nT-1)/fs; % time vector
    % shortest distance between electrodes in mm
    pitch = min(diff(unique([MEA.Electrode.Channel.Info.LocationY])))*1000;
    xy = MEA.MapInfo.coord(2:-1:1,:);% Electrode coordinates
    % find out which electrode is being stimulated during the trial
    [~,stim_elec_ind] = max(range(X,1));
    stim_elect = MEA.MapInfo.channelnames{stim_elec_ind};
    
    
    % converting data
    % X = -X;
    % Filtering data in time domain
    b = fir1(ord,f_band/(fs/2),'bandpass');
    X = filtfilt(b,1,X);
    
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
    fname = fullfile(result_dir,[fname,sprintf('_elec_%s.gif',stim_channel_list{n})]);
    
    for t = 1:length(Tinterv)
        %display progress
        fprintf([repmat('\b',1,(numel(num2str(t-1))+numel(num2str(...
            length(Tinterv)))+1)*(t>1)),'%d/%d'],t, length(Tinterv));
        
        F = scatteredInterpolant(xy',X(Tinterv(t),:)','natural','linear');
        Vq = F(xq,yq);
        
        % spatial filtering of LFP
        %Vq = conv2(Vq,spfilt,'same');
        Vq = filter2(spfilt, Vq); % faster

        % computing CSD
        L = -del2(Vq,duq*pitch);
        
        % Applying mask to LFP and CSD
        Vq = Vq.*Inpol;
        L = L.*Inpol;
        
        V(:,:,t) = Vq;
        I(:,:,t) = L;
        
        [Vqmax,ind] = max(abs(Vq(:)));
        temp = xq(:);
        xmax = temp(ind);
        temp = yq(:);
        ymax = temp(ind);
        
        Vmax(:,t) = [xmax; ymax; Vqmax];
    end
    
    fprintf('\n');
    %% calculate color bars
    clear Vq L temp
    
    temp = X(Tinterv,:);
    climX = [min(temp(:)) max(temp(:))];
    climX = max(abs(climX))*[-1 1];
    clear temp
    
    INDTIME = linspace(plot_dur(1),plot_dur(2),size(V,3));
    [~,IND0] = min(abs(INDTIME));%index when t=0
    [~,IND1] = min(abs(INDTIME-0.7));%index when t=0.7
    
    climV = V(:,:,IND0+1:IND1+1);
    climV = [min(climV(:)), max(climV(:))];
    climV = max(abs(climV))*[-1,1];
    
    climI = I(:,:,IND0+1:IND1+1);
    climI = [min(climI(:)), max(climI(:))];
    climI = max(abs(climI))*[-1,1];
    
%% plot time series

    figure(f1)
    
    figcol = get(gcf,'color');
    for t = 1:length(Tinterv)
        % time series trace
        subplot(2,2,[1 3])
        plot(Tinterv*dt+plot_dur(1),X(Tinterv,:),'-')
        hold on
        plot([Tinterv(1); Tinterv(end)]*dt+plot_dur(1),[0; 0],'k-','linewidth',1);%horizontal line
        plot([0;0],climX','k-','linewidth',2);%time indicator bar
        plot([Tinterv(t); Tinterv(t)]*dt+plot_dur(1),climX','r--','linewidth',2);%time indicator bar
        grid on
        hold off
        axis tight
        xlabel(sprintf('t = %3.3f s',(Tinterv(t)-1)*dt+plot_dur(1)));
        ylabel('field potential (mV)','fontsize',14)
        
        % LFP
        subplot(2,2,2)
        imagesc(uq,uq',squeeze(V(:,:,t)),climV)
        colormap(cmap)
        hc = colorbar;
        set(hc,'fontsize',14)
        title('field potential (mV)','fontsize',16,'position',[10 0])
        hold on
        plot(xy(1,:),xy(2,:),'k.')
        patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
        %plot(Vmax(1,t),Vmax(2,t),'wo','markerfacecolor','w'); % big white dot
        axis equal
        axis([0 1 0 1]*13)
        axis off
        hold off
        
        % CSD
        subplot(2,2,4)
        h = imagesc(uq,uq',squeeze(I(:,:,t)),climI);
        colormap(cmap)
        hc = colorbar;
        set(hc,'fontsize',14)
        title('current density / \sigma (mA/mm^2)','fontsize',16,'position',[10 0]);
        hold on
        plot(xy(1,:),xy(2,:),'k.')
        patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
        axis equal
        axis([0 1 0 1]*13)
        axis off
        hold off
        
        suptitle(sprintf('Channel %s',stim_channel_list{n}));
        
        % write to .gif
        frame = frame2im(getframe(gcf));
        [imind, cm] = rgb2ind(frame,256);
        if t == 1
            imwrite(imind, cm, fname,'gif','LoopCount',inf,'DelayTime',gif_speed);
        else
            imwrite(imind, cm, fname,'gif','WriteMode','append','DelayTime',gif_speed);
        end
        pause(0.05);
    end
    
    
%% 

end
