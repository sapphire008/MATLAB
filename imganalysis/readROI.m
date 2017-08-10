function ROI = readROI(roifile)
% roifile = 'C:/Users/Edward/Desktop/Slice B CCh Double.512x200y75F.m1.img.roi';
fid = fopen(roifile, 'rb');
fseek(fid, 4, 'bof');
ROI = struct();
n = 1;
while ~feof(fid) && n < 1000
    % center: [x, y]
    ROI(n).center = fread(fid, 2, 'int16')';
    % unknown
    ROI(n).unknown1 = fread(fid, 1, 'int16');
    if isempty(ROI(n).unknown1)
        ROI = ROI(1:n-1);
        break;
    end
    % [x_length, y_length]
    ROI(n).size = fread(fid, 2, 'int16');
    % Some other unknwon sequence [?] * 9, mostly 0's and -1's
    ROI(n).unknown2 = fread(fid, 9, 'int16');
    % Position of the ROI square [x1,y1; x2, y2]
    ROI(n).position = fread(fid, 4, 'int16');
    if ~isempty(ROI(n).position)
        ROI(n).position = reshape(ROI(n).position, 2, 2)';
    end
    % increment index
    n = n + 1;
end
fclose('all');
end