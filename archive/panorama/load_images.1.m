function images = load_images(files, rotateAngle, iteration, images)
% Reaad images as a stack
%
% files: list of image files as char or cellstr
% rotateAngle: Specify a rotate angle in degrees and rotate the image 
%       before stacking the images

if isempty(files), return; end
if nargin < 2, rotateAngle = 0;end
if nargin < 3, images = []; iteration = 0; end

% make sure the file list is in cell array
if iteration<1, files = cellstr(files); end

% load the image, recursively
im = imread(files{1});
if rotateAngle~=0,im = imrotate(im, rotateAngle);end

% concatenate the image to the new dimension
if iteration<2, mydim = ndims(images)+1; else mydim = ndims(images); end
images = cat(mydim, images, im);

% Recursion
images = load_images(files(2:end), rotateAngle, iteration+1, images);
end