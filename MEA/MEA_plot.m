function [f1,V,I,Vmax,xy,uq] = MEA_plot(X, Tinterv, varargin)
% Function to plot MEA grids spatial map
%
% Inputs:
%   X: time by electrodes data
%
% Optional inputs:
%   'dup': MEA plot grid resolution, default is 0.1
%   'uq': range of the MEA plot grid [min, max], default is [0.5, 12.5]
%   'xy': [col;row] indicies of all electrodes
%   'climV': color bar range for voltage
%   'climI': color bar range for current
%   'gauss_sigma': spatial filter kernel size. Default is empty.
%   'plot_scale': scale relative to the full screen [row,col,height,width],
%       default [1,1,0.5,0.5]
%   'fig_name': save the series of plot as a .gif animation or other still
%       image format such as .fig, or .bmp, depending on the extension,
%       provided that the user specified a full path to save the image.
%       Default empty, therefore, not saving.
%   'gif_speed': pause between frames of .gif animation in seconds. Default
%       is 0.1.
%   'pitch': distance between electrodes in mm. Default is 0.2.
%   'custom_sup_title': customized super title for the subplots. Default is
%            empty.
%   'verbose': display progress of processing. Default is true.
%
% Outputs:
%   f1: figure handle
%   V: voltage map over time (3rd dimension)
%   I: current density map over time (3rd dimension)
%   Vmax: max voltage map
%   xy: electrode coordinate
%   uq: plotting grid element, use [xq,yq] = meshgrid(uq) to get the
%       meshgrid map of coordinates

% Parse optional inputs
mea_property = parse_varargin(varargin,{'duq',0.1},{'uq',[0.5,12.5]},...
    {'xy',[6,6,6,6,6,6,5,5,5,5,4,4,4,4,3,3,2,5,3,2,1,4,3,2,1,4,3,2,1,5,...
    6,5,1,2,3,4,1,2,3,4,1,2,3,4,2,3,3,5,4,4,4,5,5,5,5,6,6,6,6,6,7,7,7,7,...
    7,7,8,8,8,8,9,9,9,9,10,10,11,8,10,11,12,9,10,11,12,9,10,11,12,8,7,8,...
    12,11,10,9,12,11,10,9,12,11,10,9,11,10,10,8,9,9,9,8,8,8,8,7,7,7,7,7;...
    7,8,12,11,10,9,12,11,10,9,12,11,10,9,11,10,10,8,9,9,9,8,8,8,8,7,7,7,...
    7,7,6,6,6,6,6,6,5,5,5,5,4,4,4,4,3,3,2,5,3,2,1,4,3,2,1,4,3,2,1,5,6,5,...
    1,2,3,4,1,2,3,4,1,2,3,4,2,3,3,5,4,4,4,5,5,5,5,6,6,6,6,6,7,7,7,7,7,7,...
    8,8,8,8,9,9,9,9,10,10,11,8,10,11,12,9,10,11,12,9,10,11,12,8]},...
    {'climV',[]},{'climI',[]},{'climX',[]},{'verbose',true},...
    {'gauss_sigma',[]},{'plot_scale',[1,1,0.5,0.5]},{'fig_name',''},...
    {'gif_speed',0.1},{'pitch',0.2},{'custom_sup_title',''});
% Sanity check: number of rows of X must be equal to number of Tinterv
% if mea_property.ind_mode && size(X,1) ~= numel(Tinterv)
%     error('Data size does not match time points specified');
% elseif ~mea_property.ind_mode && max(Tinterv)>size(X,1)
%     error('Index specified in time points (Tinterv) exceeds data matrix dimension');
% end
% Unwrap the structures
unwrap_data_structure(mea_property);
clear mea_property;
% define corners of the plot based on uq
corner_coord = [...
    floor(min(uq)) floor(min(uq)); floor(min(uq)) ceil(max(uq)); ...
    ceil(max(uq)) ceil(max(uq)); ceil(max(uq)) floor(min(uq))];
