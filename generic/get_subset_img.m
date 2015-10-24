function IMG_out = get_subset_img(IMG,dim,Slice_Range)
if isempty(Slice_Range)
    Slice_Range = 1:size(IMG,dim);
end
% get the image based on dim. If any dimension is singlet, squeeze to
% produce 2D image
switch dim
    case 1
        IMG_out = squeeze(IMG(Slice_Range,:,:));
    case 2
        IMG_out = squeeze(IMG(:,Slice_Range,:));
    case 3
        IMG_out = squeeze(IMG(:,:,Slice_Range));
end
end