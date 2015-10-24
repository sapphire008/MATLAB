function create_binary_mask(source_img_dir,save_dir,thresh)
% create_binary_mask(source_img_dir, save_dir, thresh)
% Create a binary mask using a source nifti image thresholded by thresh
%
%   source_img_dir: directory of source image to create mask from.
%   save_dir: directory to save the mask
%   thresh: threshold. Value below the threshold are set to zero, values
%           above or equal to threshold are set to 1.

%addpath('/hsgs/projects/jhyoon1/pkg64/NIFTI/');

%load image
TmpImg = load_nii(source_img_dir);
%thresholding
TmpImg.img(isnan(TmpImg.img)) = 0;
TmpImg.img(TmpImg.img<thresh) = 0;
TmpImg.img(TmpImg.img>=thresh) = 1;

%check if the resulting image is binary
if length(unique(TmpImg.img))>2 || length(unique(TmpImg.img))<2
    error('Resulting image is not binary of unknown reason. Try again.');
else
    %save image
    save_nii(TmpImg,save_dir);
end

end

