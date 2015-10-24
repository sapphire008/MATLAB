function betas = extract_roi_betas(Images,ROI_loc,adjust_logical)
% Required inputs:
%       Images: cellstr or matrix of images
%
%       ROI_loc: string or cellstr of ROI locations, 
%                assuming they are nifti files\
%
% Optional Inputs:
%       adjust: [0|1] logical, default 1. Adjust ROI image space so that 
%               it matches the space of Images

% Inspect optional input(s)
if nargin<3
    adjust_logical = 1;
end

% Converts all inputs to cellstr
Images = cellstr(Images);
ROI_loc = cellstr(ROI_loc);

for r = 1:length(ROI_loc)
    %find the index of voxels of ROI, so that we don't have to load the
    %entire image into the memory
    [XYZ, ROI_mat] = roi_find_index(ROI_loc{r});
    % load images
    V = spm_vol(Images);
    % adjust ROI to fit images
    if adjust_logical
        funcXYZ = adjust_XYZ(XYZ, ROI_mat,V);
    else
        funcXYZ = XYZ;
    end
    % extract betas for all images
    betas.(['ROI',num2str(r)]).ROI = ROI_loc{r};
    for k = 1:length(Images)
        betas.(['ROI',num2str(r)]).data(k,:) = spm_get_data(Images{k},funcXYZ{k});    
    end
    %average across all the voxels of all images within current ROI
    betas.(['ROI',num2str(r)]).mean = nanmean(betas.(['ROI',num2str(r)]).data(:));
    
end