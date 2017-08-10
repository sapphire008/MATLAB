function outText = checkSingleEpisodeSTA(fileNames)
    persistent lastVals
    
    if ~nargin
        outText = 'Check STA';
        return
    end
    
    if isempty(lastVals)
        lastVals = {'.5', '10'};
    end
    
    whereBounds = inputdlg({'Window Delay (msec)', 'Window Length (msec)'},'',1, lastVals);
    
    if ~isempty(whereBounds)
        lastVals = whereBounds;
        windowDelay = str2double(whereBounds{1});
        windowLength = str2double(whereBounds{2});
        % find all selected files
        for i = fileNames
            checkSTA(i{1}, windowLength, windowDelay);
        end
    end   