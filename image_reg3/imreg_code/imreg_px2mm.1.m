function [px2mm,pxdist]=imreg_px2mm(images, params)
%calibration using the distance between the centers of the two squares
disp('Calibrating distance...');
%LR center distance of each image
LRDist_vect = cellfun(@(x) sqrt(sum(diff(x,1,1).^2)),{images.LRcenter});
pxdist = nanmean(LRDist_vect(:));
px2mm=pxdist/params.centerDist_mm; %Calculate px2mm

disp(['px2mm = ' num2str(px2mm) ' px/mm']);
disp('End Calibration');
end