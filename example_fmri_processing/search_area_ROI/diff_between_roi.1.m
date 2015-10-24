function [only_in_1, only_in_2, common] = diff_between_roi(ROI1_loc,ROI2_loc)
% [only_in_1, only_in_2, common] = diff_between_roi(ROI1_loc,ROI2_loc)
% ROI1_loc,ROI2_loc  strings pointing to images of the same size
% only_in_1 = number of voxels only in ROI1
% only_in_2 = number of voxels only in ROI2  
% common = number of voxel common between them


% read in ROI
[Y1 XYZ1] = spm_read_vols(spm_vol(ROI1_loc));
[Y2 XYZ2] = spm_read_vols(spm_vol(ROI2_loc));

% locate non zero values
idx1 = find(Y1);
idx2 = find(Y2);

% find the difference and intersects
common = intersect(idx1,idx2);
only_in_1 = setdiff(idx1,idx2);
only_in_2 = setdiff(idx2,idx1);

common = length(common);
only_in_1 = length(only_in_1);
only_in_2 = length(only_in_2);


