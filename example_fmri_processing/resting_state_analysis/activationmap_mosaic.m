function activationmap_mosaic(Activation_Img,Template_Img,View,Slice_Range,Threshold,PlotOpt,ColorMapOpt)
% Plot mosaic slices of activation maps
%
% activationmap_mosaic(Activation_Img,Template_Img,View,Slice_Range,Threshold,ColorMap,Title)
%
% Inputs:
%   Activation_Img: full path to the activation image
%   Template_Img: full path to template overlay
%   View: (optional) Which view to overlay on. Default is Axial.
%         The selections are the following (either number or string).
%           1). sagittal
%           2). coronal
%           3). axial
%          View will be shown on the title of the entire figure
%   Slice_Range:(optional) which slices to include.
%               Default is to include all slices
%   Threshold: (optional) thresholding the activation map image. Use as a
%              dictionary fashion: {'below'/'above',thresh}. 
%              Example:
%                   To keep values above 0.4, input {'above',0.4}
%              Value will be shown in the title if specified
%   PlotOpt: (optional) Additional plot options, input as a doublet
%             {Title,subplot_arrangement}
%           ~ Title: extra title of the figure prepended to 
%                    Threshold and View information
%           ~ subplot_arrangement: in M x N subplots, assume M > N
%                       if 'vertical', will arrange subplot as M x N
%                       if 'horizontal', will arrange subplot as N x M
%           Default: {'','horizontal'}
%   ColorMapOpt: (optional) which colormap to use.  Input as a
%                triplets {ColorMapName,ColorRange,Reverse}. 
%           ~ ColorMapName: See COLORMAP. Deafult 'jet'
%           ~ ColorRange: By default the colormap will range from thelowest 
%                         to the highest value in the image. This can be 
%                         changed by specifying a couplet of max and min 
%                         value i.e. [minValue, maxValue] in ColorRange
%           ~ Reverse: [true|false] whether or not reverse the colorbar
%                       direction, so that smaller value corresponds to
%                       brighter color. E.g. in jet colormap, blue
%                       corresponds to small value and red corresponds to
%                       large value. If set Reverse = true, blue will
%                       correspond to large value and red will correspond
%                       to small value.
%           ~ Default: {'jet',[],false}
%

% inspect inputs
if nargin<3 || isempty(View)
    View = 'coronal';
end
if nargin<4 || isempty(Slice_Range)
    Slice_Range = [];
end
if nargin<6 || isempty(PlotOpt)
    PlotOpt = {'','horizontal'};
else
    PlotOpt{1} = regexprep(PlotOpt{1},'_','\_');
end
if nargin<7 || isempty(ColorMapOpt)
    ColorMapOpt = {'jet',[],false};
end

% load the image
Template_Img = load_nii(Template_Img);
Header = Template_Img.hdr;% save the header info
Template_Img = Template_Img.img;
Activation_Img = load_nii(Activation_Img);
Activation_Img = Activation_Img.img;
if nargin>4  && ~isempty(Threshold)
   switch lower(Threshold{1})
       case 'below'
           Activation_Img(Activation_Img>Threshold{2}) = NaN;
       case 'above'
           Activation_Img(Activation_Img<Threshold{2}) = NaN;
   end
end

% check if the size are the same
if ~all(size(Activation_Img) == size(Template_Img))
    error('Map size does not match the template size!');
end

% generate subset of wanted slices based on View and Slice Range
dim = -1; %initialize
if ischar(View)
    switch lower(View)
        case 'sagittal'
            dim = 1;
        case 'coronal'
            dim = 2;
        case 'axial'
            dim = 3;
    end
elseif isinteger(View) && View<4 && View > 0
    dim = View;
    switch View
        case 1
            View = 'sagittal';
        case 2
            View = 'coronal';
        case 3
            View = 'axial';
    end
end
if dim < 0
    error('Unrecognized dimension input dim.')
end
[Template_Img,Slice_Range] = get_subset_img(Template_Img,dim,Slice_Range);
Activation_Img = get_subset_img(Activation_Img,dim,Slice_Range);

% get slice range in mm for labeling purpose
[Slice_Range_mm,Slice_Sign] = Voxel2MM(Slice_Range,dim,Header);

% get the size of the plots
figure_dim = calc_subplot_dim(length(Slice_Range),PlotOpt{2});

% convert colormap name to colormap matrix
if ischar(ColorMapOpt{1})
    ColorMapOpt{1} = colormap(ColorMapOpt{1});
end

% compute color range base on min and max of activation image
if isempty(ColorMapOpt{2})
    C_Range = [min(Activation_Img(:)),max(Activation_Img(:))];
else
    C_Range = ColorMapOpt{2};
end

