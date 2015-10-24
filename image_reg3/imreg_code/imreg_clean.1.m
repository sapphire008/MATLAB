function images = imreg_clean(images, params)
% The imreg_clean function cleans the images in two ways. First, it gets
% rid of anything that is touching the edges of the image, and saves these
% images in images.clean. Then, it removes any feature with area less than
% area specified in params.min_area, and saves in images.cleaner.

disp(['Cleaning ' num2str(params.image_num) ' image edges...']); tic;
images(params.image_num).clean = [];
for i = 1:params.image_num
    % for each image, we want to remove the edge noise
    images(i).clean = ~images(i).cropped;
    % median filter
    %images(i).clean = medfilt2(images(i).clean,[10,3]);
    % group the 1's in the image
    [grouped_im, num] = bwlabel(images(i).clean, 8);
    for j = 1:num % for each numbered block in the image
        if sum(grouped_im(1,:) == j) ~= 0 % if touching the top edge
            images(i).clean(grouped_im == j) = 0; % clean
        elseif sum(grouped_im(end,:) == j) ~= 0 % if touching the bottom edge
            images(i).clean(grouped_im == j) = 0; %clean
        elseif sum(grouped_im(:,1) == j) ~= 0 % if touching the left edge
            images(i).clean(grouped_im == j) = 0; % clean
        elseif sum(grouped_im(:,end) == j) ~= 0 % if touching the right edge
            images(i).clean(grouped_im == j) = 0; % clean
        end
    end
end
toc; disp(' ');
% If user is not saving workspace, let's clear some RAM:
if ~params.save_workspace
    images = rmfield(images, 'cropped');
end
% Give option to view images with edges cleaned
if params.interactive
    choice = questdlg('View images after primary cleaning?',...
        'Cleaned Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            images = imreg_display(images, 'clean');
        case 'Cancel'
            images = -1; return;
    end
end

%%
% Clean extra noise from the images by tossing out anything with an area
% smaller than the one given in min_area.
disp(['Removing noise from '...
    num2str(params.image_num) ' images...']); tic;
images(params.image_num).cleaner = [];
for i = 1:params.image_num
    images(i).cleaner = images(i).clean;
    [grouped_im num] = bwlabel(images(i).cleaner, 8);
    for j = 1:num
        blocksize = length(find(grouped_im==j));
        if blocksize < params.min_area
            images(i).cleaner(grouped_im==j) = 0;
        end
    end    
end
toc; disp(' ');
% If user is not saving workspace, let's clear some RAM:
if ~params.save_workspace
    images = rmfield(images, 'clean');
end
% Give option to view images after cleaning up noise
if params.interactive
    choice = questdlg('View images after secondary cleaning?',...
        'Cleaned Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
        images = imreg_display(images, 'cleaner');
        case 'Cancel'
            images = -1; return;
    end
end

end