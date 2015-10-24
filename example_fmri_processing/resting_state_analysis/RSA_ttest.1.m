function [T_out,P_out] = RSA_ttest(P1,P2,T_name,P_name,Mask,Tail)
% Compare two groups of images with Student's T Test
% [T_out,P_out] = RSA_ttest(P1,P2,T_name,P_name,Mask)
%
% Inputs:
%       P1: strings or cellstr of file paths to the images in group 1
%       P2: strings or cellstr of file paths to the images in group 2
%
% All images in P1 AND P2 must be normalized to the same space
%
%       T_name: name to save the t-value image as
%       P_name: name to save the p-value image as
%       Mask: (optional) mask image, to focus only on the mask voxels.
%             Similar to the ROI argument, this can be path, loaded image,
%             or 3D image itself. Mask dimension must be the same as the
%             images
%       Tail: (optional) specify alternative hypothesis (See ttest2)
%              'both'  -- "means are not equal" (two-tailed test) (Default)
%              'right' -- "mean of X is greater than mean of Y" (right-tailed test)
%              'left'  -- "mean of X is less than mean of Y" (left-tailed test)
%
% Outputs:
%       T_out: SPM image handle of the t-value map
%       P_out: SPM image handle of the p-value map
%
% Note: When adding spm package, make sure NaN functions, such as nanvar or
%       nanmean are not overwritten.

% read in the figure handles (%this is not actually loading in the images)
V1 = spm_vol(char(P1));
V2 = spm_vol(char(P2));
% Check V1 and V2 dimension
if V1(1).dim ~= V2(1).dim
    error('Image dimension does not agree');
end
% get Mask XYZ index
if nargin<5 || isempty(Mask)
    Mask_XYZ = NaN;
    Slice_Range = 1:V1(1).dim(3);
else
    %extract the Mask coordinates
    [Mask_XYZ,Mask_Size] = get_roi_index(Mask);
    Slice_Range = min(Mask_XYZ(3,:)):max(Mask_XYZ(3,:));
    %check if ROI, Mask, and raw image has the same dimension
    A = [V1(1).dim;V2(1).dim;Mask_Size];
    D_mat = sqrt(bsxfun(@plus,dot(A,A,2),dot(A,A,2)')-2*(A*A'));
    if any(D_mat(:))
        error('Mask size does not agree with image size');
    end
end
% get alternative hypothesis
if nargin<6 || isempty(Tail)
    Tail = 'both';
end

% pre-allocate some space for the correlation map
TMAP = zeros(V1(1).dim);
PMAP = zeros(V1(2).dim);

% for each slice, do t-test
for n = Slice_Range
    %print progress
    if n == Slice_Range(1)
        fprintf('Current Slice: %d',n);
    else
        fprintf([repmat('\b',1,1+floor(log10(n-1))),'%d'],n);
    end
    % get the index of current slice, after masking
    if isnan(Mask_XYZ)
        % get the index of all the voxels of current slice
        [x0,y0] = meshgrid(1:V1(1).dim(1),1:V1(1).dim(2));
        Slice_XYZ = [x0(:)';y0(:)';n*ones(1,length(x0(:)))];
        clear x0 y0;
    else
        Slice_XYZ = Mask_XYZ(:,find(Mask_XYZ(3,:) == n));
    end
    % get the data series for all voxels of current slice
    V1_Slice_dataseries = spm_get_data(V1,Slice_XYZ);
    V2_Slice_dataseries = spm_get_data(V2,Slice_XYZ);
    ind = sub2ind(size(TMAP),Slice_XYZ(1,:),Slice_XYZ(2,:),Slice_XYZ(3,:));
    % Do the t-test with ttest2, treating NaN as missing value
    [~,PMAP(ind),~,K]=ttest2(V1_Slice_dataseries,V2_Slice_dataseries,[],Tail);
    TMAP(ind) = K.tstat;
    clear ind K Slice_XYZ V1_Slice_dataseries V2_Slice_dataseries;
end
fprintf('\n');

% write out the image
T_out = V1(1);%use the info of raw data files
T_out.fname = T_name;%change the save directory and file name
T_out = spm_create_vol(T_out);%create the file
T_out = spm_write_vol(T_out,TMAP);

P_out = V1(1);%use the info of raw data files
P_out.fname = P_name;%change the save directory and file name
P_out = spm_create_vol(P_out);%create the file
P_out = spm_write_vol(P_out,PMAP);

% free some memory
clear V ROI_XYZ ROI_timeseries;
end


%% Sub-functions
function [index,ROI_Size]= get_roi_index(ROI)
if isempty(ROI)
    index = NaN;
    return;
end
% load and get ROI XYZ coordinates
switch class(ROI)
    case 'char'%assume path to seed image
        ROI = load_nii(ROI);
        ROI = ROI.img;
    case 'struct'%assume image loaded by load_nii
        ROI = ROI.img;
%otherwise, assume ROI is already a 3D image
end
% get the image of the ROI, must be loaded first as a 3D image
ROI_Size = size(ROI);
[X,Y,Z] = ind2sub(ROI_Size,find(ROI));
index = [X(:)';Y(:)';Z(:)'];
end
