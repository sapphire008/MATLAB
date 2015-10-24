function V = spm_img_snr(P,Q,algorithm,verbose)
% Image SNR calculator.
%
% Inputs:
%   P: list of files (3D or 4D .nii images), or SPM file_array handles
%      (loaded by spm_vol)
%   Q: output image. Default is SNR.nii at the same directory as the input
%
%   algorithm (optional): ways to calcualte SNR, along with others
%       1: SNR = mean(voxel_t)/std(voxel_t)
%       2: SNR = mean(voxel_t)/std(voxel_t - global_3rd_order_polynomial_trend)
%       3: STD = std(voxel_t)
%
%   verbose (optional): display progress. Default is false.
%
% Output:
%   V: SPM nifti file_array handle of the SNR output image
%

% Algorithm 1 is according to Ben Inglis' blog: 
% http://practicalfmri.blogspot.com/2011/01/comparing-fmri-protocols.html
% Algorithm 2 is from Bob Dougherty's Python script for QA at Center for
% Cognitive and Neurobiological Imaging at Stanford University. Git hub:
% https://github.com/cni/nims/blob/master/nimsproc/qa_report.py


% parse inputs
if ischar(P)
    P = spm_vol(P);
elseif iscellstr(P)
    P = spm_vol(char(P));
elseif iscell(P)  && isfield(P{1},'private') && isa(P{1}.private,'nifti')
    P = cell2mat(P);
elseif isstruct(P) && isfield(P(1),'private') && isa(P(1).private,'nifti')
else
    error('Unrecognized input image format!\n');
end
if nargin<2 || isempty(Q)%default: name the output SNR.nii
    Q = fullfile(fileparts(P(1).fname),'SNR.nii');
end
if nargin<3 || isempty(algorithm)%default:use algorithm 1
    algorithm = 1;
end
if nargin<4 || isempty(verbose)%default: not displaying progress
    verbose = false;
end
% create the output
V = P(1);
V.fname = Q;%change name
V = spm_create_vol(V);%create header
% transverse through all the planes to calculate SNR
for n = 1:V.dim(3)
    if verbose
        fprintf('Calculating slice %d\n',n);
    end
    % get the stack of slices
    Y = spm_get_slice(P,3,n);
    switch algorithm
        case 1
            % SNR = mean(voxel_t)/std(voxel_t)
            % Ben Inglis
            SNR = squeeze(nanmean(Y,1)./nanstd(Y,[],1));
        case 2
            % SNR = mean(voxel_t)/std(voxel_t - global_3rd_order_polynomial_trend)
            % Bob Dougherty
            SNR = polyval(polyfit(1:numel(P),...%global trend
                squeeze(nanmean(nanmean(Y,2),3))',3),1:numel(P))';
            SNR = squeeze(nanmean(Y,1)./(nanstd(bsxfun(@minus,Y,...
                reshape(SNR,[numel(SNR),1,1])),[],1)));
        case 3% standard deviation image
            SNR = squeeze(nanstd(Y,1,1));
    end
    % write slice by slice
    V = spm_write_plane(V,SNR,n);
end
end

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
[Y,X] = meshgrid(1:P(1).dim(notdim(2)),1:P(1).dim(notdim(1)));
XYZ = zeros(3,numel(X));
XYZ(dim,:) = slicenum*ones(1,numel(X));
XYZ(notdim(1),:) = X(:)';
XYZ(notdim(2),:) = Y(:)';
clear X Y;
% get the data according to dimension requested
Y = spm_get_data(P,XYZ);
Y = reshape(Y,[numel(P),P(1).dim(notdim)]);
end