% plot each overlay
for n = 1:length(Slice_Range)
    % get current image
    tmp_activation_img = rot90(get_subset_img(Activation_Img,dim,n));
    tmp_activation_img = INTENSITY2COLOR(...
        tmp_activation_img,ColorMapOpt{1},C_Range);
    tmp_template_img = rot90(get_subset_img(Template_Img,dim,n));
    % start plotting image overlay
    subplot(figure_dim(1),figure_dim(2),n);
    % show template: make the first a grey-scale image with three 
    % channels so it will not be affected by the colormap later on
    imagesc(tmp_template_img(:,:,[1,1,1]));
    colormap gray;
    hold on;
    Ih = imagesc(tmp_activation_img);
    set(Ih, 'AlphaData', tmp_activation_img);
    colormap(ColorMapOpt{1});
    hold off;
    xlabel(sprintf('Slice:%s%dmm',Slice_Sign{n},Slice_Range_mm(n))); 
    set(gca,'visible','off');
    set(findall(gca,'type','text'),'visible','on');
end

% put title on the figure
if nargin>4 && ~isempty(Threshold)
    suptitle(sprintf('%s %s Thresholded %s at %.2f',...
        regexprep(PlotOpt{1},'_','\_'),View,Threshold{1},Threshold{2}));
else
    suptitle(sprintf('%s %s: Not Thresholded', ...
        Pregexprep(PlotOpt{1},'_','\_'),View));
end

% put colorbar
lastsubplotposition = get(gca,'position');
colorbar('location','eastoutside');
if ColorMapOpt{3}
    colormap(flipud(ColorMapOpt{1}));
end
caxis(C_Range);
set(gca,'position',lastsubplotposition);
end

%% Subroutine functions
function ALPHA = INTENSITY2COLOR(IMG,C,C_Range)
%convert a grayscale image to a colored image
C_IND = linspace(C_Range(1),C_Range(2),size(C,1));
D_mat = sqrt(bsxfun(@plus,dot(C_IND(:),C_IND(:),2),dot(IMG(:),IMG(:),2)')-2*(C_IND(:)*IMG(:)'));
[~,IND] = min(abs(D_mat),[],1);
ALPHA = reshape(C(IND),size(IMG));
clear C_IND D_MAT IND;
end

function [Slice_Range_mm,Slice_Sign] = Voxel2MM(Slice_Range,dim,Header)
% get a reference frame
ORIGIN = Header.hist.originator(1:3);%origin in voxel
VOXEL_SIZE = Header.dime.pixdim(2:4);%voxel size in mm
IMAGE_SIZE = Header.dime.dim(2:4);% image dimension
% check if slice range is within the image size
if max(Slice_Range) > IMAGE_SIZE(dim)
    Slice_Range(Slice_Range == max(Slice_Range)) = IMAGE_SIZE(dim);
end
% convert voxel to mm from origin
Slice_Range_mm = (Slice_Range-ORIGIN(dim))*VOXEL_SIZE(dim);
% get the sign of slice number
Slice_Sign = cell(1,length(Slice_Range));
Slice_Sign(Slice_Range_mm<0) = {''};
Slice_Sign(Slice_Range_mm>=0) = {'+'};
end

function [IMG_out,Slice_Range] = get_subset_img(IMG,dim,Slice_Range)
if isempty(Slice_Range)
    Slice_Range = 1:size(IMG,dim);
end
% get the image based on dim. If any dimension is singleton, squeeze to
% produce 2D image
switch dim
    case 1
        IMG_out = squeeze(IMG(Slice_Range,:,:));
    case 2
        IMG_out = squeeze(IMG(:,Slice_Range,:));
    case 3
        IMG_out = squeeze(IMG(:,:,Slice_Range));
end
end

function figure_dim = calc_subplot_dim(num_slices,DIRECTION)
if nargin<2 || isempty(DIRECTION)
    DIRECTION = 'horizontal';
end
% for 2 and 3, plot vertically
if num_slices == 2 || num_slices == 3
    switch DIRECTION
        case 'horizontal'
            figure_dim = [1,num_slices];
        case 'vertical'
            figure_dim = [num_slices,1];
    end
    return;
end
% find nearest square
S = ceil(sqrt(num_slices));
% for prime number, find the next composite
if isprime(num_slices)
    % since num_slices now is greater than 2, the next number to the
    % current prime number must be even and therefore composite
    num_slices = num_slices + 1;
end
% compare nearest square to min diff factor pair
F = factor_pair(num_slices);
[~,IND] = min(diff(F,1,2),[],1);
F = F(IND,:);
if diff(F) < (S^2-num_slices)
    switch DIRECTION
        case 'horizontal'
            figure_dim = [min(F),max(F)];
        case 'vertical'
            figure_dim = [max(F),min(F)];
    end
else
    figure_dim = [S,S];
end
end

function F = factor_pair(N)
tmp = factor(N);
F = zeros(length(tmp),2);
F(1,:) = [1,N];
for n = 1:length(tmp)-1
    F(n+1,:) = [prod(tmp(1:n)),prod(tmp(n+1:end))];
end
end