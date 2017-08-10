function cleanUp
% these should disappear with the fileBrowser figure, but this function
% provides a means to free up the space without deleting the figure also.
    if isappdata(getappdata(0, 'fileBrowser'), 'episodeInfo')
        rmappdata(getappdata(0, 'fileBrowser'), 'episodeInfo');
        rmappdata(getappdata(0, 'fileBrowser'), 'episodeDirectory');
        rmappdata(getappdata(0, 'fileBrowser'), 'episodeHeaders');
        rmappdata(getappdata(0, 'fileBrowser'), 'imageHeaders');
    end
end