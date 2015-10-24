function target_ROI = spm_ITKSNAP_coreg_ROIs(source_ROI,template_image,dim_diff,target_name)
% Move ROI from one template to another. This mediates coregsitration
% differences between two templates when drawing ROIs in ITK-SNAP.
% Templates must have the same rotational orientation.
%
% Inputs:
%   source_ROI: ROI to be moved
%   template_image: new template to be the ROIs into
%   dim_diff: 2x3 matrix; given any arbitrary point of the two templates
%           (source ROI's original template and the new template), these 
%           two points represent exactly the same anatomical region. The
%           first row gives the coordinate (in terms of data matrix's
%           dimension, not in mm) of the ROI's originl template, and the
%           second row gives the coordinate of the new template. Open
%           ITK-SNAP and load both images. Click anywhere on the image. The
%           image should be coregsitered automatically by ITK-SNAP. Take
%           the coordinate of these points (order: axial=Z, sagittal=X,
%           coronal=Y), and specified the matrix as [X1,Y1,Z1;X2,Y2,Z2].
%   target_name: name to save the new ROI as.
%
% Output:
%   target_ROI: spm_vol handle of the target ROI

% source_ROI = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/fullhead/M3128_CNI_060314_fullhead_ACPC_SNleft_STNleft_RNleft_VTAleft.nii';
% template_image = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/TR2/resample_rM3128_CNI_060314_average_TR2.nii';%the rois will be in this image's space
% dim_diff = [120,147,145;117,99,107];% [source_pos; target_pos]
% target_name = 'M3128_CNI_060314_TR2_ACPC_SNleft_STNleft_RNleft_VTAleft.nii';

% load ROI information
[XYZ,Y,~,~,dt] = sub_get_roi_info(source_ROI);
% load template image
target_ROI = spm_vol(template_image);
% shift the indices to the target image space
XYZ = bsxfun(@plus,XYZ,diff(dim_diff,1)');
% put the new data to a new data matrix
DATA = zeros(target_ROI.dim);
DATA(sub2ind(target_ROI.dim,XYZ(1,:),XYZ(2,:),XYZ(3,:))) = Y;
% write out the new ROI
target_ROI.fname = target_name;
target_ROI.dt = dt;
target_ROI = spm_create_vol(target_ROI);
target_ROI = spm_write_vol(target_ROI,DATA);
end

function [XYZ,M,mat,dim,dt]=sub_get_roi_info(V)
% get ROI or any binary mask information
% Inputs:
%   V: either path to the image or spm_vol loaded image handle
% Outputs:
%   XYZ: coordinate the mask
%   M: values at the coordiante
%   mat: rotation matrix of the mask
%   dim: dimension of the mask
%   dt: data type
if iscellstr(V),V = char(V);end
if ischar(V),V = spm_vol(V);end
mat = V.mat;dim=V.dim;dt=V.dt;
V = double(V.private.dat);
[X,Y,Z] = ind2sub(size(V),find(V));
XYZ = [X(:)';Y(:)';Z(:)']; clear X Y Z;
M = V(V~=0); M = M(:)';
end

