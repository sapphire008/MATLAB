function [XYZ,M,mat,dim,dt]=get_roi_info(V)
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