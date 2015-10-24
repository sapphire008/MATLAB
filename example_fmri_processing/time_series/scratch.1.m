%ROI_loc = '/nfs/u3/SN_loc/ITK_Snap/SN_left/AT14_SNleft_unsmoothed_placebo.nii';

ROI = 'flipped_simple_roi.nii';

refimage = 'simple_roi.nii';

threshold = .3;

[XYZ1 ROImat] = roi_find_index(ROI,threshold);

[XYZ2 REFmat] = roi_find_index(refimage,threshold);

XYZ = XYZ1;
XYZ(4,:) = 1;

XYZ = inv(REFmat) * (ROImat * XYZ);

foo = spm_get_data('simple_roi.nii',XYZ)

XYZ = XYZ1;
XYZ(4,:) = 1;

XYZ = ROImat * XYZ;

XYZ = inv(ROImat) * XYZ;

XYZ = XYZ(1:3,:);

% trans = REFmat/ROImat;
% [U S V] = svd(trans(1:3, 1:3));
% XYZ = XYZ1;
% XYZ(4,:) = 1;
% foo = trans(1:3,:)*XYZ;



%image = nifti(ROI_loc);

%nii = make_nii(img, [voxel_size], [origin], [datatype], [description])
%nii = make_nii(zeros(128,128,25),[1.75 1.75 1.9], ,512,'empty image') 

nii = make_nii(zeros(128,128,25),[1 1 1],[64 64 12] ,512,'empty image');
nii.img(70:75,70:75,12) = 1

save_nii(nii,'simple_roi.nii');

%To convert matrix coordinates for a given Nifti/Analyze-image into the image coordinates and vice versa, you need to load the transformation matrix of the image into the workspace:

vol = spm_vol('image.img')
vol.mat % displays the transformation matrix

% trasform from matrix/voxel coordinates to image coordinates (the fourth element has to be 1)
vol.mat * [x y z 1]‘
% transform image coordinates (e.g. mni space) to matrix coordinates
inv(vol.mat) * [x y z 1]‘
 