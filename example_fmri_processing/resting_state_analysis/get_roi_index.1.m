function [index,ROI_Size]= get_roi_index(ROI)
if isempty(ROI)
    index = NaN;
    return;
end
% load and get ROI XYZ coordinates
switch class(ROI)
    case 'char'%assume path to seed image
        ROI = load_untouch_nii(ROI);
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