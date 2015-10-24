function [images,params,Query] = imreg_segment(images,params,Border,TEMPLATE)
%[images,W] = imreg_segment(images,params)
% Auto-segmenting target images based on Hausdorff Distance
%
% Structure fields of modifications:
%
% a). images.cleaner:   images of recognized markers;
% b). params.Window:    the crop window of the image, as 
%                       [row_start, row_end, col_start, col_end]
%
% Also returns:
%   Query: ['Yes'|'No'|'Cancel'] indicates user's response whether or not
%          the segmentation is good.
% 
% Some optional inputs:
%   Border: leave number of pixels as margin during cropping.
%   TEMPLATE: default is a square. Used as image segmentation matching
%             target.
% 
% Uses Hausdorff distance to match the template to each segmentation of the
% image. 1). Binary thresholding according to the choice of user; 2).
% Optional median filter; 3). Label the binary image; 4). For each label,
% calculate Hausdorff distance between the segment and the TEMPLATE; 5).
% Locate the two segments that have the minimal Hausdorff distance with the
% template; 6). Calculate inter-centroid distance of the fiducial marker;
% 7). Use the first frame as reference, find frames that have
% inter-centroid distance beyond +/-3 pixels. 8). If any, exclude the
% mis-segmented frames, calculate a window based on other frames, and redo
% segmentation after cropping the image according the calculated window.
%
% Before going to this step, the user can specify a Window as params.Window
% to crop the input image before doing segmentation. This can usually help 
% with avoiding segments with artifacts.

%cropping border
if nargin<3 || isempty(Border),Border = 50; end 
% Make a template
if nargin<4 || isempty(TEMPLATE)
    TEMPLATE = false(100,100);
    TEMPLATE(30:70, 30:70) = true;
end
% Display
disp('Auto Segmentation ...'); disp('');
tic;
% Set up window: [row_start, row_end, col_start, col_end]
window_flag = isfield(params,'Window');
if ~window_flag
    params.Window = [1,size(images(1).gray,1),1,size(images(1).gray,2)];
end
% segment images
[images, Window] = segment_image_main(images,params,TEMPLATE,1:params.image_num);

% reprocess if some images are not segmented correctly and no window
% provided
if ~window_flag
    % Calculate LR centroid distance
    LR = cellfun(@(x) sqrt(sum(diff(x,1,1).^2)),{images.LRcenter});
    % Use the first LR as reference, find anything that is beyond +/-3
    IND = (LR>LR(1)+3) | (LR<LR(1)-3); NOT_IND = find(~IND); IND = find(IND);
    params.Window = [min(Window(NOT_IND,1)),max(Window(NOT_IND,2)),...
        min(Window(NOT_IND,3)),max(Window(NOT_IND,4))];
    %Adjust the window
    params.Window([1,3]) = max([params.Window([1,3])-Border;1,1],[],1);%max row/col start
    params.Window([2,4]) = min([params.Window([2,4])+Border;params.img_dim],[],1);%min row/col end
    if ~isempty(IND)
        %reprocess these images
        disp('Redo segmentation for some images ...'); disp('');
        try
            images = segment_image_main(images,params,TEMPLATE,IND);
        catch ERR
            Query = 'No';
            disp(ERR.message);
            return;
        end
    end
    % Crop the images if not already
    for m = NOT_IND
        images(m).cleaner = images(m).cleaner(params.Window(1):params.Window(2),...
            params.Window(3):params.Window(4));
    end
end

images = rmfield(images,'LRcenter');
toc;
fprintf('\n');

% If interactive, ask the user to view the cropped images
if params.interactive
    Query = questdlg('Do you want to view the cropped and cleaned images?',...
        'Marker Auto-Detection','Yes','No','Cancel','Yes');
    if strcmpi(Query,'Yes')
        imreg_display(images,'cleaner');
    end
    % let user decide if the segmentation is successful
    Query = questdlg('Happy with the segmentation?','Segmentation',...
        'Yes','No','Cancel','No');
else
    Query = 'Yes';
end

% Remove the original image field if not saving the workspace
if ~params.save_workspace && strcmpi(Query,'Yes')
    images = rmfield(images,'gray');
end
end

