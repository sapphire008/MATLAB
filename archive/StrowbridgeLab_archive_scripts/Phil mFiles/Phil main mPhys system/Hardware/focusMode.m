function focusMode(obj, eventStruct, zImage, numPoints, pixelUs, lagX, pixelsY, turnLength)
if evalin('base', 'imageDone')
    assignin('base', 'imageDone', 0);
    
    fid = fopen('R:\rasterOut.dat');
        fseek(fid, 20, 'bof'); % 20 for the header
        zImage.photometry = fread(fid, [2, numPoints], '*int16')';
        zImage.photometry(1:round(150 / pixelUs), :) = [];
    fclose(fid);

    % correct for lags
    zImage.stack = reshape(circshift(zImage.photometry(:,1), [-round(lagX / pixelUs) 0]), [], pixelsY);

    % trim off the turn arounds
    zImage.stack = zImage.stack(turnLength + 1:end, :);

    % flip the return lines of the x dimension
    zImage.stack(:, 1:2:end) = zImage.stack(end:-1:1, 1:2:end); 

    imageBrowser(zImage);
end