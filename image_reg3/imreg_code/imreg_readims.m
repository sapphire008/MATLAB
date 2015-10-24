function [images,params] = imreg_readims(params)
% The imreg_readims function reads in images from param.im_names and
% thresholds them using the binary threshold stored in bin_thresh. Stores
% read images in images.gray and thresholded images in images.bw
disp(['Processing ' num2str(params.image_num) ' images...']); tic;
% initialize images structure
images = struct(); disp(' ');
% initialize the images struct
images(params.image_num).gray = [];
images(params.image_num).cleaner = [];
images(params.image_num).name = [];
for i = 1:params.image_num
    % Greyscale each image and read into the struct
    images(i).name = params.im_names{i};
    images(i).gray = rgb2gray(imread(fullfile(params.im_dir,images(i).name)));
    images(i).time = (1/params.sample_rate) * (i-1);
end
% get image dimension
params.img_dim = size(images(1).gray);
toc; disp(' ');
% If the user wants option to view images
if params.interactive
    % Option to view grayscaled images
    choice = questdlg('View grayscaled images?',...
        'Original Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            images = imreg_display(images, 'gray');
        case 'Cancel'
            images = -1; return;
    end
end
end