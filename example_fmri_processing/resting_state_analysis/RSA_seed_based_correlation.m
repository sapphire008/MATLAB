function [V_out,SEEDMAP] = RSA_seed_based_correlation(P,ROI,save_name,Mask,Mode)
% SEEDMAP=RSA_seed_based_correlation(P,ROI,save_name,MASK,mode)
% compute a seed based correlation map
% Inputs:
%       P: strings or cellstr of file paths.
%       ROI: ROI seed image, to which correlation will be calculated with.
%             This can be a path to the ROI, or loaded ROI image
%             with load_nii, or the 3D image itself
%       save_name: name to save the file as
%       Mask: Optional; mask image, to focus only on the mask voxels.
%             Similar to the ROI argument, this can be path, loaded image,
%             or 3D image itself
%       Mode: Optional; by default, output as a map of Pearson's
%             correlation. Possible modes are:
%               1).'pearson' (default): Pearson's correlation
%               2).'zscore': normalized z-score, using Fisher's R to Z 
%                            transform
% Outputs:
%       V_out: SPM image handle of the seeded map
%       SEEDMAP: actual 3D matrix of the seeded map

% ROI = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/MP021_051713_TR3_SNleft.nii';
% P_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/subjects/funcs/MP021_051713/';
% P=dir([P_dir,'2sresample_*.nii']);
% P=cellfun(@(x) [P_dir,x],{P.name},'un',0);
% P=char(P);
% Mask = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/MP021_051713_average_TR3_mask.nii';
% save_name = '/nfs/jong_exp/midbrain_pilots/scripts/resting_state_analysis/corr_V.nii';

% read in the figure handles
V = spm_vol(char(P));%this is not actually loading in the images
% get ROI XYZ index
[ROI_XYZ,ROI_Size] = get_roi_index(ROI);
% get Mask XYZ index
if nargin<4
    Mask_XYZ = NaN;
    Slice_Range = 1:V(1).dim(3);
    % check if ROI and raw image has the same dimension
    if any(V(1).dim ~= ROI_size)
        error('ROI size and raw image size do not agree!');
    end
else
    %extract the Mask coordinates
    [Mask_XYZ,Mask_Size] = get_roi_index(Mask);
    Slice_Range = min(Mask_XYZ(3,:)):max(Mask_XYZ(3,:));
    %check if ROI, Mask, and raw image has the same dimension
    A = [ROI_Size;Mask_Size;V(1).dim];
    D_mat = sqrt(bsxfun(@plus,dot(A,A,2),dot(A,A,2)')-2*(A*A'));
    if any(D_mat(:))
        error('ROI size, Mask size, and raw image size do not agree!');
    end
    
end
if nargin<5 || isempty(Mode)
    Mode = 'pearson';
end

% get time series from the ROI_XYZ
ROI_timeseries = mean(spm_get_data(V,ROI_XYZ),2);

% pre-allocate some space for the correlation map
SEEDMAP = zeros(V(1).dim);

% for each slice, generate a correlation map
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
        [x0,y0] = meshgrid(1:V(1).dim(1),1:V(1).dim(2));
        Slice_XYZ = [x0(:)';y0(:)';n*ones(1,length(x0(:)))];
        clear x0 y0;
    else
        Slice_XYZ = Mask_XYZ(:,find(Mask_XYZ(3,:) == n));
    end
    % get the time series data for all voxels of current slice
    Slice_timeseries = spm_get_data(V,Slice_XYZ);
    SEEDMAP(sub2ind(size(SEEDMAP),Slice_XYZ(1,:),...
        Slice_XYZ(2,:),Slice_XYZ(3,:)))=...
        faster_corr(repmat(ROI_timeseries,1,size(Slice_XYZ,2)),Slice_timeseries);
    clear Slice_XYZ Slice_timeseries;
end
fprintf('\n');

% convert the seed map score if necessary
switch Mode
    case 'zscore'
        SEEDMAP = atanh(SEEDMAP);
end

% write out the image
V_out = V(1);%use the info of raw data files
V_out.fname = save_name;%change the save directory and file name
V_out = spm_create_vol(V_out);%create the file
V_out = spm_write_vol(V_out,SEEDMAP);

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

function R=faster_corr(X,Y)
%faster way to compute Pearson's correlation
%http://stackoverflow.com/questions/9262933/what-is-a-fast-way-to-compute-column-by-column-correlation-in-matlab
X=bsxfun(@minus,X,mean(X,1));
Y=bsxfun(@minus,Y,mean(Y,1));
X=bsxfun(@times,X,1./sqrt(sum(X.^2,1))); %% L2-normalization
Y=bsxfun(@times,Y,1./sqrt(sum(Y.^2,1))); %% L2-normalization
R=sum(X.*Y,1);
end
