function pixelSize = micronsPerPixel(objective, xVolts, xPixels)
% calculate the number of microns per pixel
% data from two photon B 5-23-07

pixelSize = (9.38965E-4 + 0.0324 * xVolts) * 512 / xPixels;

switch objective
    case 63
        pixelSize = pixelSize * 0.9524; % not actually tested, just mathed
    case 60
        % do nothing as this was the data that generated the curve
    case 40
        pixelSize = pixelSize * 1.4575;
    case 20
        pixelSize = pixelSize * 2.6895;
    case 10
        pixelSize = pixelSize * 5.5118;
    case 5
        pixelSize = pixelSize * 12.0576;
    otherwise
        pixelSize = nan;
end