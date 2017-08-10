function saveImageAs(imageHandle, fileName)

if nargin < 1
    switch get(findobj('tag', 'cboImageSet'), 'value');
        case 1
            imageHandle = findobj('tag', 'image');
        case 2
            imageHandle = findobj('tag', 'background');
        case 3
            imageHandle = findobj('tag', 'baseline');
        case 4
            imageHandle = findobj('tag', 'fiducials');
    end
end

if nargin < 2 || fileName(end - 3) ~= '.' || isempty(imformats(fileName(end - 2:end)))
    allFormats = imformats;
    extData = {};
    for i = allFormats
        if ~isempty(i.write)
            extData{end + 1, 1} = ['*.' i.ext{1}];
            extData{end, 2} = i.description;
        end
    end
    if nargin < 2
        [fileName,pathName,filterIndex] = uiputfile(extData, 'Select Location to Save File');
    else
        [fileName,pathName,filterIndex] = uiputfile(extData, 'Select Location to Save File', fileName);
    end
    
    fileType = extData{filterIndex, 1}(3:end);
    fileName = [pathName fileName];
else
    fileType = fileName(end - 2:end);
end

clim = get(ancestor(imageHandle, 'axes'), 'clim');

imageData = get(imageHandle, 'cdata');

if sum(size(imageData) ~= 1) == 2
    imwrite((imageData - clim(1)) / clim(2) * size(get(ancestor(imageHandle, 'figure'), 'colormap'), 1), get(ancestor(imageHandle, 'figure'), 'colormap'), fileName, fileType);
else
    imwrite(imageData, fileName, fileType);
end