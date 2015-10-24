function [images, translational] = imreg_calculate(images, params)
% The imreg_calculate function uses the averages computed in the
% imreg_center function to output the translational motion
% of each frame as compared to the base.
% Improving from the previous version, the modifier of this script accounts
% for the rotation of the images, instead of rotational movement.

% Easiest way to get the angle from the x axis here is to convert into  the
% imaginary plane and use the angle function

%place hodling a collection of centers of all images
center_mat = cell2mat(cellfun(@(x) x',{images.center},'un',0));% [row; col]
% convert to [x y] coordinate. Since x=col, y=row, and when row increases,
% the actual movement goes down. So we have to make y negative, so that as
% row increases, y decreases.
center_mat = [center_mat(2,:); -center_mat(1,:)];
% for i = 1:params.image_num
%     %vector projected by the left and right center
%     images(i).rot_vect = complex(...
%         images(i).LRcenter(1,2) - images(i).LRcenter(1,1),...
%         images(i).LRcenter(2,1) - images(i).LRcenter(2,2));
%     %angle of the projected vector with respect to horizontal axis of the
%     %screen (defined to be X direction)
%     images(i).angle = angle(images(i).rot_vect) * 180 / pi; %[deg]
% end
%theta=mean2(cell2mat({images.angle})); %average rotated angle [deg]
%theta_rad=theta*pi/180; %theta in radian [rad]
%rotation matrix
%rot_mat=[cos(theta_rad) -sin(theta_rad); sin(theta_rad) cos(theta_rad)];
%Assume that the angle of rotational motion during the scan is less than 1
%deg, which means the rotated position of the image is relatively constant,
%then we rotate the image if the angle of the projected vecotr is greater
%than 1 deg (theta>0.5)
% rot_correct_flag=0; %input "1" to correct rotation
% if (abs(theta)-1)>(1E-7) && rot_correct_flag
%     center_mat=rot_mat\center_mat; %Cartesian coordinate after rotation
%     if theta>0;
%         Rotating_Direction = 'clockwise';
%     else
%         Rotating_Direction = 'counterclockwise';
%     end
%     %display a message in the command window if there is any adjustment
%     disp (['Image is slant. Centers are rotated by: ' ...
%         num2str(theta) ' degrees ' Rotating_Direction]);
% end
%we could shift the base_image center back to its original position.
%However, since we are not emphasizing the absolute position, but a
%relative displacement or change of position (velocity), shifting the
%center or not does not affect the result.

% Compute the translational displacement of center dot of each frame and 
% the rotational displacement from the angles found above
translational.displacement = bsxfun(@minus,center_mat, center_mat(:,1))/params.pixels_to_mm;
translational.velocity = [[0;0],diff(center_mat,[],2)]/params.pixels_to_mm * params.sample_rate;
%rotational.displacement = cell2mat({images.angle}) - images(1).angle;
%rotational.velocity = [0, diff(cell2mat({images.angle}))]*params.sample_rate;

end


