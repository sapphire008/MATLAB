function [image_out,view_dim,num_kept_slice] = ROI_find_bounded_img(image_in,ROI_in,display_mode)
% [image_out,view_dim,num_kept_slice] = find_bounded_img(image_in,ROI_in,display_mode)
% Cut template image of ROI and keep only slices that contains the ROI
% Inputs:
%       image_in: 3D template images (dimension N x M x R)
%       ROI_in: ROI clusters, (dimension N x M x R)
%           Note image_in and ROI_in must be the same dimension
%       display_mode: 'saggital' | 'coronal' | 'axial'; 1|2|3
%                     This assusmes that 
%                     the first dimension is saggital with size N;
%                     the second dimension is coronal with size M; 
%                     and the third dimension is axial, with size R.
% 
% Outputs:
%       image_out: template images that contains only the ROI slices.
%                  For selected dimension, specified in display_mode, all
%                  the voxels in the other two dimensions are kept, whereas
%                  only slices of current dimension that contains 
%                  ROIs are kept.
%       view_dim: converted the word 'saggital' to 1, 'coronal' to
%                 2, 'axial' to 3, as dimension numbers
%       num_kept_slice: number of slices kept in current dimension


%sanity check
if size(image_in) ~= size(ROI_in)
    error('size of image must be equal to the size of ROI');
end
%get the location where the ROI is located
[X,Y,Z] = ind2sub(size(image_in),find(ROI_in));
%load only bounded slices
switch display_mode
    case {'sagittal',1}
        image_out = image_in(unique(X),:,:);
        view_dim = 1;
        num_kept_slice = length(unique(X));
    case {'coronal',2}
        image_out = image_in(:,unique(Y),:);
        view_dim = 2;
        num_kept_slice = length(unique(Y));
    case {'axial',3}
        image_out = image_in(:,:,unique(Z));
        view_dim = 3;
        num_kept_slice = length(unique(Z));
end
clear X Y Z;
end