mea_border_size = [floor(min(uq)),ceil(max(uq)), floor(min(uq)), ceil(max(uq))];
% reconstruct uq
uq = uq(1):duq:uq(2);
%mesh grid for data plot
[xq,yq] = meshgrid(uq);
% Defining image mask: covers the corner
tri = delaunayTriangulation(xy(1,:)',xy(2,:)');
K = convexHull(tri);
pts = flipud(tri.Points(K,:));
Inpol = inpolygon(xq,yq,tri.Points(K,1),tri.Points(K,2));
[xmask, ymask] = polybool('minus', corner_coord(:,1), corner_coord(:,2), pts(:,1),pts(:,2));
[fmask,vmask] = poly2fv(xmask,ymask);
clear K corner_coord pts tri;
% Designing spatial filter
if ~isempty(gauss_sigma)
    spfilt = exp(-((xq-6.5).^2+(yq-6.5).^2)/(2*gauss_sigma^2));
    spfilt = spfilt/sum(spfilt(:));
end
% Initialize spatial map matrix matrix
I = zeros([size(xq) length(Tinterv)]);%current
V = zeros([size(xq) length(Tinterv)]);%voltage
Vmax = zeros(3,length(Tinterv));


% plot over time
for t = 1:length(Tinterv)
    %display progress
    if verbose
        fprintf([repmat('\b',1,(numel(num2str(t-1))+numel(num2str(...
            length(Tinterv)))+1)*(t>1)),'%d/%d'],t, length(Tinterv));
    end
    
    F = scatteredInterpolant(xy',eliminate_overinfluencing_electrodes(X(t,:),xy)','natural','linear');
    %F = scatteredInterpolant(xy',X(t,:)','natural','linear');
    Vq = F(xq,yq);
    
    % spatial filtering of LFP
    if ~isempty(gauss_sigma)
        Vq = filter2(spfilt, Vq); % faster
    end
    
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
clear L Vq F temp xmax ymax;

%%
% get color bars for each plot
if isempty(climX)
    climX = [min(X(:)) max(X(:))];
    climX = max(abs(climX))*[-1 1];
