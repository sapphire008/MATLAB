function images = imreg_tobin(images, params)
% Tell the user what we're doing
disp(['Thresholding ' num2str(params.image_num) ...
    ' images to binary...']); tic;
% Find out if we want to auto-thresh each image

for i = 1:params.image_num
    % for each image, we want to threshold to bw
    images(i).bw = im2bw(images(i).gray, params.bin_thresh);
    if params.invert_image
        images(i).bw = ~images(i).bw;
    end
end

% Option to view thresholded images
if params.interactive
    choice = questdlg('View thresholded images?',...
        'Threshold Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            images = imreg_display(images, 'bw');
        case 'Cancel'
            images = -1; return;
    end
end

% If user did not want to save entire workspace, let's clear some RAM
if ~params.save_workspace
    images = rmfield(images, 'gray');
end; toc; disp(' ');
end