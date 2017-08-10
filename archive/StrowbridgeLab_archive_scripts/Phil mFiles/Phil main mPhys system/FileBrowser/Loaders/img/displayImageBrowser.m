function outText = displayImageBrowser(fileName)  
if ~nargin
    outText = 'Image Browser';
    return
end

    if strcmp(fileName{1}(end - 3:end), '.mat')
        % this is a data trace name
        imageBrowser(fileName{1}(1:find(fileName{1} == filesep, 1, 'last')));
    else
        % this is an image file name
        imageBrowser(fileName{1});        
    end