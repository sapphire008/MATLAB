function [images, replace_ind, names] = imageMovieView(Path)
% image flipping routines
if nargin<1 || isempty(Path), Path = pwd; end
% Get the list of files
[P, N] = SearchFiles(Path, '*.img','D');
% read in the files
images = read2PRaster(P);
% process the images
for n = 1:length(images)
    images(n).img = generateProcessedImage(images(n).img);
end
% view image
[images, replace_ind, names] = imreg_display(images, 'img',N);
end