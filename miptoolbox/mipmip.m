function pimg = mipmip(img, plane)
% Return the Maximum Intensity Projection image
switch lower(plane)
    case {1, 'transverse', 't'}
        pimg = squeeze(max(img, [], 3)); % transverse
    case {2, 'coronal', 'c'}
        pimg = squeeze(max(img, [], 2)); % coronal
    case {3, 'sagittal', 's'}
        pimg = squeeze(max(img, [], 1)); % sagital 
    otherwise
        error('Unrecognized plane %s\n', plane);
end
end