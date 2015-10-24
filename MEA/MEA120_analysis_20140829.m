clear 
close all
clc
addpath('Z:\GalanLab\NeuroShare');
%% Parameter Specification
fileName = 'Z:\Data\Edward\RawData\2014 August 27\Data_082714_4uM gabazine_spontaneous_slice1_0000.mcd';
thres = 0.400; %0.200; %0.800;        % event threshold in mV
ord = 100; % order of fir filter
f_band = [0.5 40]; % filter band [Hz]
sigma = 0.5; %1; % spatial filter width
skip_factor = 20; %10*dt; %skip how many indicies when plotting data
duq = 0.1; %plot grid resolution
uq = 0.5:duq:12.5; %grids

%% Read Data and make other parameters based on data
[MEA,X] = loadMEA(fileName);
% Other parameters based on data file
[nT, nch] = size(X); % number of channels, number of samples (time steps)
fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
dt = 1/fs;          % time step
time = (0:nT-1)/fs; % time vector
% shortest distance between electrodes in mm
pitch = min(diff(unique([MEA.Electrode.Channel.Info.LocationY])))*1000;
xy = MEA.MapInfo.coord(2:-1:1,:);% Electrode coordinates
[xq,yq] = meshgrid(uq);%mesh grid for data plot
%% converting data
% X = -X;
%% Filtering data in time domain
b = fir1(ord,f_band/(fs/2),'bandpass');
X = filtfilt(b,1,X);
clear b ord f_band;
%% Designing spatial filter
spfilt = exp(-((xq-6.5).^2+(yq-6.5).^2)/(2*sigma^2));
spfilt = spfilt/sum(spfilt(:));
clear sigma;
%% Event detector
Y = X(:,1);
[~,POS_LOCS] = findpeaks(Y,'MinPeakHeight',1/3*max(Y),'MinPeakDistance',fs*15);
[~,NEG_LOCS] =  findpeaks(-Y,'MinPeakHeight',-1/3*min(Y),'MinPeakDistance',fs*15);

spkt = [NEG_LOCS-3*fs,POS_LOCS+10*fs]'; %spike timing
nspkt = size(spkt,2); % number of events

clear POS_LOCS NEG_LOCS thres Y;
%% Defining image mask
tri = delaunayTriangulation(xy(1,:)',xy(2,:)');
temp = convexHull(tri);
temp1 = [0 0; 0 13; 13 13; 13 0];
temp2 = flipud(tri.Points(temp,:));
Inpol = inpolygon(xq,yq,tri.Points(temp,1),tri.Points(temp,2));
[xmask, ymask] = polybool('minus', temp1(:,1), temp1(:,2), temp2(:,1),temp2(:,2));
[fmask,vmask] = poly2fv(xmask,ymask);
clear temp temp1 temp2 tri;
%% Loop in time around events
f1 = figure('position',get(0,'ScreenSize').*[1,1,0.5,0.5]); % maximizing figure
cmap = flipud(colormap(jet));  % defining new colormap

for n = 1:nspkt
    
    fprintf(1,'n = %i of %i\n',n,nspkt);
    
    Tinterv = spkt(1,n):skip_factor:spkt(2,n);
    %Tinterv = round(spkt(n)/dt):round(ds/dt):round((spkt(n)+0.75)/dt);
    I = zeros([size(xq) length(Tinterv)]);%current
    V = zeros([size(xq) length(Tinterv)]);%voltage
    Vmax = zeros(3,length(Tinterv));
    
    % gif file name
    [fpath,fname,~] = fileparts(fileName);
    fname = fullfile(fpath,[fname,sprintf('_event%03.0f.gif',n)]);
    clear fpath;
    
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
    
    clear Vq L temp
    
    temp = X(Tinterv,:);
    climX = [min(temp(:)) max(temp(:))];
    climX = max(abs(climX))*[-1 1];
    clear temp
    
    climV = [min(V(:)) max(V(:))];
    climV = max(abs(climV))*[-1 1];
    
    climI = [min(I(:)) max(I(:))];
    climI = max(abs(climI))*[-1 1];
    
%

    figure(f1)
    
    figcol = get(gcf,'color');
    for t = 1:length(Tinterv)
        % time series trace
        subplot(2,2,[1 3])
        plot(Tinterv*dt,X(Tinterv,:),'-')
        hold on
        plot([Tinterv(t); Tinterv(t)]*dt,climX','r--','linewidth',2)
        plot([Tinterv(1); Tinterv(end)]*dt,[0; 0],'k-','linewidth',1)
        grid on
        hold off
        axis tight
        set(gca,'fontsize',16)
        xlabel('time (s)')
        ylabel('field potential (mV)','fontsize',16)
        title(sprintf('t = %3.3f s',(Tinterv(t)-1)*dt),'fontsize',14)
        
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
        %plot(Vmax(1,t),Vmax(2,t),'wo','markerfacecolor','w')
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
        
        suptitle(sprintf('Event %d',n));
        
        % write to .gif
        frame = frame2im(getframe(gcf));
        [imind, cm] = rgb2ind(frame,256);
        if t == 1
            imwrite(imind, cm, fname,'gif','LoopCount',inf,'DelayTime',0.02);
        else
            imwrite(imind, cm, fname,'gif','WriteMode','append','DelayTime',0.02);
        end
        pause(0.05);
    end
    
    
%% 

end
