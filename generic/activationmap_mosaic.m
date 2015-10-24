function activationmap_mosaic(Activation_Img,Template_Img,View,Slice_Range,Threshold,ChosenColorMap,Title)
% Inputs:
%   activation_img: full path to the activation image
%   template_img: full path to template overlay
%   View: (optional) Which view to overlay on. Default is Axial.
%         The selections are the following.
%           1). sagittal
%           2). coronal
%           3). axial
%   Slice_Range:(optional) which slices to include.
%               Default is to include all slices
%   Threshold: (optiona) thresholding the activation map image. Use as a
%              tuple: {'below'/'above',thresh}. 
%              Example:
%                   To keep values above 0.4, input {'above',0.4}
%   ColorMap: (optional) which colormap to use. See COLORMAP
%
%   Title: (optional) title of the entire figure
%      
%  

Activation_Img = '/nfs/jong_exp/midbrain_pilots/RestingState/analysis/Seeded_Correlation_Maps/group_level_summary_maps/Control_CC_Pearson_R_map_average.nii';
Template_Img = '/usr/local/pkg64/matlabpackages/spm8/templates/EPI.nii';
View = 'axial';
Slice_Range = 45:60;
ChosenColorMap = 'hot';
Threshold = {'below',0.05};

% inspect inputs
if nargin<3 || isempty(View)
    View = 'coronal';
end
if nargin<4 || isempty(Slice_Range)
    Slice_Range = [];
end

if nargin<6 || isempty(ChosenColorMap)
    ChosenColorMap = 'jet';
end
if nargin<7 || isempty(Title)
    Title = '';
end

% load the image
Activation_Img = load_untouch_nii(Activation_Img);
Activation_Img = Activation_Img.img;
if nargin>4  && ~isempty(Threshold)
   switch lower(Threshold{1})
       case 'below'
           Activation_Img(Activation_Img>Threshold{2}) = NaN;
       case 'above'
           Activation_Img(Activation_Img<Threshold{2}) = NaN;
   end
end
Template_Img = load_untouch_nii(Template_Img);
Template_Img = Template_Img.img;

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
Activation_Img = get_subset_img(Activation_Img,dim,Slice_Range);
Template_Img = get_subset_img(Template_Img,dim,Slice_Range);

% get the size of the plots
figure_dim = calc_subplot_dim(length(Slice_Range));

% plot each overlay
h = figure;

ChosenColorMap = colormap(ChosenColorMap);
for n = 1:length(Slice_Range)
    % get current image
    tmp_activation_img = rot90(get_subset_img(Activation_Img,dim,n));
    tmp_activation_img = INTENSITY2COLOR(tmp_activation_img,ChosenColorMap);
    tmp_template_img = rot90(get_subset_img(Template_Img,dim,n));
    % start plotting image overlay
    subplot(figure_dim(1),figure_dim(2),n);
    % show template: make the first a grey-scale image with three 
    % channels so it will not be affected by the colormap later on
    imshow(tmp_template_img(:,:,[1,1,1]));
    hold on;
    Ih = imshow(tmp_activation_img);
    set(Ih, 'AlphaData', tmp_activation_img);
    colormap(ChosenColorMap);
    hold off;
    xlabel(sprintf('Slice:%d',Slice_Range(n))); 
end

%set(h,'renderer','zbuffer');% put title on the figure
if nargin<5 || isempty(Threshold)
    suptitle(sprintf('%s %s Not Thresholded',Title,View));
else
    suptitle(sprintf('%s %s: Thresholded at %d',Threshold{2}));
end
end

%% subroutine functions
function ALPHA = INTENSITY2COLOR(IMG,C)
%convert a grayscale image to a colored image
C_IND = linspace(min(IMG(:)),max(IMG(:)),size(C,1));
D_mat = sqrt(bsxfun(@plus,dot(C_IND(:),C_IND(:),2),dot(IMG(:),IMG(:),2)')-2*(C_IND(:)*IMG(:)'));
[~,IND] = min(abs(D_mat),[],1);
ALPHA = reshape(C(IND),size(IMG));
clear C_IND D_MAT IND;
end

function IMG_out = get_subset_img(IMG,dim,Slice_Range)
if isempty(Slice_Range)
    Slice_Range = 1:size(IMG,dim);
end
% get the image based on dim. If any dimension is singlet, squeeze to
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

function figure_dim = calc_subplot_dim(num_slices)
if isprime(num_slices)
    %if prime, use nearest square
    figure_dim = [ceil(sqrt(num_slices)),ceil(sqrt(num_slices))];
else
    figure_dim = factor_pair(num_slices);
    [~,IND] = min(diff(figure_dim,1,2),[],1);
    figure_dim = figure_dim(IND,:);
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