%% Segmentation Subroutines
function [images, Window] = segment_image_main(images,params,TEMPLATE,IND)
% initialize LRcenter
if ~isfield(images(1),'LRcenter')
    images(params.image_num).LRcenter =  [];
end
Window = zeros(params.image_num,4);
% Recognize the feature for each image
if exist(fullfile(matlabroot,'toolbox/distcomp'),'dir') && ...
        length(IND) == params.image_num %use parallel processing toolbox
    Crop_row = params.Window(1):params.Window(2);
    Crop_col = params.Window(3):params.Window(4);
    bin_thresh = params.bin_thresh; min_area = params.min_area;
    W_1 = params.Window(1); W_3 = params.Window(3);
    medfilt = params.medfilt;
    try
        evalc('matlabpool(5)');%create workpool silently
        parfor n = IND
            % segment the images
            [images(n).cleaner,BB,images(n).LRcenter] = segment_image(...
                images(n).gray(Crop_row, Crop_col),TEMPLATE, bin_thresh,...
                [min_area,50000],medfilt);
            % Update window
            Window(n,:) = [BB(1:2) + W_1-1, BB(3:4)+W_3-1];
        end
        evalc('matlabpool close');%close workpool silently
    catch ERROR
        evalc('matlabpool close force');%close workpool silently
        rethrow(ERROR);
    end
    fprintf('\n');
else % if parallel processing toolbox not present, expect being slow.
    fprintf('Image :    ');%initialize text progress
    for n = IND
        % start displaying progress
        fprintf([repmat('\b',1,(numel(num2str(n-1))+numel(num2str(...
            length(images)))+1)*(n>1)),'%d/%d'],n, length(images));
        % segment the images
        [images(n).cleaner,BB,images(n).LRcenter] = segment_image(images(n).gray(...
            params.Window(1):params.Window(2),params.Window(3):params.Window(4)),...
            TEMPLATE, params.bin_thresh,[params.min_area,50000],...
            params.medfilt);
        % Update window after adjusting cropping
        Window(n,:) = [BB(1:2)+params.Window(1)-1,BB(3:4)+params.Window(3)-1];
    end
    fprintf('\n\n');%leave some space
end
end

function [IMAGE,BB,LR] = segment_image(IMAGE,TEMPLATE,BIN_THRESH,FEATURE_SIZE_RANGE,MEDFILT_SIZE)
% Convert to binary image
Labeled_IMAGE = ~im2bw(IMAGE,BIN_THRESH);
% Median filter / smoothing
if nargin>4 && ~isempty(MEDFILT_SIZE)
    Labeled_IMAGE = medfilt2(Labeled_IMAGE,MEDFILT_SIZE);
end
% Label the image: 8-connected
Labeled_IMAGE = bwlabel(Labeled_IMAGE,8);
% Index the labels
[N,X] = hist(Labeled_IMAGE(:),unique(Labeled_IMAGE(:)));
% Filter segments size to be within feature size range
X = X(N>min(FEATURE_SIZE_RANGE) & N<max(FEATURE_SIZE_RANGE));
%N = N(N>min(FEATURE_SIZE_RANGE) & N<max(FEATURE_SIZE_RANGE));
% Filter out segments with zero labels
%N = N(X>0);
X = X(X>0);
%N = N(:);
X = X(:);

% For each pair of segments, calculate Hausdorff Distance
DIST = NaN(numel(X),1);
for n = 1:numel(X)
    % get a segment
    tmp = get_image_piece(Labeled_IMAGE,X(n));
    % find Hausdorff distance
    DIST(n,1) = HausdorffDist_template_matching(TEMPLATE,tmp);
end

% Sort in order to choose the top 2 that most resembling a square
[~,MINLOC] = sort(DIST,'ascend');

% Get centroids of segmented parts
LR = zeros(2,2);
for ss = 1:2
    tmp_img = get_image_piece(Labeled_IMAGE, X(MINLOC(ss)));
    % Find Left and Right Center
    [row,col] = ind2sub(size(tmp_img),find(tmp_img));
    LR(ss,:) = [mean(row), mean(col)];
end

% Get Final Image
clear IMAGE; IMAGE = logical(get_image_piece(Labeled_IMAGE, X(MINLOC(1:2))));
% Find the coordinate of the segmented features
[row,col] = ind2sub(size(IMAGE),find(IMAGE));
% calculate bounding box
BB = [min(row), max(row), min(col), max(col)];

