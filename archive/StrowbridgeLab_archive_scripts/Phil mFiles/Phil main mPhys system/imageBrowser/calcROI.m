function ROI = calcROI(ROI)
% calculates the array roiData that contains the sum of each roi in each
% frame

    zImage = evalin('base', 'zImage');
    
    for x = 1:numel(ROI)
        ROI(x).data = zeros(size(zImage.stack, 3),1, class(zImage.stack));
        for i = 1:size(ROI(x).points, 1)
            ROI(x).data = ROI(x).data + squeeze(zImage.stack(ROI(x).points(i,1), ROI(x).points(i,2), :)) / length(ROI(x).data);
        end
    end