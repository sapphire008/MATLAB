function I = createZStack2D(images, savedir, Pallete, rotDeg, filterOpt)
% Create 2D Z-stack images
% 
% Inputs:
%   images: directory of the images, or cell array of list of images paths
%       or raster structures
%   savedir: optional full path to save image
%   Pallete: hard intensity threshold, default is [10, 650]
%   rotDeg: degree of rotation. Rotation is necessary to make sure that the
%           stripes artifacts are vertical. Default 90.
%   filterOpt: vertical stripe filtering option, in the format of cell
%       array {decNum, wname, sigma}. See XREMOVESTRIPESVERTICAL for
%       details. Input -1 to skip filtering
%
% Output:
%   I: image matrix
%   saved image at savedir
%

% load all the image files
if nargin<2, savedir = ''; end
if nargin<3, Pallete = []; end
if nargin<4, rotDeg = []; end
if nargin<5, filterOpt = []; end

if ischar(images) && size(images, 1) == 1 % single directory path
    images = SearchFiles(images, '*.img');
elseif ischar(images) % list of images, but in char
    images = cellstr(images);
end

I = 0;
% process the images
for n = 1:length(images)
    if iscellstr(images)
        I_tmp = read2PRaster(images{n});
    else
        I_tmp = images(n).img;
    end
    I_tmp = generateProcessedImage(I_tmp.img, Pallete, rotDeg, filterOpt);
    I = I + I_tmp;
end
% convert to grayscale image
I = imadjust(mat2gray(I));
% write to file
if ~isempty(savedir), imwrite(I, savedir);end
end