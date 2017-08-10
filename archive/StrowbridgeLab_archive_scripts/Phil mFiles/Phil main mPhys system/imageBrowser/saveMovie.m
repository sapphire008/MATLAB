function saveMovie
% saves a movie of the current cell

    [FileName PathName] = uiputfile({'*.avi', 'Movies (*.avi)';' *.*', 'All Files (*.*)'},'Choose name and location for file', 'myVideo');
    currentFrame = get(findobj('tag', 'cboFrame'), 'value');
    numFrames = numel(get(findobj('tag', 'cboFrame'), 'string'));
    callback = get(findobj('tag', 'cboFrame'), 'callback');
    set(findobj('tag', 'frmDisplayImage'), 'visible', 'off');
    
    % Record the movie
    aviStruct = avifile([PathName FileName], 'fps', 5, 'quality', 100, 'keyFramePerSec', 1);
    
    for j = 1:numFrames
        set(findobj('tag', 'cboFrame'), 'value', j);
        eval(callback);
        aviStruct = addframe(aviStruct, findobj('tag', 'imageAxis'));
    end    
    
    aviStruct = close(aviStruct);
    set(findobj('tag', 'cboFrame'), 'value', currentFrame);
    set(findobj('tag', 'frmDisplayImage'), 'visible', 'on');    