% Clear some variables
clear N X n a MINLOC DIST Labeled_IMAGE tmp TEMPLATE BIN_THRESH FEATURE_SIZE_RANGE row col;
end

%% Function to calculate HausdorffDist
function MHD = HausdorffDist_template_matching(TEMPLATE,IMAGE)
% IMAGE = HausdorffDist_template_matching(TEMPLATE_IMAGE, SOURCE_IMAGE)
% Use HausdorffDist to match image to template
% Both TEMPLATE_IMAGE and SOURCE_IMAGE must be binary
% Edged image will be calculated before the template matching

% Find the edge of the binary image using Roberts algorithm
TEMPLATE = edge(TEMPLATE,'Roberts');
IMAGE = edge(IMAGE,'Roberts');

% Find the coordinates of the points
% Must center the points to the origin in order to compare to shapes
[row,col] = ind2sub(size(TEMPLATE),find(TEMPLATE));
T = [row(:)-mean(row(:)),col(:)-mean(col(:))];
[row,col] = ind2sub(size(IMAGE),find(IMAGE));
I = [row(:)-mean(row(:)),col(:)-mean(col(:))];

% Find the Modified Hausdorff Distance between template and image
% the MDH score indicates the maximum averaged discripency between template
% and image
MHD = ModHausdorffDist(T,I);
%MHD = HausdorffDist(P.TEMPLATE,P.IMAGE);
end

%% Modified HausdorffDist
function [mhd,fhd,rhd] = ModHausdorffDist(A,B)
%[modified_dist, forward_dist, reverse_dir] = ModHausdorffDist(PointSetA,PointSetB)
% 
% This function computes the Modified Hausdorff Distance (MHD) which is 
% proven to function better than the directed HD as per Dubuisson et al. 
% in the following work:
% 
% M. P. Dubuisson and A. K. Jain. A Modified Hausdorff distance for object 
% matching. In ICPR94, pages A:566-568, Jerusalem, Israel, 1994.
% http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=576361
% 
% The function computed the forward and reverse distances and outputs the 
% maximum/minimum of both. 
% Optionally, the function can return forward and reverse distance.
% 
% Format for calling function:
% 
% [MHD,FHD,RHD] = ModHausdorffDist(A,B);
% 
% where
% MHD = Modified Hausdorff Distance.
% FHD = Forward Hausdorff Distance: minimum distance from all points of B
%       to a point in A, averaged for all A
% RHD = Reverse Hausdorff Distance: minimum distance from all points of A
%       to a point in B, averaged for all B
% A -> Point set 1, [row as observations, and col as dimensions]
% B -> Point set 2, [row as observations, and col as dimensions]
% 
% No. of samples of each point set may be different but the dimension of
% the points must be the same.
%
% Code Written by B S SasiKanth, Indian Institute of Technology Guwahati.
% Website: www.bsasikanth.com
% E-Mail:  bsasikanth@gmail.com
% Modified by Edward DongBo Cui for faster pair-wise distance calculation;
% Stanford University; 10/21/2013

% BEGINNING OF CODE

% Calculate Distance matrix
D_mat = sqrt(bsxfun(@plus,dot(A,A,2),dot(B,B,2)')-2*(A*B'));
% Calculating the forward HD: mean(min(each col))
fhd = mean(min(D_mat,[],2),1);
% Calculating the reverse HD: mean(min(each row))
rhd = mean(min(D_mat,[],1),2);
% Calculating mhd
mhd = max(fhd,rhd);
end


%% Get pieces of labeled images
function IMAGE = get_image_piece(IMAGE,Label_Number)
% IMAGE = get_image_piece(Labeled_IMAGE,Label_Number)
% generating segmented version of labeled images, keeping the dimension of
% the original image
%    Inputs:
%       Labeled_IMAGE: binary image generated from bwlabel
%       Label_Number: which image labels to extract? cannot be empty
%
%   Outpus:
%       IMAGE with only specified labels, whereas all other labels are set
%       to 0

% segmenting images
IND = true(size(IMAGE));
for n = 1:length(Label_Number)
    IND = IND & (IMAGE ~= Label_Number(n));
end
IMAGE(IND) = 0;
end
