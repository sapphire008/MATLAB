function Y = spm_get_slice(P,dim,slicenum)
% Get data from the specified slice from a stack of 3D volumes
% Inputs:
%   P: spm_vol loaded image handle
%   dim: dimension to get the slice from
%   slicenum: which slice to get
% Output:
%   Y: T x M x N matrix, where T is the number of volumes in P, M and N are
%      dimensions of the slices

% sanity check
nslices = P(1).dim(dim);
if slicenum>nslices
    error('Slice number requested is beyond the total number of slices in current dimension\n');
end
clear nslices;
notdim = [1,2,3];
notdim = notdim(notdim~=dim);
[X,Y] = meshgrid(1:P(1).dim(notdim(1)),1:P(1).dim(notdim(2)));
XYZ = zeros(3,numel(X));
XYZ(dim,:) = slicenum*ones(1,numel(X));
XYZ(notdim(1),:) = X(:)';
XYZ(notdim(2),:) = Y(:)';
clear X Y;
Y = spm_get_data(P,XYZ);
clear XYZ;
Y = squeeze(reshape(Y,[numel(P),P(1).dim(notdim)]));
end