end
if isempty(climV)
    climV_opt = 3;
    switch climV_opt % for debug
        case 1% use largest maximum as colorbar range
            climV = [min(V(:)), max(V(:))];
            climV = max(abs(climV))*[-1,1];
        case 2% median filter the spikes out (not prepferred)
            climV = medfilt1(X,3);
            climV = max(abs(climV))*[-1,1]*1.5;
        case 3%use the second largest maximum as colorbar range
            [~,IND] = max(abs(X),[],2);
            INDK = accumarray([[1:size(X,1)]',IND(:)],ones(size(X,1),1),size(X));
            climV = X.*(~INDK);
            climV = [-1,1] * max(abs(climV(:)));
    end
    if isempty(climI)
        climI = [min(I(:)), max(I(:))];
        climI = max(abs(climI))*[-1,1];
    end
    % Start plotting
    f1 = figure('position',get(0,'ScreenSize').*plot_scale); % maximizing figure
    cmap = flipud(colormap(jet));  % defining new colormap
    figure(f1)
    figcol = get(gcf,'color');
    for t = 1:length(Tinterv)
        if length(Tinterv)>1
            % plot with subplots
            MEA_plot_TS({2,2,[1 3]},X,Tinterv,climX,t);
            MEA_plot_LFP({2,2,2},V,climV,t,uq,cmap,xy,fmask,vmask,figcol,mea_border_size);
            MEA_plot_CSD({2,2,4},I,climI,t,uq,cmap,xy,fmask,vmask,figcol,mea_border_size);
            suptitle(custom_sup_title);
        else
            MEA_plot_LFP([],V, climV, t, uq, cmap, xy, fmask, vmask, figcol, mea_border_size);
        end
        
        % write to figure
        if ~isempty(fig_name)
            [~,~,EXT] = fileparts(fig_name);
            switch EXT
                case '.gif'
                    frame = frame2im(getframe(gcf));
                    [imind, cm] = rgb2ind(frame,256);
                    if t == 1
                        imwrite(imind, cm, fig_name,'gif','LoopCount',inf,'DelayTime',gif_speed);
                    else
                        imwrite(imind, cm, fig_name,'gif','WriteMode','append','DelayTime',gif_speed);
                    end
                otherwise
                    saveas(gcf,fig_name);
            end
        end
        pause(0.05);
    end
end
end

%% use the average value of the nearest neighbor to winzorize the over-influencing electrode
function X = eliminate_overinfluencing_electrodes(X,xy)
% X is a time series by electrode matrix, in mV
% xy is 2 by electrode matrix that gives the coordinate of X
% interpolate the stimulated electrode based on the average of nearest
% neighbors
[~,S_IND] = max(abs(X),[],2);% find the over-influencing electrode at each time point
S_COORD = xy(:,S_IND);% for each time point
% pair-wise distance
D_mat = sqrt(bsxfun(@plus, dot(S_COORD',S_COORD',2), dot(xy',xy',2)')-2*(S_COORD'*xy));
% find the neighbors that has distance exactly one
[I,J] = ind2sub(size(D_mat),find(D_mat == 1));
for kk = 1:unique(I)
    X(S_IND(kk)) = mean(X(kk,J(I==kk)));
end
end

%% plot each type of data
function MEA_plot_LFP(subplot_ind,V,climV,t,uq,cmap,xy,fmask,vmask,figcol,axis_size)
% LFP
if ~isempty(subplot_ind),subplot(subplot_ind{:});end
imagesc(uq,uq',squeeze(V(:,:,t)),climV)
colormap(cmap)
hc = colorbar;
set(hc,'fontsize',14)
hold on
plot(xy(1,:),xy(2,:),'k.')
patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
%plot(Vmax(1,t),Vmax(2,t),'wo','markerfacecolor','w'); % big white dot
axis equal
axis(axis_size)
axis off
hold off
if ~isempty(subplot_ind)
    title('field potential (mV)','fontsize',16,'position',[10 0])
else
    title('field potential (mV)','fontsize',16)
end
end

function MEA_plot_CSD(subplot_ind,I,climI,t,uq,cmap,xy,fmask,vmask,figcol,axis_size)
% CSD
if ~isempty(subplot_ind),subplot(subplot_ind{:});end
imagesc(uq,uq',squeeze(I(:,:,t)),climI);
colormap(cmap)
hc = colorbar;
set(hc,'fontsize',14)
hold on
plot(xy(1,:),xy(2,:),'k.')
patch('faces',fmask,'vertices',vmask,'facecolor',figcol,'edgecolor',figcol)
axis equal
axis(axis_size)
axis off
hold off
if ~isempty(subplot_ind)
    title('current density / \sigma (mA/mm^2)','fontsize',16,'position',[10 0]);
else
    title('current density / \sigma (mA/mm^2)','fontsize',16);
end
end

function MEA_plot_TS(subplot_ind,X,Tinterv,climX,t)
% time series trace
if ~isempty(subplot_ind),subplot(subplot_ind{:});end
plot(Tinterv,X,'-')
hold on
plot([Tinterv(1); Tinterv(end)],[0; 0],'k-','linewidth',1);%horizontal line
plot([0;0],climX','k-','linewidth',2);%time indicator bar
plot([Tinterv(t); Tinterv(t)],climX','r--','linewidth',2);%time indicator bar
grid on
hold off
axis tight
xlabel(sprintf('t = %3.3f s',Tinterv(t)));
ylabel('field potential (mV)','fontsize',14)
end

%% unwrap a data structure
function unwrap_data_structure(S,F)
if nargin<2 || isempty(F), F = fieldnames(S);end
for n = 1:length(F)
    assignin('caller',F{n},S.(F{n}));
end
end

%% varargin input
function [flag,key,ind] = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1','key1'}.
% returns structure of flag and key with each option name, e.g. 'opt1' as
% field names
% also returns ind variable, which specifies the index mapping between
% options and varargin
flag = struct();%place holding
key = struct();%place holding
ind = [];
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
        ind = [ind, 2*find(tmp,1) + [-1,0]];
    else
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    if numel(varargin{n})>2
        key.(varargin{n}{1}) = varargin{n}{3};
    else
        key.(varargin{n}{1}) = [];
    end
    clear tmp;
end
ind = sort(ind);
end