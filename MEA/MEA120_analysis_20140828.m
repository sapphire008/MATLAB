clear 
close all
clc
addpath('G:\GalanLab\NeuroShare');
%% Loading file
fileName = 'G:\GalanLab\RawData\2014 August 27\Data_082714_4uM gabazine_spontaneous_slice1_0000.mcd';
[MEA,X] = loadMEA(fileName);
%% Parameter definition
[nT, nch] = size(X); % number of channels, number of samples (time steps)
fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
fn = fs/2; % Nyquist frequency
dt = 1/fs;          % time step
time = (0:nT-1)*dt; % time vector
thres = 0.600; %200; %800;        % event threshold in mV
pitch = min(diff(unique([MEA.Electrode.Channel.Info.LocationY])))*1000;% shortest distance between electrodes in mm    

%% Electrode coordinates
xy = MEA.MapInfo.coord(2:-1:1,:);


%% converting data
% 
% X = -X;
% convert everyting to mV
switch lower(MEA.Electrode.Channel.Info(1).Units)
    case 'v'
        X = X/1000;
    case 'uv'
        X = X*1000;
end
thres = -thres;

%% Filtering data in time domain

ord = 100;
b = fir1(ord,[0.5 40]/fn,'bandpass');
X = filtfilt(b,1,X);

%% Event detector

spkt = min(X,[],2) < thres;     % detects a negative LFP spike
spkt = diff(spkt) > 0;
spkt = time(spkt) - 0.05; %0.100
spkt = spkt(spkt > 0);
nspkt = length(spkt);           % number of events

%% Parameters for plotting data
  
ds = 5*dt; %10*dt;

duq = 0.1;
uq = 0.5:duq:12.5;
[xq,yq] = meshgrid(uq);

%% Defining image mask

tri = delaunayTriangulation(xy(1,:)',xy(2,:)');
temp = convexHull(tri);
temp1 = [0 0; 0 13; 13 13; 13 0];
temp2 = flipud(tri.Points(temp,:));
Inpol = inpolygon(xq,yq,tri.Points(temp,1),tri.Points(temp,2));
[xmask, ymask] = polybool('minus', temp1(:,1), temp1(:,2), temp2(:,1),temp2(:,2));
[fmask,vmask] = poly2fv(xmask,ymask);
clear temp temp1 temp2

%% Designing spatial filter

sigma = 0.5; %1; %0.5;
spfilt = exp(-((xq-6.5).^2+(yq-6.5).^2)/(2*sigma^2));
spfilt = spfilt/sum(spfilt(:));

%% Loop in time around events

scrsz = get(0,'ScreenSize');
f1 = figure('position',scrsz);

for n = 1:nspkt
    
    fprintf(1,'n = %i of %i\n',n,nspkt)
    
    Tinterv = round(spkt(n)/dt):round(ds/dt):round((spkt(n)+0.30)/dt);
    %Tinterv = round(spkt(n)/dt):round(ds/dt):round((spkt(n)+0.75)/dt);
    I = zeros([size(xq) length(Tinterv)]);
    V = zeros([size(xq) length(Tinterv)]);
    Vmax = zeros(3,length(Tinterv));
    
    s = 0;
    
    for t = Tinterv
        
        s = s + 1;
        
        F = scatteredInterpolant(xy',X(t,:)','natural','linear');
        Vq = F(xq,yq);
        L = -del2(Vq,duq*pitch);
        
        % spatial filtering
        Vq = conv2(Vq,spfilt,'same');
        L = conv2(L,spfilt,'same');
        
        % Applying mask to LFP and CSD
        Vq = Vq.*Inpol;
        L = L.*Inpol;
        
        I(:,:,s) = L;
        V(:,:,s) = -Vq;
        
        [Vqmax,ind] = max(abs(Vq(:)));
        temp = xq(:);
        xmax = temp(ind);
        temp = yq(:);
        ymax = temp(ind);
        
        Vmax(:,s) = [xmax; ymax; Vqmax];
 
    end
    
    clear Vq L temp

    temp = X(Tinterv,:);
    climX = [min(temp(:)) max(temp(:))];
    climX = max(abs(climX))*[-1 1];
    clear temp
    
    climV = [min(V(:)) max(V(:))];
    climV = max(abs(climV))*[-1 1];
    
    climI = [min(I(:)) max(I(:))];
    climI = max(abs(climI))*[-1 1];
    
%%

    figure(f1)
    
    figcol = get(gcf,'color');
    
    s = 0;

    for t = Tinterv
        
        s = s + 1;
        
        subplot(2,2,[1 3])
        plot(Tinterv*dt,X(Tinterv,:),'-')
        hold on
        plot([t; t]*dt,climX','r--','linewidth',2)
        plot([Tinterv(1); Tinterv(end)]*dt,[0; 0],'k-','linewidth',1)
        grid on
        hold off
        axis tight
        set(gca,'fontsize',16)
        xlabel('time (s)')
        ylabel('field potential (mV)','fontsize',18)
        title(['t = ' num2str((t-1)*dt) ' s'],'fontsize',18)
        
        subplot(2,2,2)
        imagesc(uq,uq',squeeze(V(:,:,s)),climV)
        hc = colorbar;
        ht = get(hc,'title');
        set(ht,'string','(mV)','fontsize',16)
        set(hc,'fontsize',14)
        %title('field potential','fontsize',18)
        %title('neural activity / capacity','fontsize',18)
        title('inverted field potential','fontsize',18)
        hold on
        plot(xy(1,:),xy(2,:),'k.')
        patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
        plot(Vmax(1,s),Vmax(2,s),'wo','markerfacecolor','w')
        axis equal
        axis([0 1 0 1]*13)
        axis off
        hold off
        
        subplot(2,2,4)
        imagesc(uq,uq',squeeze(I(:,:,s)),climI)
        hc = colorbar;
        ht = get(hc,'title');
        set(ht,'string','(mV/mm^2)','fontsize',16)
        set(hc,'fontsize',14)
        title('current density / \sigma','fontsize',18)
        hold on
        plot(xy(1,:),xy(2,:),'k.')
        patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
        axis equal
        axis([0 1 0 1]*13)
        axis off
        hold off
        
        pause(0.1)

    end
        
%% 

end
