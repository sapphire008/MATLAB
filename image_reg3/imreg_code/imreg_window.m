function [images,params] = imreg_window(images, params)
% The imreg_window function allows the user to specify which region of the
% images we are interested in, stores the images in images.cropped, and
% displays the cropped images. NOTE: make sure when specifying your ROI
% that you get all of it. 
happy = 0;
% while user is not satisfied by ROI selection
while happy == 0
    % create a temporary image to display and draw on
    f = figure('Name', 'Base Image Window', 'NumberTitle', 'off');
    fig_title = 'Window the Base Image (Corners) to Contain Only the ROI:';
    temp_im  = im2bw(images(1).gray, params.bin_thresh);
    if params.invert_image
        temp_im = ~temp_im;
    end
    row = zeros(2,1); 
    col = zeros(2,1);
    imshow(temp_im); title(fig_title);
    for i = 1:2 % for the left and right corner
        % get the coordinates of the chosen point from the user
        [col(i), row(i)] = ginput(1);
        col(i) = round(col(i)); row(i) = round(row(i));
        % draw the point on the image
        temp_im(row(i)-2:row(i)+2,col(i)-2:col(i)+2) = 0;
        imshow(temp_im); title(fig_title); % update the image
        if i == 2
            % if this is the second corner, we want to draw the box
            temp_im(row(1), col(1):col(2)) = 0;
            temp_im(row(2), col(1):col(2)) = 0;
            temp_im(row(1):row(2), col(1)) = 0;
            temp_im(row(1):row(2), col(2)) = 0;
            imshow(temp_im); title(fig_title);
            pause(2); % pause for half second so user can see box
        end
    end
    disp(' ');
    %record the cropped window size
    params.Window = [row(1),row(2),col(1),col(2)];
    % Try to close the main crop figure
    try close(f);
    catch e
        disp('User closed figure.');
    end
    % Important to make sure that our ROI is big enough, so show it:
    choice = questdlg('View cropped images?',...
        'Cropped Images', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            for n = 1:length(images)
                images(n).cropped = images(n).gray(row(1):row(2),col(1):col(2));
            end
            images = imreg_display(images, 'cropped');
            images = rmfield(images,'cropped');
        case 'Cancel'
            images = -1; return;
    end

    % If the user is not happy with the window, do it again
    choice = questdlg('Happy with the window?',...
        'Choose Window', 'Yes', 'No', 'Cancel', 'Yes');
    switch choice
        case 'Yes'
            happy = 1; 
        case 'No'
        case 'Cancel'
            images = -1; return;
    end
end
end
