function [index mat] = roi_find_index(ROI_loc,thresh)
% XYZ = roi_find_index(ROI_loc,thresh)
% returns the XYZ address of voxels
% with values greater then threshold
% ROI_loc = string pointing to nifti image
% thresh = threshold value, defaults to zero


if ~exist('thresh'),
    thresh = 0;
end

% V = spm_vol(ROI_loc)
% 
% % read in ROI
% [Y XYZ] = spm_read_vols(V,0);
% 
% %replace NaN with zeros
% Y(isnan(Y)) = 0;
% % step through each slice - find x y location for ones in slice
% % append x y z data to index list
% index = [];
% for n = 1:size(Y,3)
%     % find values greater > thresh
%     [xx yy] = find(squeeze(Y(:,:,n)) > thresh);
%     if ~isempty(xx),
%         zz = ones(size(xx))*n;
%         index = [index,[xx';yy';zz']];
%     end
% end
% 
% 
% % translate address locations - using affine transform
% 
% index(4,:) = 1;
% index = V(1).mat(1:3,:)*index;


data = nifti(ROI_loc);
Y = double(data.dat);
Y(isnan(Y)) = 0;
index = [];
for n = 1:size(Y,3)
    % find values greater > thresh
    [xx yy] = find(squeeze(Y(:,:,n)) > thresh);
    if ~isempty(xx),
        zz = ones(size(xx))*n;
        index = [index,[xx';yy';zz']];
    end
end
% XYZ = index;
% [U S V] = svd(data.mat(1:3, 1:3));
% index(4,:) = 1;
 mat = data.mat;
% %index = data.mat(1:3,:)*index;
% index = V*index;


end

