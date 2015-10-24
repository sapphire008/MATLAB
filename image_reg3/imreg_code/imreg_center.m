function images = imreg_center(images, params)
% The imreg_center  function takes in the TEMPLATE images and calculates a
% center, leftcenter, rightcenter,for each image.
% The center values are stored in images.center and images.LRcenter
% Edward DongBo Cui & Dennis Thompson

% Initialize our result arrays
disp('Finding centers of image features...'); tic;
images(params.image_num).centered = [];
images(params.image_num).center = [];
images(params.image_num).LRcenter =  [];

% Calculate centers for each image in the list
for i = 1:params.image_num
%   Find the center of the entire image using the cleaner image
%   Currently, squre is white, and background is black.
    images(i).centered = images(i).edged; %start with the edged image
    [im_row, im_col]=find(images(i).cleaner);%find coord of the image
    images(i).center=mean([im_row, im_col]); %center of image [row, col];
    
    %use kmeans to find two centers of two clusters (squares)
    [~, images(i).LRcenter]=kmeans([im_row, im_col],2,...
        'Distance','sqEuclidean','Start','cluster','EmptyAction','drop',...
        'Replicate',5);
    %organize the centers and indices, so that the left center has IDX==1,
    %and right center has IDX==2
    images(i).LRcenter = sortrows(images(i).LRcenter,2);
    
    %set dot_size to draw a bigger than 1 pixel dot at each center.
    dot_size=0; %[-d:d]
    %Put a dot at the center of the image
    images(i).centered(round(images(i).center(1,1)+dot_size),...
        round(images(i).center(1,2)+dot_size))=1;
    %Put a dot at the left center
    images(i).centered(round(images(i).LRcenter(1,1))+dot_size,...
        round(images(i).LRcenter(1,2))+dot_size)=1;
    %Put a dot at the right center
    images(i).centered(round(images(i).LRcenter(2,1))+dot_size,...
        round(images(i).LRcenter(2,2))+dot_size)=1;
end
toc; disp(' ');
% If user is not saving workspace, let's clear some RAM:
if ~params.save_workspace
    images = rmfield(images, 'edged');
    images = rmfield(images, 'cleaner');
end
% Give option to view these images
if params.interactive || params.display_final
    choice = questdlg('View images with found centers?',...
        'Centered Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
%             tempfig = figure;
%             for i = 1:params.image_num
%                 if isempty(findobj('type', 'figure')); break;
%                 else imshow(images(i).centered); end
%                 pause(params.wait_time);
%             end
%             try close(tempfig);
%             catch e
%                 disp('User closed figure.');
%             end
            images = imreg_display(images, 'centered');
        case 'Cancel'
            images = -1; return;
    end
end
end